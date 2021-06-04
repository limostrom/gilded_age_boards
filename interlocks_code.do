/*
interlocks_code.do

To be used after industrials_interlocks_coded has already been constructed
	with coding interlocks Horizontal, Vertical, or No Relationship, the industry
	of the firm, and whether the firm is 

*/
clear all
cap log close
pause on

cap cd "C:/Users/lmostrom/Documents/Gilded Age Boards - Scratch"

*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cap cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Post-Thesis" // old computer
cd "C:\Users\lmostrom\Documents\Gilded Age Boards - Scratch\"

use fullname_m year_std using "Thesis/Merges/UW_1880-1920_top10.dta", clear
duplicates drop
tempfile top10
save `top10', replace

use year_std fullname_m using "Data/UW_1880-1920_Indtop10.dta", clear
duplicates drop
tempfile indtop10
save `indtop10', replace

*%% Code Railroad Interlocks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use cname fullname_m director year_std using "Thesis/Merges/RR_boards_wtitles.dta", clear
include "../GitHub/gilded_age_boards/assign_regions.do"
keep if director
drop director

ren cname cnameB
ren region regionB
tempfile self
save `self', replace

ren cnameB cnameA
ren regionB regionA

joinby fullname_m year_std using `self'

merge m:1 fullname_m year_std using `top10', keep(1 3)
gen banker = _merge == 3
drop _merge

gen interlock = cnameA != cnameB
	replace banker = 0 if interlock == 0
gen same_reg = regionA == regionB
gen oth_reg = regionA != regionB
		*sort cnameA cnameB fullname_m
		*br fullname_m interlock banker cnameB cnameA year_std ///
			if year_std == 1905 
			*& cnameA == "Cleve Cincin Chic & St Louis"
		*pause
duplicates drop
drop fullname_m

bys cnameA cnameB year_std: egen n_totints = total(interlock)
bys cnameA cnameB year_std: egen n_bnkints = total(banker)
bys cnameA cnameB year_std: ereplace banker = max(banker)
duplicates drop

save "Data/rr_interlocks_coded.dta", replace
	sdf
*%% Prep Industry Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
forval y = 1895(5)1920 {
    import excel cname cid Entrant Industry using "industrials_interlocks_coded.xlsx", ///
		clear sheet("`y'") cellrange(A2)
	gen year_std = `y'
	replace cname = "Natinoal Linseed Oil" if cname == "National Linseed Oil" & year_std == 1895
	tempfile ind`y'
	save `ind`y'', replace
}


use `ind1895', clear
forval y = 1900(5)1920 {
	append using `ind`y''
}

drop if cname == ""

tempfile industries
save `industries', replace
*%%Load Industrials Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cap cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Post-Thesis" // old computer
cd "C:\Users\lmostrom\Documents\PersonalResearch\"

use year_std cname fullname_m director sector cid ///
	using "Thesis/Merges/Ind_boards_wtitles.dta", clear

merge m:1 fullname_m year_std using `top10', keep(1 3)
gen banker = _merge == 3
drop _merge
merge m:1 fullname_m year_std using `indtop10', keep(1 3)
gen banker_indtop10 = _merge == 3
drop _merge
	
assert fullname_m != ""
keep if director == 1
local id cid

* bring in industries
merge m:1 cname year_std using `industries', assert(1 3)
preserve
	keep if _merge == 1
	keep cname year_std
	duplicates drop
	save "utils_in_ind_dataset.dta", replace
restore
drop if _merge == 1
drop _merge

merge m:1 cname year_std using "assets_ind.dta", assert(2 3)
*pause
drop if _merge == 2
drop _merge

keep fullname_m year_std cname cid banker banker_indtop10 Entrant Industry assets
	ren cname cnameB
	ren cid cidB
	ren Entrant entrantB
	ren Industry indB
	ren assets assetsB

tempfile self
save `self', replace

	ren cnameB cnameA
	ren cidB cidA
	ren entrantB entrantA
	ren indB indA
	ren assetsB assetsA

joinby fullname_m year_std using `self'
drop fullname_m

gen interlock = (cnameA != cnameB)
bys cnameA cnameB year_std: egen n_totints = total(interlock)
bys cnameA cnameB year_std: egen n_bnkints = total(banker)
bys cnameA cnameB year_std: egen n_bnkints_indtop10 = total(banker_indtop10)
bys cnameA cnameB year_std: ereplace banker = max(banker)
bys cnameA cnameB year_std: ereplace banker_indtop10 = max(banker_indtop10)
duplicates drop


	foreach X in "A" "B" {
		replace ind`X' = "Mining / Smelting & Refining" if inlist(ind`X', "Mining/Metals", ///
						"Metals/Steel", "Mining/Metals / Steel / Chemicals", "Metals", ///
						"Mining / Shipping", "Mining / Steel", "Mining / Oil", ///
						"Metals / Smelting & Refining", "melting/Refining") ///
						| inlist(ind`X', "Mining", "Smelting/Refining")
		replace ind`X' = "Automobiles" if inlist(ind`X', "Automobiles / Farming Machinery", ///
						"Automobiles / Firearms & Explosives", "Automobiles / Rubber")
		replace ind`X' = "Chemicals" if ind`X' == "Chemicals / Mining"
		replace ind`X' = "General Manufacturing" if ind`X' == "General Manufacturing / Chemicals"
		replace ind`X' = "Food & Beverages" if ind`X' == "Food & Beverages / Consumer Goods"
		replace ind`X' = "Oil" if ind`X' == "Oil / Shipping"
		replace ind`X' = "Pharmaceuticals" if ind`X' == "Pharmaceuticals / Consumer Goods"
		replace ind`X' = "Land/Real Estate" if ind`X' == "Real Estate / Shipping"
		replace ind`X' = "Shipping" if ind`X' == "Shipping / General Manufacturing"
		

	}

tab year_std interlock

gen vertical = 0
gen horizontal = 0
gen ownership = 0
gen no_relationship = 0

*1895
replace vertical = 1 if ///
			(cnameA == "Illinois Steel" & cnameB == "Pullman's Palace Car Co.") ///
			| (cnameA == "Pullman's Palace Car Co." & cnameB == "Illinois Steel")

replace no_relationship = 1 if interlock & vertical + horizontal == 0 & year_std == 1895

*1900
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Amalgamated Copper") ///
	| (cnameA == "Amalgamated Copper" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Allis-Chalmers Manufacturing")
	
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "Anaconda Copper Mining Company") ///
	| (cnameA == "Anaconda Copper Mining Company" & cnameB == "Amalgamated Copper")
replace ownership = 1 if year_std == 1900 & ///
	((cnameA == "Amalgamated Copper" & cnameB == "Anaconda Copper Mining Company") ///
	| (cnameA == "Anaconda Copper Mining Company" & cnameB == "Amalgamated Copper"))
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "Tennessee Copper Company") ///
	| (cnameA == "Tennessee Copper Company" & cnameB == "Amalgamated Copper")
	
replace vertical = 1 if ///
	(cnameA == "American Can Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "American Can Company")
	
replace horizontal = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "International Power") ///
	| (cnameA == "International Power" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "American Locomotive Company")
replace horizontal = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "The Pullman Co") ///
	| (cnameA == "The Pullman Co" & cnameB == "American Locomotive Company")

replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Colorado Fuel and Iron Company") ///
	| (cnameA == "Colorado Fuel and Iron Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Tennessee Coal & Iron") ///
	| (cnameA == "Tennessee Coal & Iron" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "American Smelting and Refining")

replace horizontal = 1 if ///
	(cnameA == "American Snuff Co." & cnameB == "American Tobacco Co.") ///
	| (cnameA == "American Tobacco Co." & cnameB == "American Snuff Co.")
replace ownership = 1 if year_std == 1900 & ///
	((cnameA == "American Snuff Co." & cnameB == "American Tobacco Co.") ///
	| (cnameA == "American Tobacco Co." & cnameB == "American Snuff Co."))
replace horizontal = 1 if ///
	(cnameA == "American Snuff Co." & cnameB == "Continental Tobacco Co") ///
	| (cnameA == "Continental Tobacco Co" & cnameB == "American Snuff Co.")

replace horizontal = 1 if ///
	(cnameA == "American Spirits Manufacturing" & cnameB == "Distilling Co of America") ///
	| (cnameA == "Distilling Co of America" & cnameB == "American Spirits Manufacturing")
replace ownership = 1 if year_std == 1900 & ///
	((cnameA == "American Spirits Manufacturing" & cnameB == "Distilling Co of America") ///
	| (cnameA == "Distilling Co of America" & cnameB == "American Spirits Manufacturing"))

replace horizontal = 1 if ///
	(cnameA == "American Tobacco Co." & cnameB == "Continental Tobacco Co") ///
	| (cnameA == "Continental Tobacco Co" & cnameB == "American Tobacco Co.")
replace vertical = 1 if ///
	(cnameA == "American Tobacco Co." & cnameB == "Virginia-Carolina Chemical") ///
	| (cnameA == "Virginia-Carolina Chemical" & cnameB == "American Tobacco Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Anaconda Copper Mining Company" & cnameB == "Tennessee Copper Company") ///
	| (cnameA == "Tennessee Copper Company" & cnameB == "Anaconda Copper Mining Company")

replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Central Coal and Coke Company") ///
	| (cnameA == "Central Coal and Coke Company" & cnameB == "Bethlehem Steel Corporation")
	
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "Colorado Fuel and Iron Company")
	
replace vertical = 1 if ///
	(cnameA == "Continental Tobacco Co" & cnameB == "Virginia-Carolina Chemical") ///
	| (cnameA == "Virginia-Carolina Chemical" & cnameB == "Continental Tobacco Co")
	
replace vertical = 1 if ///
	(cnameA == "Crucible Steel Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Crucible Steel Company")
	
replace vertical = 1 if ///
	(cnameA == "Glucose Sugar Ref" & cnameB == "National Biscuit") ///
	| (cnameA == "National Biscuit" & cnameB == "Glucose Sugar Ref")
	
replace horizontal = 1 if ///
	(cnameA == "Homestake Mining Company" & cnameB == "Ontario Silver Mining") ///
	| (cnameA == "Ontario Silver Mining" & cnameB == "Homestake Mining Company")
	
replace vertical = 1 if ///
	(cnameA == "International Paper" & cnameB == "Mergenthaler Linotype Company") ///
	| (cnameA == "Mergenthaler Linotype Company" & cnameB == "International Paper")
	
replace horizontal = 1 if ///
	(cnameA == "International Power" & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "International Power")
	
replace vertical = 1 if ///
	(cnameA == "New York Air Brake" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "New York Air Brake")
	
replace horizontal = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Pacific Coast Company")
replace vertical = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "Pacific Coast Company")
replace horizontal = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "Pacific Coast Company")
	
replace vertical = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "Pittsburgh Coal Company")
replace horizontal = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "Pittsburgh Coal Company")
	
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Pressed Steel Car")
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "Westinghouse Air Brake") ///
	| (cnameA == "Westinghouse Air Brake" & cnameB == "Pressed Steel Car")
	
replace horizontal = 1 if ///
	(cnameA == "Republic Iron and Steel" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "Republic Iron and Steel")
replace vertical = 1 if ///
	(cnameA == "Republic Iron and Steel" & cnameB == "Westinghouse Air Brake") ///
	| (cnameA == "Westinghouse Air Brake" & cnameB == "Republic Iron and Steel")
	
replace horizontal = 1 if ///
	(cnameA == "Rubber Goods Mfg Company" & cnameB == "US Rubber") ///
	| (cnameA == "US Rubber" & cnameB == "Rubber Goods Mfg Company")
	
replace vertical = 1 if ///
	(cnameA == "The Pullman Co" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "The Pullman Co")
	
replace vertical = 1 if ///
	(cnameA == "Westinghouse Air Brake" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "Westinghouse Air Brake")
	
replace no_relationship = 1 if interlock & vertical + horizontal == 0 & year_std == 1900

	
*1905
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "Adams Express Co.")
	
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Amalgamated Copper") ///
	| (cnameA == "Amalgamated Copper" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Case (J. I.) Threshing Machine Co.") ///
	| (cnameA == "Case (J. I.) Threshing Machine Co." & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Allis-Chalmers Manufacturing")
	
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "Anaconda Copper Mining Company") ///
	| (cnameA == "Anaconda Copper Mining Company" & cnameB == "Amalgamated Copper")
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "Tennessee Copper Company") ///
	| (cnameA == "Tennessee Copper Company" & cnameB == "Amalgamated Copper")
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Amalgamated Copper")
	
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "American Brake Shoe & Foundry Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Can Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "American Can Company")
	
replace vertical = 1 if ///
	(cnameA == "American Car & Foundry" & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "American Car & Foundry")
replace vertical = 1 if ///
	(cnameA == "American Car & Foundry" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "American Car & Foundry")
	
replace vertical = 1 if ///
	(cnameA == "American Coal Co. of Allegany Co." & cnameB == "Granby Consolidated Smelting and Power Company") ///
	| (cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "American Coal Co. of Allegany Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Coal Products Co." & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "American Coal Products Co.")
replace vertical = 1 if ///
	(cnameA == "American Coal Products Co." & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "American Coal Products Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Bethlehem Steel Corporation") ///
	| (cnameA == "Bethlehem Steel Corporation" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "American Locomotive Company")
replace horizontal = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "The Pullman Co") ///
	| (cnameA == "The Pullman Co" & cnameB == "American Locomotive Company")
	
replace horizontal = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "American Smelting and Refining") ///
	| (cnameA == "American Smelting and Refining" & cnameB == "American Smelters' Security Co.")
replace ownership = 1 if year_std == 1905 & ///
	((cnameA == "American Smelters' Security Co." & cnameB == "American Smelting and Refining") ///
	| (cnameA == "American Smelting and Refining" & cnameB == "American Smelters' Security Co."))
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "American Smelters' Security Co.")
	
replace horizontal = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Granby Consolidated Smelting and Power Company") ///
	| (cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Iron Silver Mining Company") ///
	| (cnameA == "Iron Silver Mining Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "American Smelting and Refining")
	
replace vertical = 1 if ///
	(cnameA == "American Steel Foundries" & cnameB == "International Harvester of NJ") ///
	| (cnameA == "International Harvester of NJ" & cnameB == "American Steel Foundries")
replace horizontal = 1 if ///
	(cnameA == "American Steel Foundries" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "American Steel Foundries")
	
replace vertical = 1 if ///
	(cnameA == "American Tobacco Co." & cnameB == "Virginia-Carolina Chemical") ///
	| (cnameA == "Virginia-Carolina Chemical" & cnameB == "American Tobacco Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Anaconda Copper Mining Company" & cnameB == "Tennessee Copper Company") ///
	| (cnameA == "Tennessee Copper Company" & cnameB == "Anaconda Copper Mining Company")
	
replace horizontal = 1 if ///
	(cnameA == "Associated Merchants Company" & cnameB == "Claflin Company") ///
	| (cnameA == "Claflin Company" & cnameB == "Associated Merchants Company")
replace ownership = 1 if year_std == 1905 & ///
	((cnameA == "Associated Merchants Company" & cnameB == "Claflin Company") ///
	| (cnameA == "Claflin Company" & cnameB == "Associated Merchants Company"))
	
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "Bethlehem Steel Corporation")
replace horizontal = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Tennessee Coal & Iron") ///
	| (cnameA == "Tennessee Coal & Iron" & cnameB == "Bethlehem Steel Corporation")
replace horizontal = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Bethlehem Steel Corporation")
	
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "Colorado Fuel and Iron Company")
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "Colorado Fuel and Iron Company")
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "Colorado Fuel and Iron Company")
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Colorado Fuel and Iron Company")
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "Wells Fargo and Company") ///
	| (cnameA == "Wells Fargo and Company" & cnameB == "Colorado Fuel and Iron Company")
	
replace vertical = 1 if ///
	(cnameA == "Corn Products Refining Co." & cnameB == "National Biscuit") ///
	| (cnameA == "National Biscuit" & cnameB == "Corn Products Refining Co.")
	
replace vertical = 1 if ///
	(cnameA == "Crucible Steel Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Crucible Steel Company")
	
replace vertical = 1 if ///
	(cnameA == "Federal Mining and Smelting Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Federal Mining and Smelting Company")
	
replace vertical = 1 if ///
	(cnameA == "Homestake Mining Company" & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "Homestake Mining Company")
replace horizontal = 1 if ///
	(cnameA == "Homestake Mining Company" & cnameB == "Ontario Silver Mining") ///
	| (cnameA == "Ontario Silver Mining" & cnameB == "Homestake Mining Company")
	
replace vertical = 1 if ///
	(cnameA == "International Harvester of NJ" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "International Harvester of NJ")
	
replace vertical = 1 if ///
	(cnameA == "International Paper" & cnameB == "Pacific Mail Steamship Co.") ///
	| (cnameA == "Pacific Mail Steamship Co." & cnameB == "International Paper")
	
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "Ontario Silver Mining") ///
	| (cnameA == "Ontario Silver Mining" & cnameB == "International Steam Pump")
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "Tennessee Coal & Iron") ///
	| (cnameA == "Tennessee Coal & Iron" & cnameB == "International Steam Pump")
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "International Steam Pump")
	
replace vertical = 1 if ///
	(cnameA == "Iron Silver Mining Company" & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "Iron Silver Mining Company")
	
replace vertical = 1 if ///
	(cnameA == "New York Air Brake" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "New York Air Brake")
	
replace horizontal = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Pacific Coast Company")
replace vertical = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "Pacific Coast Company")
replace horizontal = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "Pacific Coast Company")
replace vertical = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Wells Fargo and Company") ///
	| (cnameA == "Wells Fargo and Company" & cnameB == "Pacific Coast Company")
	
replace vertical = 1 if ///
	(cnameA == "Pacific Mail Steamship Co." & cnameB == "Wells Fargo and Company") ///
	| (cnameA == "Wells Fargo and Company" & cnameB == "Pacific Mail Steamship Co.")
	
replace vertical = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "Pittsburgh Coal Company")
replace horizontal = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "Pittsburgh Coal Company")
	
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Pressed Steel Car")
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Pressed Steel Car")
	
replace vertical = 1 if ///
	(cnameA == "Railway Steel Spring" & cnameB == "Tennessee Coal & Iron") ///
	| (cnameA == "Tennessee Coal & Iron" & cnameB == "Railway Steel Spring")
	
replace horizontal = 1 if ///
	(cnameA == "Republic Iron and Steel" & cnameB == "Virginia Iron Coal and Coke Company") ///
	| (cnameA == "Virginia Iron Coal and Coke Company" & cnameB == "Republic Iron and Steel")
	
replace horizontal = 1 if ///
	(cnameA == "Tennessee Copper Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Tennessee Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "The Pullman Co" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "The Pullman Co")
	
replace vertical = 1 if ///
	(cnameA == "Westinghouse Air Brake" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "Westinghouse Air Brake")
	
replace no_relationship = 1 if interlock & vertical + horizontal == 0 & year_std == 1905

*1910	
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "Associated Merchants Company") ///
	| (cnameA == "Associated Merchants Company" & cnameB == "Adams Express Co.")
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "Adams Express Co.")
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "The Pullman Co") ///
	| (cnameA == "The Pullman Co" & cnameB == "Adams Express Co.")
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "United Dry Goods") ///
	| (cnameA == "United Dry Goods" & cnameB == "Adams Express Co.")
	
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "International Harvester of NJ") ///
	| (cnameA == "International Harvester of NJ" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Lackawanna Steel") ///
	| (cnameA == "Lackawanna Steel" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Allis-Chalmers Manufacturing")
	
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "Anaconda Copper Mining Company") ///
	| (cnameA == "Anaconda Copper Mining Company" & cnameB == "Amalgamated Copper")
	
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "American Cotton Oil Co.") ///
	| (cnameA == "American Cotton Oil Co." & cnameB == "American Agricultural Chemical Co.")
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "American Sugar Refining Co.") ///
	| (cnameA == "American Sugar Refining Co." & cnameB == "American Agricultural Chemical Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Beet Sugar Co." & cnameB == "American Express Co.") ///
	| (cnameA == "American Express Co." & cnameB == "American Beet Sugar Co.")
replace vertical = 1 if ///
	(cnameA == "American Beet Sugar Co." & cnameB == "US Industrial Alcohol") ///
	| (cnameA == "US Industrial Alcohol" & cnameB == "American Beet Sugar Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "American Locomotive Company") ///
	| (cnameA == "American Locomotive Company" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "American Brake Shoe & Foundry Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Can Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "American Can Company")
	
replace vertical = 1 if ///
	(cnameA == "American Express Co." & cnameB == "Corn Products Refining Co.") ///
	| (cnameA == "Corn Products Refining Co." & cnameB == "American Express Co.")
replace vertical = 1 if ///
	(cnameA == "American Express Co." & cnameB == "US Industrial Alcohol") ///
	| (cnameA == "US Industrial Alcohol" & cnameB == "American Express Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Bethlehem Steel Corporation") ///
	| (cnameA == "Bethlehem Steel Corporation" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "American Locomotive Company")
	
replace horizontal = 1 if ///
	(cnameA == "American Malt Corporation" & cnameB == "American Malting") ///
	| (cnameA == "American Malting" & cnameB == "American Malt Corporation")
replace ownership = 1 if year_std == 1910 & ///
	((cnameA == "American Malt Corporation" & cnameB == "American Malting") ///
	| (cnameA == "American Malting" & cnameB == "American Malt Corporation"))
	
replace horizontal = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "American Smelting and Refining") ///
	| (cnameA == "American Smelting and Refining" & cnameB == "American Smelters' Security Co.")
replace ownership = 1 if year_std == 1910 & ///
	((cnameA == "American Smelters' Security Co." & cnameB == "American Smelting and Refining") ///
	| (cnameA == "American Smelting and Refining" & cnameB == "American Smelters' Security Co."))
replace horizontal = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "American Smelters' Security Co.")
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "American Smelters' Security Co.")
replace horizontal = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "National Lead Co") ///
	| (cnameA == "National Lead Co" & cnameB == "American Smelters' Security Co.")
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "American Smelters' Security Co.")
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "American Smelters' Security Co.")
	
replace horizontal = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "American Smelting and Refining")
replace horizontal = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "National Lead Co") ///
	| (cnameA == "National Lead Co" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "American Smelting and Refining")
	
replace horizontal = 1 if ///
	(cnameA == "American Snuff Co." & cnameB == "American Tobacco Co.") ///
	| (cnameA == "American Tobacco Co." & cnameB == "American Snuff Co.")
replace ownership = 1 if year_std == 1910 & ///
	((cnameA == "American Snuff Co." & cnameB == "American Tobacco Co.") ///
	| (cnameA == "American Tobacco Co." & cnameB == "American Snuff Co."))
replace horizontal = 1 if ///
	(cnameA == "American Snuff Co." & cnameB == "Lorillard") ///
	| (cnameA == "Lorillard" & cnameB == "American Snuff Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Steel Foundries" & cnameB == "International Harvester of NJ") ///
	| (cnameA == "International Harvester of NJ" & cnameB == "American Steel Foundries")
replace vertical = 1 if ///
	(cnameA == "American Steel Foundries" & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "American Steel Foundries")
replace horizontal = 1 if ///
	(cnameA == "American Steel Foundries" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "American Steel Foundries")
	
replace horizontal = 1 if ///
	(cnameA == "American Tobacco Co." & cnameB == "Lorillard") ///
	| (cnameA == "Lorillard" & cnameB == "American Tobacco Co.")
	
replace ownership = 1 if year_std == 1910 & ///
	((cnameA == "Assets Realization Co." & cnameB == "Crucible Steel Company") ///
	| (cnameA == "Crucible Steel Company" & cnameB == "Assets Realization Co."))
	
replace horizontal = 1 if ///
	(cnameA == "Associated Merchants Company" & cnameB == "Claflin Company") ///
	| (cnameA == "Claflin Company" & cnameB == "Associated Merchants Company")
replace horizontal = 1 if ///
	(cnameA == "Associated Merchants Company" & cnameB == "United Dry Goods") ///
	| (cnameA == "United Dry Goods" & cnameB == "Associated Merchants Company")
	
replace vertical = 1 if ///
	(cnameA == "Associated Oil Co." & cnameB == "Pacific Mail Steamship Co.") ///
	| (cnameA == "Pacific Mail Steamship Co." & cnameB == "Associated Oil Co.")
	
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "Bethlehem Steel Corporation")
	
replace vertical = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Granby Consolidated Smelting and Power Company") ///
	| (cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Chino Copper Company")
replace vertical = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "US Reduction and Refining") ///
	| (cnameA == "US Reduction and Refining" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Chino Copper Company")
	
replace horizontal = 1 if ///
	(cnameA == "Claflin Company" & cnameB == "United Dry Goods") ///
	| (cnameA == "United Dry Goods" & cnameB == "Claflin Company")
	
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "General Motors Co.") ///
	| (cnameA == "General Motors Co." & cnameB == "Colorado Fuel and Iron Company")
	
replace vertical = 1 if ///
	(cnameA == "Corn Products Refining Co." & cnameB == "General Chemical Co.") ///
	| (cnameA == "General Chemical Co." & cnameB == "Corn Products Refining Co.")
	
replace vertical = 1 if ///
	(cnameA == "Crucible Steel Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Crucible Steel Company")
	
replace vertical = 1 if ///
	(cnameA == "Electric Storage Battery Co" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "Electric Storage Battery Co")
	
replace horizontal = 1 if ///
	(cnameA == "Federal Mining and Smelting Company" & cnameB == "National Lead Co") ///
	| (cnameA == "National Lead Co" & cnameB == "Federal Mining and Smelting Company")
replace horizontal = 1 if ///
	(cnameA == "Federal Mining and Smelting Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Federal Mining and Smelting Company")
	
replace vertical = 1 if ///
	(cnameA == "General Motors Co." & cnameB == "New York Air Brake") ///
	| (cnameA == "New York Air Brake" & cnameB == "General Motors Co.")
replace vertical = 1 if ///
	(cnameA == "General Motors Co." & cnameB == "Pressed Steel Car") ///
	| (cnameA == "Pressed Steel Car" & cnameB == "General Motors Co.")
replace vertical = 1 if ///
	(cnameA == "General Motors Co." & cnameB == "Rubber Goods Mfg Company") ///
	| (cnameA == "Rubber Goods Mfg Company" & cnameB == "General Motors Co.")
replace vertical = 1 if ///
	(cnameA == "General Motors Co." & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "General Motors Co.")
replace vertical = 1 if ///
	(cnameA == "General Motors Co." & cnameB == "US Rubber") ///
	| (cnameA == "US Rubber" & cnameB == "General Motors Co.")
replace vertical = 1 if ///
	(cnameA == "General Motors Co." & cnameB == "US Smelting Refining and Mining Co") ///
	| (cnameA == "US Smelting Refining and Mining Co" & cnameB == "General Motors Co.")
replace vertical = 1 if ///
	(cnameA == "General Motors Co." & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "General Motors Co.")
	
replace vertical = 1 if ///
	(cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Pittsburgh Steel") ///
	| (cnameA == "Pittsburgh Steel" & cnameB == "Granby Consolidated Smelting and Power Company")
	
replace vertical = 1 if ///
	(cnameA == "Guggenheim Exploration Co." & cnameB == "National Lead Co") ///
	| (cnameA == "National Lead Co" & cnameB == "Guggenheim Exploration Co.")
replace horizontal = 1 if ///
	(cnameA == "Guggenheim Exploration Co." & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Guggenheim Exploration Co.")
replace horizontal = 1 if ///
	(cnameA == "Guggenheim Exploration Co." & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Guggenheim Exploration Co.")
replace ownership = 1 if year_std == 1910 & ///
	((cnameA == "Guggenheim Exploration Co." & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Guggenheim Exploration Co."))
	
replace vertical = 1 if ///
	(cnameA == "Homestake Mining Company" & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "Homestake Mining Company")
replace horizontal = 1 if ///
	(cnameA == "Homestake Mining Company" & cnameB == "Ontario Silver Mining") ///
	| (cnameA == "Ontario Silver Mining" & cnameB == "Homestake Mining Company")
	
replace vertical = 1 if ///
	(cnameA == "Ingersoll-Rand Company" & cnameB == "International Harvester of NJ") ///
	| (cnameA == "International Harvester of NJ" & cnameB == "Ingersoll-Rand Company")
	
replace vertical = 1 if ///
	(cnameA == "International Harvester of NJ" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "International Harvester of NJ")
	
replace vertical = 1 if ///
	(cnameA == "International Mercantile Marine" & cnameB == "South Porto Rico Sugar Company") ///
	| (cnameA == "South Porto Rico Sugar Company" & cnameB == "International Mercantile Marine")
	
replace vertical = 1 if ///
	(cnameA == "International Paper" & cnameB == "Mergenthaler Linotype Company") ///
	| (cnameA == "Mergenthaler Linotype Company" & cnameB == "International Paper")
	
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "International Steam Pump")
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "International Steam Pump")
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "International Steam Pump")
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "US Smelting Refining and Mining Co") ///
	| (cnameA == "US Smelting Refining and Mining Co" & cnameB == "International Steam Pump")
	
replace vertical = 1 if ///
	(cnameA == "Jefferson and Clearfield Coal and Iron Company" & cnameB == "Lackawanna Steel") ///
	| (cnameA == "Lackawanna Steel" & cnameB == "Jefferson and Clearfield Coal and Iron Company")
	
replace vertical = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "The Pullman Co") ///
	| (cnameA == "The Pullman Co" & cnameB == "Lackawanna Steel")
replace horizontal = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Lackawanna Steel")
	
replace horizontal = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "May Department Stores")
	
replace horizontal = 1 if ///
	(cnameA == "National Lead Co" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "National Lead Co")
	
replace horizontal = 1 if ///
	(cnameA == "Nevada Consolidated Copper Company" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Nevada Consolidated Copper Company")
replace vertical = 1 if ///
	(cnameA == "Nevada Consolidated Copper Company" & cnameB == "US Reduction and Refining") ///
	| (cnameA == "US Reduction and Refining" & cnameB == "Nevada Consolidated Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Nevada Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Nevada Consolidated Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "New York Air Brake" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "New York Air Brake")
	
replace horizontal = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Pacific Coast Company")
replace vertical = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "Pacific Coast Company")
replace vertical = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "Pacific Coast Company")
	
replace vertical = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "Pittsburgh Coal Company")
replace vertical = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Pittsburgh Coal Company")
	
replace horizontal = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Pressed Steel Car")
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Pressed Steel Car")
	
replace vertical = 1 if ///
	(cnameA == "Ray Consolidated Copper Company" & cnameB == "US Reduction and Refining") ///
	| (cnameA == "US Reduction and Refining" & cnameB == "Ray Consolidated Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Ray Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Ray Consolidated Copper Company")
	
replace horizontal = 1 if ///
	(cnameA == "Republic Iron and Steel" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Republic Iron and Steel")
	
replace horizontal = 1 if ///
	(cnameA == "Rubber Goods Mfg Company" & cnameB == "US Rubber") ///
	| (cnameA == "US Rubber" & cnameB == "Rubber Goods Mfg Company")
	
replace vertical = 1 if ///
	(cnameA == "The Pullman Co" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "The Pullman Co")
	
replace vertical = 1 if ///
	(cnameA == "US Reduction and Refining" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "US Reduction and Refining")
	
replace no_relationship = 1 if interlock & vertical + horizontal == 0 & year_std == 1910
	
*1915
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "Associated Merchants Company") ///
	| (cnameA == "Associated Merchants Company" & cnameB == "Adams Express Co.")
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "Montgomery Ward and Co") ///
	| (cnameA == "Montgomery Ward and Co" & cnameB == "Adams Express Co.")
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "New York Dock") ///
	| (cnameA == "New York Dock" & cnameB == "Adams Express Co.")
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "United Dry Goods") ///
	| (cnameA == "United Dry Goods" & cnameB == "Adams Express Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Alaska Gold Mines Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Alaska Gold Mines Company")
	
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "American Smelters' Security Co.") ///
	| (cnameA == "American Smelters' Security Co." & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "American Smelting and Refining") ///
	| (cnameA == "American Smelting and Refining" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Colorado Fuel and Iron Company") ///
	| (cnameA == "Colorado Fuel and Iron Company" & cnameB == "Allis-Chalmers Manufacturing")
	
replace vertical = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "American Express Co.") ///
	| (cnameA == "American Express Co." & cnameB == "Amalgamated Copper")
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "Anaconda Copper Mining Company") ///
	| (cnameA == "Anaconda Copper Mining Company" & cnameB == "Amalgamated Copper")
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "Inspiration Consolidated Copper Company") ///
	| (cnameA == "Inspiration Consolidated Copper Company" & cnameB == "Amalgamated Copper")
replace horizontal = 1 if ///
	(cnameA == "Amalgamated Copper" & cnameB == "National Enameling and Stamping") ///
	| (cnameA == "National Enameling and Stamping" & cnameB == "Amalgamated Copper")
	
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "American Beet Sugar Co.") ///
	| (cnameA == "American Beet Sugar Co." & cnameB == "American Agricultural Chemical Co.")
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "American Cotton Oil Co.") ///
	| (cnameA == "American Cotton Oil Co." & cnameB == "American Agricultural Chemical Co.")
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "American Sugar Refining Co.") ///
	| (cnameA == "American Sugar Refining Co." & cnameB == "American Agricultural Chemical Co.")
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "United Cigar Manufacturers") ///
	| (cnameA == "United Cigar Manufacturers" & cnameB == "American Agricultural Chemical Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "American Locomotive Company") ///
	| (cnameA == "American Locomotive Company" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "Baldwin Locomotive Works") ///
	| (cnameA == "Baldwin Locomotive Works" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "American Brake Shoe & Foundry Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Can Company" & cnameB == "Phelps Dodge and Company") ///
	| (cnameA == "Phelps Dodge and Company" & cnameB == "American Can Company")
	
replace vertical = 1 if ///
	(cnameA == "American Car & Foundry" & cnameB == "The Texas Co") ///
	| (cnameA == "The Texas Co" & cnameB == "American Car & Foundry")
	
replace vertical = 1 if ///
	(cnameA == "American Cotton Oil Co." & cnameB == "General Chemical Co.") ///
	| (cnameA == "General Chemical Co." & cnameB == "American Cotton Oil Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Bethlehem Steel Corporation") ///
	| (cnameA == "Bethlehem Steel Corporation" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "American Locomotive Company")
	
replace ownership = 1 if year_std == 1915 & ///
	((cnameA == "American Malt Corporation" & cnameB == "American Malting") ///
	| (cnameA == "American Malting" & cnameB == "American Malt Corporation"))
	
replace horizontal = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "American Smelters' Security Co.")
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "American Smelters' Security Co.")
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "American Smelters' Security Co.")
replace horizontal = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "American Smelters' Security Co.")
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "American Smelters' Security Co.")
	
replace horizontal = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "American Smelting and Refining")
replace horizontal = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "American Smelting and Refining")
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "American Smelting and Refining")
	
replace horizontal = 1 if ///
	(cnameA == "Associated Merchants Company" & cnameB == "United Dry Goods") ///
	| (cnameA == "United Dry Goods" & cnameB == "Associated Merchants Company")
	
replace vertical = 1 if ///
	(cnameA == "Associated Oil Co." & cnameB == "Pacific Mail Steamship Co.") ///
	| (cnameA == "Pacific Mail Steamship Co." & cnameB == "Associated Oil Co.")
	
replace vertical = 1 if ///
	(cnameA == "Baldwin Locomotive Works" & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "Baldwin Locomotive Works")
	
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Maxwell Motors") ///
	| (cnameA == "Maxwell Motors" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Bethlehem Steel Corporation")
replace horizontal = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Bethlehem Steel Corporation")
	
replace vertical = 1 if ///
	(cnameA == "Brown Shoe Co." & cnameB == "May Department Stores") ///
	| (cnameA == "May Department Stores" & cnameB == "Brown Shoe Co.")
replace vertical = 1 if ///
	(cnameA == "Brown Shoe Co." & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "Brown Shoe Co.")
	
replace vertical = 1 if ///
	(cnameA == "California Petroleum Corporation" & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "California Petroleum Corporation")
replace horizontal = 1 if ///
	(cnameA == "California Petroleum Corporation" & cnameB == "Mexican Petroleum") ///
	| (cnameA == "Mexican Petroleum" & cnameB == "California Petroleum Corporation")
	
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Chino Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "Cluett, Peabody & Co." & cnameB == "May Department Stores") ///
	| (cnameA == "May Department Stores" & cnameB == "Cluett, Peabody & Co.")
replace horizontal = 1 if ///
	(cnameA == "Cluett, Peabody & Co." & cnameB == "National Cloak and Suit Company") ///
	| (cnameA == "National Cloak and Suit Company" & cnameB == "Cluett, Peabody & Co.")
replace vertical = 1 if ///
	(cnameA == "Cluett, Peabody & Co." & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "Cluett, Peabody & Co.")
	
replace vertical = 1 if ///
	(cnameA == "Corn Products Refining Co." & cnameB == "General Chemical Co.") ///
	| (cnameA == "General Chemical Co." & cnameB == "Corn Products Refining Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Distillers Securites Corp." & cnameB == "US Industrial Alcohol") ///
	| (cnameA == "US Industrial Alcohol" & cnameB == "Distillers Securites Corp.")
	
replace vertical = 1 if ///
	(cnameA == "Federal Mining and Smelting Company" & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "Federal Mining and Smelting Company")
replace horizontal = 1 if ///
	(cnameA == "Federal Mining and Smelting Company" & cnameB == "Guggenheim Exploration Co.") ///
	| (cnameA == "Guggenheim Exploration Co." & cnameB == "Federal Mining and Smelting Company")
replace horizontal = 1 if ///
	(cnameA == "Federal Mining and Smelting Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Federal Mining and Smelting Company")
	
replace vertical = 1 if ///
	(cnameA == "General Development Company" & cnameB == "Granby Consolidated Smelting and Power Company") ///
	| (cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "General Development Company")
replace horizontal = 1 if ///
	(cnameA == "General Development Company" & cnameB == "Miami Copper Company") ///
	| (cnameA == "Miami Copper Company" & cnameB == "General Development Company")
replace horizontal = 1 if ///
	(cnameA == "General Development Company" & cnameB == "Ontario Silver Mining") ///
	| (cnameA == "Ontario Silver Mining" & cnameB == "General Development Company")
replace horizontal = 1 if ///
	(cnameA == "General Development Company" & cnameB == "Pittsburgh Steel") ///
	| (cnameA == "Pittsburgh Steel" & cnameB == "General Development Company")
	
replace vertical = 1 if ///
	(cnameA == "Goodrich (The B.F.) Co." & cnameB == "Studebaker Corp") ///
	| (cnameA == "Studebaker Corp" & cnameB == "Goodrich (The B.F.) Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Miami Copper Company") ///
	| (cnameA == "Miami Copper Company" & cnameB == "Granby Consolidated Smelting and Power Company")
replace vertical = 1 if ///
	(cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Pittsburgh Steel") ///
	| (cnameA == "Pittsburgh Steel" & cnameB == "Granby Consolidated Smelting and Power Company")
	
replace vertical = 1 if ///
	(cnameA == "Guggenheim Exploration Co." & cnameB == "International Steam Pump") ///
	| (cnameA == "International Steam Pump" & cnameB == "Guggenheim Exploration Co.")
replace horizontal = 1 if ///
	(cnameA == "Guggenheim Exploration Co." & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Guggenheim Exploration Co.")
replace horizontal = 1 if ///
	(cnameA == "Guggenheim Exploration Co." & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Guggenheim Exploration Co.")
replace ownership = 1 if year_std == 1915 & ///
	((cnameA == "Guggenheim Exploration Co." & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Guggenheim Exploration Co."))
	
replace vertical = 1 if ///
	(cnameA == "Ingersoll-Rand Company" & cnameB == "International Harvester Corp") ///
	| (cnameA == "International Harvester Corp" & cnameB == "Ingersoll-Rand Company")
replace vertical = 1 if ///
	(cnameA == "Ingersoll-Rand Company" & cnameB == "International Harvester of NJ") ///
	| (cnameA == "International Harvester of NJ" & cnameB == "Ingersoll-Rand Company")
replace vertical = 1 if ///
	(cnameA == "Ingersoll-Rand Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Ingersoll-Rand Company")
	
replace horizontal = 1 if ///
	(cnameA == "Inspiration Consolidated Copper Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Inspiration Consolidated Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Inspiration Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Inspiration Consolidated Copper Company")
	
replace horizontal = 1 if ///
	(cnameA == "International Agricultural Corporation" & cnameB == "International Harvester of NJ") ///
	| (cnameA == "International Harvester of NJ" & cnameB == "International Agricultural Corporation")
replace vertical = 1 if ///
	(cnameA == "International Agricultural Corporation" & cnameB == "Tobacco Products Corporation") ///
	| (cnameA == "Tobacco Products Corporation" & cnameB == "International Agricultural Corporation")
	
replace horizontal = 1 if ///
	(cnameA == "International Harvester Corp" & cnameB == "International Harvester of NJ") ///
	| (cnameA == "International Harvester of NJ" & cnameB == "International Harvester Corp")
replace vertical = 1 if ///
	(cnameA == "International Harvester Corp" & cnameB == "Lackawanna Steel") ///
	| (cnameA == "Lackawanna Steel" & cnameB == "International Harvester Corp")
replace vertical = 1 if ///
	(cnameA == "International Harvester Corp" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "International Harvester Corp")
	
replace vertical = 1 if ///
	(cnameA == "International Harvester of NJ" & cnameB == "Lackawanna Steel") ///
	| (cnameA == "Lackawanna Steel" & cnameB == "International Harvester of NJ")
replace vertical = 1 if ///
	(cnameA == "International Harvester of NJ" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "International Harvester of NJ")
	
replace horizontal = 1 if ///
	(cnameA == "International Mercantile Marine" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "International Mercantile Marine")
replace vertical = 1 if ///
	(cnameA == "International Mercantile Marine" & cnameB == "South Porto Rico Sugar Company") ///
	| (cnameA == "South Porto Rico Sugar Company" & cnameB == "International Mercantile Marine")
	
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "International Steam Pump")
replace vertical = 1 if ///
	(cnameA == "International Steam Pump" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "International Steam Pump")
	
replace vertical = 1 if ///
	(cnameA == "Jefferson and Clearfield Coal and Iron Company" & cnameB == "Lackawanna Steel") ///
	| (cnameA == "Lackawanna Steel" & cnameB == "Jefferson and Clearfield Coal and Iron Company")
	
replace vertical = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "Pressed Steel Car") ///
	| (cnameA == "Pressed Steel Car" & cnameB == "Lackawanna Steel")
replace vertical = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "The Pullman Co") ///
	| (cnameA == "The Pullman Co" & cnameB == "Lackawanna Steel")
replace horizontal = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Lackawanna Steel")

replace vertical = 1 if ///
	(cnameA == "Maxwell Motors" & cnameB == "US Realty & Improvement") ///
	| (cnameA == "US Realty & Improvement" & cnameB == "Maxwell Motors")
	
replace vertical = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "National Cloak and Suit Company") ///
	| (cnameA == "National Cloak and Suit Company" & cnameB == "May Department Stores")
replace horizontal = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "May Department Stores")
replace vertical = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "United Cigar Manufacturers") ///
	| (cnameA == "United Cigar Manufacturers" & cnameB == "May Department Stores")
replace horizontal = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "May Department Stores")
	
replace vertical = 1 if ///
	(cnameA == "National Cloak and Suit Company" & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "National Cloak and Suit Company")
	
replace horizontal = 1 if ///
	(cnameA == "Nevada Consolidated Copper Company" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Nevada Consolidated Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Nevada Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Nevada Consolidated Copper Company")
		
replace vertical = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Republic Iron and Steel") ///
	| (cnameA == "Republic Iron and Steel" & cnameB == "Pittsburgh Coal Company")
replace vertical = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Pittsburgh Coal Company")
	
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Pressed Steel Car")
	
replace horizontal = 1 if ///
	(cnameA == "Ray Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Ray Consolidated Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "Rumely Co" & cnameB == "Standard Milling") ///
	| (cnameA == "Standard Milling" & cnameB == "Rumely Co")
	
replace vertical = 1 if ///
	(cnameA == "Sears, Roebuck & Co" & cnameB == "United Cigar Manufacturers") ///
	| (cnameA == "United Cigar Manufacturers" & cnameB == "Sears, Roebuck & Co")
replace horizontal = 1 if ///
	(cnameA == "Sears, Roebuck & Co" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "Sears, Roebuck & Co")
	
replace vertical = 1 if ///
	(cnameA == "Studebaker Corp" & cnameB == "The Texas Co") ///
	| (cnameA == "The Texas Co" & cnameB == "Studebaker Corp")
	
replace vertical = 1 if ///
	(cnameA == "The Pullman Co" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "The Pullman Co")
	
replace vertical = 1 if ///
	(cnameA == "United Fruit Company" & cnameB == "Virginia-Carolina Chemical") ///
	| (cnameA == "Virginia-Carolina Chemical" & cnameB == "United Fruit Company")

replace no_relationship = 1 if interlock & vertical + horizontal == 0 & year_std == 1915
	
*1920
replace horizontal = 1 if ///
	(cnameA == "ALLIANCE RLTY CO" & cnameB == "US Realty & Improvement") ///
	| (cnameA == "US Realty & Improvement" & cnameB == "ALLIANCE RLTY CO")
	
replace horizontal = 1 if ///
	(cnameA == "AMALGAMATED SUGAR CO" & cnameB == "Cuba Cane Sugar") ///
	| (cnameA == "Cuba Cane Sugar" & cnameB == "AMALGAMATED SUGAR CO")
replace horizontal = 1 if ///
	(cnameA == "AMALGAMATED SUGAR CO" & cnameB == "South Porto Rico Sugar Company") ///
	| (cnameA == "South Porto Rico Sugar Company" & cnameB == "AMALGAMATED SUGAR CO")
	
replace vertical = 1 if ///
	(cnameA == "AMERICAN BOSCH MAGNETO CORP" & cnameB == "BETHLEHEM MOTORS CORP") ///
	| (cnameA == "BETHLEHEM MOTORS CORP" & cnameB == "AMERICAN BOSCH MAGNETO CORP")
	
replace vertical = 1 if ///
	(cnameA == "AMERICAN LA FRANCE FIRE ENGINE" & cnameB == "Crucible Steel Company") ///
	| (cnameA == "Crucible Steel Company" & cnameB == "AMERICAN LA FRANCE FIRE ENGINE")
replace vertical = 1 if ///
	(cnameA == "AMERICAN LA FRANCE FIRE ENGINE" & cnameB == "Worthington Pump and Machinery") ///
	| (cnameA == "Worthington Pump and Machinery" & cnameB == "AMERICAN LA FRANCE FIRE ENGINE")
	
replace horizontal = 1 if ///
	(cnameA == "AMERICAN RY EXPRESS CO" & cnameB == "Adams Express Co.") ///
	| (cnameA == "Adams Express Co." & cnameB == "AMERICAN RY EXPRESS CO")
replace horizontal = 1 if ///
	(cnameA == "AMERICAN RY EXPRESS CO" & cnameB == "American Express Co.") ///
	| (cnameA == "American Express Co." & cnameB == "AMERICAN RY EXPRESS CO")
replace vertical = 1 if ///
	(cnameA == "AMERICAN RY EXPRESS CO" & cnameB == "GENERAL AMERN TANK CAR CORP") ///
	| (cnameA == "GENERAL AMERN TANK CAR CORP" & cnameB == "AMERICAN RY EXPRESS CO")
replace vertical = 1 if ///
	(cnameA == "AMERICAN RY EXPRESS CO" & cnameB == "Montgomery Ward and Co") ///
	| (cnameA == "Montgomery Ward and Co" & cnameB == "AMERICAN RY EXPRESS CO")
replace vertical = 1 if ///
	(cnameA == "AMERICAN RY EXPRESS CO" & cnameB == "Pacific Mail Steamship Co.") ///
	| (cnameA == "Pacific Mail Steamship Co." & cnameB == "AMERICAN RY EXPRESS CO")
replace horizontal = 1 if ///
	(cnameA == "AMERICAN RY EXPRESS CO" & cnameB == "Wells Fargo and Co") ///
	| (cnameA == "Wells Fargo and Co" & cnameB == "AMERICAN RY EXPRESS CO")
	
replace vertical = 1 if ///
	(cnameA == "AMERICAN SHIP & COMM CORP" & cnameB == "ATLANTIC FRUIT CO") ///
	| (cnameA == "ATLANTIC FRUIT CO" & cnameB == "AMERICAN SHIP & COMM CORP")
replace horizontal = 1 if ///
	(cnameA == "AMERICAN SHIP & COMM CORP" & cnameB == "Gaston Williams and Wigmore") ///
	| (cnameA == "Gaston Williams and Wigmore" & cnameB == "AMERICAN SHIP & COMM CORP")
replace vertical = 1 if ///
	(cnameA == "AMERICAN SHIP & COMM CORP" & cnameB == "United States Express Co") ///
	| (cnameA == "United States Express Co" & cnameB == "AMERICAN SHIP & COMM CORP")
replace vertical = 1 if ///
	(cnameA == "AMERICAN SHIP & COMM CORP" & cnameB == "Wells Fargo and Co") ///
	| (cnameA == "Wells Fargo and Co" & cnameB == "AMERICAN SHIP & COMM CORP")
	
replace vertical = 1 if ///
	(cnameA == "AMERICAN WHOLESALE CORP" & cnameB == "Continental Can Co.") ///
	| (cnameA == "Continental Can Co." & cnameB == "AMERICAN WHOLESALE CORP")
replace vertical = 1 if ///
	(cnameA == "AMERICAN WHOLESALE CORP" & cnameB == "May Department Stores") ///
	| (cnameA == "May Department Stores" & cnameB == "AMERICAN WHOLESALE CORP")
replace vertical = 1 if ///
	(cnameA == "AMERICAN WHOLESALE CORP" & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "AMERICAN WHOLESALE CORP")
replace vertical = 1 if ///
	(cnameA == "AMERICAN WHOLESALE CORP" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "AMERICAN WHOLESALE CORP")
	
replace horizontal = 1 if ///
	(cnameA == "AMERICAN ZINC LEAD & SMLT CO" & cnameB == "US Smelting Refining and Mining Co") ///
	| (cnameA == "US Smelting Refining and Mining Co" & cnameB == "AMERICAN ZINC LEAD & SMLT CO")
	
replace vertical = 1 if ///
	(cnameA == "ATLANTIC FRUIT CO" & cnameB == "AUSTIN NICHOLS & CO INC") ///
	| (cnameA == "AUSTIN NICHOLS & CO INC" & cnameB == "ATLANTIC FRUIT CO")
replace vertical = 1 if ///
	(cnameA == "ATLANTIC FRUIT CO" & cnameB == "International Agricultural Corporation") ///
	| (cnameA == "International Agricultural Corporation" & cnameB == "ATLANTIC FRUIT CO")
	
replace vertical = 1 if ///
	(cnameA == "ATLANTIC GULF & WEST INDIES SS" & cnameB == "American Ship Building") ///
	| (cnameA == "American Ship Building" & cnameB == "ATLANTIC GULF & WEST INDIES SS")
replace vertical = 1 if ///
	(cnameA == "ATLANTIC GULF & WEST INDIES SS" & cnameB == "PUNTA ALEGRE SUGAR CO") ///
	| (cnameA == "PUNTA ALEGRE SUGAR CO" & cnameB == "ATLANTIC GULF & WEST INDIES SS")
	
replace vertical = 1 if ///
	(cnameA == "ATLAS TACK CORP" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "ATLAS TACK CORP")
	
replace vertical = 1 if ///
	(cnameA == "AUTOSALES CORP" & cnameB == "Allis-Chalmers Manufacturing") ///
	| (cnameA == "Allis-Chalmers Manufacturing" & cnameB == "AUTOSALES CORP")
	
replace vertical = 1 if ///
	(cnameA == "Adams Express Co." & cnameB == "Montgomery Ward and Co") ///
	| (cnameA == "Montgomery Ward and Co" & cnameB == "Adams Express Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Advance Rumely" & cnameB == "Allis-Chalmers Manufacturing") ///
	| (cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Advance Rumely")
	
replace horizontal = 1 if ///
	(cnameA == "Alaska Gold Mines Company" & cnameB == "Butte and Superior Mining") ///
	| (cnameA == "Butte and Superior Mining" & cnameB == "Alaska Gold Mines Company")
replace vertical = 1 if ///
	(cnameA == "Alaska Gold Mines Company" & cnameB == "Granby Consolidated Smelting and Power Company") ///
	| (cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Alaska Gold Mines Company")
	
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Colorado Fuel and Iron Company") ///
	| (cnameA == "Colorado Fuel and Iron Company" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Computing Tabulating Recording") ///
	| (cnameA == "Computing Tabulating Recording" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "INTERNATIONAL MOTOR TRUCK") ///
	| (cnameA == "INTERNATIONAL MOTOR TRUCK" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Allis-Chalmers Manufacturing")
replace vertical = 1 if ///
	(cnameA == "Allis-Chalmers Manufacturing" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Allis-Chalmers Manufacturing")
	
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "PUNTA ALEGRE SUGAR CO") ///
	| (cnameA == "PUNTA ALEGRE SUGAR CO" & cnameB == "American Agricultural Chemical Co.")
replace vertical = 1 if ///
	(cnameA == "American Agricultural Chemical Co." & cnameB == "United Fruit Company") ///
	| (cnameA == "United Fruit Company" & cnameB == "American Agricultural Chemical Co.")
	
replace horizontal = 1 if ///
	(cnameA == "American Beet Sugar Co." & cnameB == "GUANTANAMO SUGAR CO") ///
	| (cnameA == "GUANTANAMO SUGAR CO" & cnameB == "American Beet Sugar Co.")
replace vertical = 1 if ///
	(cnameA == "American Beet Sugar Co." & cnameB == "White Motor") ///
	| (cnameA == "White Motor" & cnameB == "American Beet Sugar Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "American Steel Foundries") ///
	| (cnameA == "American Steel Foundries" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "Baldwin Locomotive Works") ///
	| (cnameA == "Baldwin Locomotive Works" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "INTERNATIONAL MOTOR TRUCK") ///
	| (cnameA == "INTERNATIONAL MOTOR TRUCK" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "Midvale Steel and Ordnance") ///
	| (cnameA == "Midvale Steel and Ordnance" & cnameB == "American Brake Shoe & Foundry Co.")
replace vertical = 1 if ///
	(cnameA == "American Brake Shoe & Foundry Co." & cnameB == "Railway Steel Spring") ///
	| (cnameA == "Railway Steel Spring" & cnameB == "American Brake Shoe & Foundry Co.")
	
replace vertical = 1 if ///
	(cnameA == "American International" & cnameB == "Cuba Cane Sugar") ///
	| (cnameA == "Cuba Cane Sugar" & cnameB == "American International")
replace vertical = 1 if ///
	(cnameA == "American International" & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "American International")
replace vertical = 1 if ///
	(cnameA == "American International" & cnameB == "International Paper") ///
	| (cnameA == "International Paper" & cnameB == "American International")
replace vertical = 1 if ///
	(cnameA == "American International" & cnameB == "MARTIN PARRY CORP") ///
	| (cnameA == "MARTIN PARRY CORP" & cnameB == "American International")
replace vertical = 1 if ///
	(cnameA == "American International" & cnameB == "NATIONAL ACME CO") ///
	| (cnameA == "NATIONAL ACME CO" & cnameB == "American International")
	
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Bethlehem Steel Corporation") ///
	| (cnameA == "Bethlehem Steel Corporation" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Crucible Steel Company") ///
	| (cnameA == "Crucible Steel Company" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Gulf States Steel") ///
	| (cnameA == "Gulf States Steel" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Midvale Steel and Ordnance") ///
	| (cnameA == "Midvale Steel and Ordnance" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "NATIONAL ACME CO") ///
	| (cnameA == "NATIONAL ACME CO" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "American Locomotive Company")
replace vertical = 1 if ///
	(cnameA == "American Locomotive Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "American Locomotive Company")
	
replace vertical = 1 if ///
	(cnameA == "American Ship Building" & cnameB == "Colorado Fuel and Iron Company") ///
	| (cnameA == "Colorado Fuel and Iron Company" & cnameB == "American Ship Building")
replace vertical = 1 if ///
	(cnameA == "American Ship Building" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "American Ship Building")
	
replace vertical = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Chile Copper") ///
	| (cnameA == "Chile Copper" & cnameB == "American Smelters' Security Co.")
replace horizontal = 1 if ///
	(cnameA == "American Smelters' Security Co." & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "American Smelters' Security Co.")
	
replace vertical = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Chile Copper") ///
	| (cnameA == "Chile Copper" & cnameB == "American Smelting and Refining")
replace horizontal = 1 if ///
	(cnameA == "American Smelting and Refining" & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "American Smelting and Refining")
	
replace vertical = 1 if ///
	(cnameA == "American Steel Foundries" & cnameB == "EMERSON BRANTINGHAM CORP") ///
	| (cnameA == "EMERSON BRANTINGHAM CORP" & cnameB == "American Steel Foundries")
replace vertical = 1 if ///
	(cnameA == "American Steel Foundries" & cnameB == "INTERNATIONAL MOTOR TRUCK") ///
	| (cnameA == "INTERNATIONAL MOTOR TRUCK" & cnameB == "American Steel Foundries")
	
replace horizontal = 1 if ///
	(cnameA == "American Sugar Refining Co." & cnameB == "PUNTA ALEGRE SUGAR CO") ///
	| (cnameA == "PUNTA ALEGRE SUGAR CO" & cnameB == "American Sugar Refining Co.")
	
replace horizontal = 1 if ///
	(cnameA == "American Sumatra Tobacco" & cnameB == "CONSOLIDATED CIGAR CORP") ///
	| (cnameA == "CONSOLIDATED CIGAR CORP" & cnameB == "American Sumatra Tobacco")
replace horizontal = 1 if ///
	(cnameA == "American Sumatra Tobacco" & cnameB == "PORTO RICAN AMERN TOB CO") ///
	| (cnameA == "PORTO RICAN AMERN TOB CO" & cnameB == "American Sumatra Tobacco")
	
replace vertical = 1 if ///
	(cnameA == "American Writing Paper" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "American Writing Paper")
replace vertical = 1 if ///
	(cnameA == "American Writing Paper" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "American Writing Paper")
	
replace horizontal = 1 if ///
	(cnameA == "Anaconda Copper Mining Company" & cnameB == "BUTTE COPPER & ZINC CO") ///
	| (cnameA == "BUTTE COPPER & ZINC CO" & cnameB == "Anaconda Copper Mining Company")
replace horizontal = 1 if ///
	(cnameA == "Anaconda Copper Mining Company" & cnameB == "Cerro de Pasco Copper") ///
	| (cnameA == "Cerro de Pasco Copper" & cnameB == "Anaconda Copper Mining Company")
replace horizontal = 1 if ///
	(cnameA == "Anaconda Copper Mining Company" & cnameB == "Greene Cananea Copper") ///
	| (cnameA == "Greene Cananea Copper" & cnameB == "Anaconda Copper Mining Company")
replace horizontal = 1 if ///
	(cnameA == "Anaconda Copper Mining Company" & cnameB == "Inspiration Consolidated Copper Company") ///
	| (cnameA == "Inspiration Consolidated Copper Company" & cnameB == "Anaconda Copper Mining Company")
	
replace horizontal = 1 if ///
	(cnameA == "BUTTE COPPER & ZINC CO" & cnameB == "Greene Cananea Copper") ///
	| (cnameA == "Greene Cananea Copper" & cnameB == "BUTTE COPPER & ZINC CO")
replace horizontal = 1 if ///
	(cnameA == "BUTTE COPPER & ZINC CO" & cnameB == "Inspiration Consolidated Copper Company") ///
	| (cnameA == "Inspiration Consolidated Copper Company" & cnameB == "BUTTE COPPER & ZINC CO")
	
replace vertical = 1 if ///
	(cnameA == "Baldwin Locomotive Works" & cnameB == "HASKELL & BARKER CAR CO") ///
	| (cnameA == "HASKELL & BARKER CAR CO" & cnameB == "Baldwin Locomotive Works")
replace vertical = 1 if ///
	(cnameA == "Baldwin Locomotive Works" & cnameB == "Midvale Steel and Ordnance") ///
	| (cnameA == "Midvale Steel and Ordnance" & cnameB == "Baldwin Locomotive Works")
	
replace horizontal = 1 if ///
	(cnameA == "Barrett" & cnameB == "NATIONAL ANILINE & CHEMICAL CO") ///
	| (cnameA == "NATIONAL ANILINE & CHEMICAL CO" & cnameB == "Barrett")
	
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "FAIRBANKS CO") ///
	| (cnameA == "FAIRBANKS CO" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "OTIS ELEVATOR CO") ///
	| (cnameA == "OTIS ELEVATOR CO" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "Stutz Motor Car") ///
	| (cnameA == "Stutz Motor Car" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "US Smelting Refining and Mining Co") ///
	| (cnameA == "US Smelting Refining and Mining Co" & cnameB == "Bethlehem Steel Corporation")
replace vertical = 1 if ///
	(cnameA == "Bethlehem Steel Corporation" & cnameB == "VANADIUM CORP AMER") ///
	| (cnameA == "VANADIUM CORP AMER" & cnameB == "Bethlehem Steel Corporation")
	
replace horizontal = 1 if ///
	(cnameA == "Brown Shoe Co." & cnameB == "REIS ROBERT & CO") ///
	| (cnameA == "REIS ROBERT & CO" & cnameB == "Brown Shoe Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Burns Brothers" & cnameB == "Dome Mines Company") ///
	| (cnameA == "Dome Mines Company" & cnameB == "Burns Brothers")
	
replace horizontal = 1 if ///
	(cnameA == "Butte and Superior Mining" & cnameB == "Chino Copper Company") ///
	| (cnameA == "Chino Copper Company" & cnameB == "Butte and Superior Mining")
replace vertical = 1 if ///
	(cnameA == "Butte and Superior Mining" & cnameB == "Granby Consolidated Smelting and Power Company") ///
	| (cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Butte and Superior Mining")
replace horizontal = 1 if ///
	(cnameA == "Butte and Superior Mining" & cnameB == "INTERNATIONAL NICKEL CO CDA LTD") ///
	| (cnameA == "INTERNATIONAL NICKEL CO CDA LTD" & cnameB == "Butte and Superior Mining")
replace horizontal = 1 if ///
	(cnameA == "Butte and Superior Mining" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Butte and Superior Mining")
replace vertical = 1 if ///
	(cnameA == "Butte and Superior Mining" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Butte and Superior Mining")
replace horizontal = 1 if ///
	(cnameA == "Butte and Superior Mining" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Butte and Superior Mining")
	
replace vertical = 1 if ///
	(cnameA == "CADDO CENT OIL REFNG CORP" & cnameB == "TRANSCONTINENTAL OIL CO") ///
	| (cnameA == "TRANSCONTINENTAL OIL CO" & cnameB == "CADDO CENT OIL REFNG CORP")
	
replace vertical = 1 if ///
	(cnameA == "CALUMET & HECLA CONS COPPER CO" & cnameB == "US Smelting Refining and Mining Co") ///
	| (cnameA == "US Smelting Refining and Mining Co" & cnameB == "CALUMET & HECLA CONS COPPER CO")
replace horizontal = 1 if ///
	(cnameA == "CALUMET & HECLA CONS COPPER CO" & cnameB == "US Smelting Refining and Mining Co") ///
	| (cnameA == "US Smelting Refining and Mining Co" & cnameB == "CALUMET & HECLA CONS COPPER CO")
	
replace horizontal = 1 if ///
	(cnameA == "CERTAIN TEED PRODS CORP" & cnameB == "Wilson") ///
	| (cnameA == "Wilson" & cnameB == "CERTAIN TEED PRODS CORP")
	
replace vertical = 1 if ///
	(cnameA == "COCA COLA CO" & cnameB == "Cuba Cane Sugar") ///
	| (cnameA == "Cuba Cane Sugar" & cnameB == "COCA COLA CO")
replace horizontal = 1 if ///
	(cnameA == "COCA COLA CO" & cnameB == "NUNNALLY CO") ///
	| (cnameA == "NUNNALLY CO" & cnameB == "COCA COLA CO")
replace vertical = 1 if ///
	(cnameA == "COCA COLA CO" & cnameB == "PUNTA ALEGRE SUGAR CO") ///
	| (cnameA == "PUNTA ALEGRE SUGAR CO" & cnameB == "COCA COLA CO")
	
replace vertical = 1 if ///
	(cnameA == "CONTINENTAL CANDY CORP" & cnameB == "TEMTOR CORN & FRUIT PKTS CO") ///
	| (cnameA == "TEMTOR CORN & FRUIT PKTS CO" & cnameB == "CONTINENTAL CANDY CORP")
	
replace horizontal = 1 if ///
	(cnameA == "COSDEN & CO" & cnameB == "INDIAHOMA REFINING CO") ///
	| (cnameA == "INDIAHOMA REFINING CO" & cnameB == "COSDEN & CO")
	
replace horizontal = 1 if ///
	(cnameA == "California Petroleum Corporation" & cnameB == "Pan American Petroleum and Transport") ///
	| (cnameA == "Pan American Petroleum and Transport" & cnameB == "California Petroleum Corporation")
	
replace vertical = 1 if ///
	(cnameA == "Central Foundry" & cnameB == "IRON PRODUCTS CORP") ///
	| (cnameA == "IRON PRODUCTS CORP" & cnameB == "Central Foundry")
	
replace horizontal = 1 if ///
	(cnameA == "Cerro de Pasco Copper" & cnameB == "Homestake Mining Company") ///
	| (cnameA == "Homestake Mining Company" & cnameB == "Cerro de Pasco Copper")
	
replace vertical = 1 if ///
	(cnameA == "Chandler Motor Car" & cnameB == "Lee Rubber and Tire") ///
	| (cnameA == "Lee Rubber and Tire" & cnameB == "Chandler Motor Car")
replace vertical = 1 if ///
	(cnameA == "Chandler Motor Car" & cnameB == "MULLINS BODY CORP") ///
	| (cnameA == "MULLINS BODY CORP" & cnameB == "Chandler Motor Car")
replace vertical = 1 if ///
	(cnameA == "Chandler Motor Car" & cnameB == "OHIO BODY & BLOWER CO") ///
	| (cnameA == "OHIO BODY & BLOWER CO" & cnameB == "Chandler Motor Car")
replace vertical = 1 if ///
	(cnameA == "Chandler Motor Car" & cnameB == "OTIS STL CO") ///
	| (cnameA == "OTIS STL CO" & cnameB == "Chandler Motor Car")
replace vertical = 1 if ///
	(cnameA == "Chandler Motor Car" & cnameB == "PARISH & BINGHAM") ///
	| (cnameA == "PARISH & BINGHAM" & cnameB == "Chandler Motor Car")
replace vertical = 1 if ///
	(cnameA == "Chandler Motor Car" & cnameB == "Transue and Williams Steel Forging") ///
	| (cnameA == "Transue and Williams Steel Forging" & cnameB == "Chandler Motor Car")
replace vertical = 1 if ///
	(cnameA == "Chandler Motor Car" & cnameB == "United Alloy Steel") ///
	| (cnameA == "United Alloy Steel" & cnameB == "Chandler Motor Car")
	
replace vertical = 1 if ///
	(cnameA == "Chile Copper" & cnameB == "Federal Mining and Smelting Company") ///
	| (cnameA == "Federal Mining and Smelting Company" & cnameB == "Chile Copper")
replace horizontal = 1 if ///
	(cnameA == "Chile Copper" & cnameB == "KENNECOTT COPPER CORP") ///
	| (cnameA == "KENNECOTT COPPER CORP" & cnameB == "Chile Copper")
replace horizontal = 1 if ///
	(cnameA == "Chile Copper" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Chile Copper")
replace horizontal = 1 if ///
	(cnameA == "Chile Copper" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Chile Copper")
	
replace vertical = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Granby Consolidated Smelting and Power Company") ///
	| (cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Chino Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Chino Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Chino Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "Cluett, Peabody & Co." & cnameB == "May Department Stores") ///
	| (cnameA == "May Department Stores" & cnameB == "Cluett, Peabody & Co.")
replace horizontal = 1 if ///
	(cnameA == "Cluett, Peabody & Co." & cnameB == "National Cloak and Suit Company") ///
	| (cnameA == "National Cloak and Suit Company" & cnameB == "Cluett, Peabody & Co.")
replace vertical = 1 if ///
	(cnameA == "Cluett, Peabody & Co." & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "Cluett, Peabody & Co.")
replace vertical = 1 if ///
	(cnameA == "Cluett, Peabody & Co." & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "Cluett, Peabody & Co.")
	
replace vertical = 1 if ///
	(cnameA == "Colorado Fuel and Iron Company" & cnameB == "Consolidation Coal Company") ///
	| (cnameA == "Consolidation Coal Company" & cnameB == "Colorado Fuel and Iron Company")
	
replace vertical = 1 if ///
	(cnameA == "Consolidation Coal Company" & cnameB == "FREEPORT TEX CO") ///
	| (cnameA == "FREEPORT TEX CO" & cnameB == "Consolidation Coal Company")
	
replace vertical = 1 if ///
	(cnameA == "Continental Can Co." & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Continental Can Co.")
	
replace vertical = 1 if ///
	(cnameA == "Crucible Steel Company" & cnameB == "Pittsburgh Coal Company") ///
	| (cnameA == "Pittsburgh Coal Company" & cnameB == "Crucible Steel Company")
	
replace vertical = 1 if ///
	(cnameA == "Cuba Cane Sugar" & cnameB == "Gaston Williams and Wigmore") ///
	| (cnameA == "Gaston Williams and Wigmore" & cnameB == "Cuba Cane Sugar")
replace vertical = 1 if ///
	(cnameA == "Cuba Cane Sugar" & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "Cuba Cane Sugar")
replace horizontal = 1 if ///
	(cnameA == "Cuba Cane Sugar" & cnameB == "MANATI SUGAR CO") ///
	| (cnameA == "MANATI SUGAR CO" & cnameB == "Cuba Cane Sugar")
replace vertical = 1 if ///
	(cnameA == "Cuba Cane Sugar" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Cuba Cane Sugar")
replace horizontal = 1 if ///
	(cnameA == "Cuba Cane Sugar" & cnameB == "South Porto Rico Sugar Company") ///
	| (cnameA == "South Porto Rico Sugar Company" & cnameB == "Cuba Cane Sugar")
	
replace horizontal = 1 if ///
	(cnameA == "Cuban-American Sugar Co." & cnameB == "GUANTANAMO SUGAR CO") ///
	| (cnameA == "GUANTANAMO SUGAR CO" & cnameB == "Cuban-American Sugar Co.")
	
replace horizontal = 1 if ///
	(cnameA == "DAVISON CHEM CO" & cnameB == "MANATI SUGAR CO") ///
	| (cnameA == "MANATI SUGAR CO" & cnameB == "DAVISON CHEM CO")
	
replace vertical = 1 if ///
	(cnameA == "EMERSON BRANTINGHAM CORP" & cnameB == "OTIS STL CO") ///
	| (cnameA == "OTIS STL CO" & cnameB == "EMERSON BRANTINGHAM CORP")
replace horizontal = 1 if ///
	(cnameA == "EMERSON BRANTINGHAM CORP" & cnameB == "Willys Overland") ///
	| (cnameA == "Willys Overland" & cnameB == "EMERSON BRANTINGHAM CORP")
replace vertical = 1 if ///
	(cnameA == "EMERSON BRANTINGHAM CORP" & cnameB == "Worthington Pump and Machinery") ///
	| (cnameA == "Worthington Pump and Machinery" & cnameB == "EMERSON BRANTINGHAM CORP")
	
replace vertical = 1 if ///
	(cnameA == "ENDICOTT JOHNSON CORP" & cnameB == "Kress") ///
	| (cnameA == "Kress" & cnameB == "ENDICOTT JOHNSON CORP")
replace horizontal = 1 if ///
	(cnameA == "ENDICOTT JOHNSON CORP" & cnameB == "PHILLIPS JONES CORP") ///
	| (cnameA == "PHILLIPS JONES CORP" & cnameB == "ENDICOTT JOHNSON CORP")
	
replace vertical = 1 if ///
	(cnameA == "FREEPORT TEX CO" & cnameB == "Pacific Mail Steamship Co.") ///
	| (cnameA == "Pacific Mail Steamship Co." & cnameB == "FREEPORT TEX CO")
	
replace vertical = 1 if ///
	(cnameA == "Fisher Body" & cnameB == "General Motors Co.") ///
	| (cnameA == "General Motors Co." & cnameB == "Fisher Body")
	
replace vertical = 1 if ///
	(cnameA == "GENERAL ASPHALT CO" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "GENERAL ASPHALT CO")
	
replace vertical = 1 if ///
	(cnameA == "Gaston Williams and Wigmore" & cnameB == "INDIAN REFNG CO") ///
	| (cnameA == "INDIAN REFNG CO" & cnameB == "Gaston Williams and Wigmore")
replace horizontal = 1 if ///
	(cnameA == "Gaston Williams and Wigmore" & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "Gaston Williams and Wigmore")
replace vertical = 1 if ///
	(cnameA == "Gaston Williams and Wigmore" & cnameB == "UNION OIL CO DEL") ///
	| (cnameA == "UNION OIL CO DEL" & cnameB == "Gaston Williams and Wigmore")
	
replace horizontal = 1 if ///
	(cnameA == "General Chemical Co." & cnameB == "NATIONAL ANILINE & CHEMICAL CO") ///
	| (cnameA == "NATIONAL ANILINE & CHEMICAL CO" & cnameB == "General Chemical Co.")
	
replace vertical = 1 if ///
	(cnameA == "Goodrich (The B.F.) Co." & cnameB == "Studebaker Corp") ///
	| (cnameA == "Studebaker Corp" & cnameB == "Goodrich (The B.F.) Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Miami Copper Company") ///
	| (cnameA == "Miami Copper Company" & cnameB == "Granby Consolidated Smelting and Power Company")
replace vertical = 1 if ///
	(cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Miami Copper Company") ///
	| (cnameA == "Miami Copper Company" & cnameB == "Granby Consolidated Smelting and Power Company")
replace horizontal = 1 if ///
	(cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "Granby Consolidated Smelting and Power Company")
replace horizontal = 1 if ///
	(cnameA == "Granby Consolidated Smelting and Power Company" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Granby Consolidated Smelting and Power Company")
	
replace horizontal = 1 if ///
	(cnameA == "Greene Cananea Copper" & cnameB == "Inspiration Consolidated Copper Company") ///
	| (cnameA == "Inspiration Consolidated Copper Company" & cnameB == "Greene Cananea Copper")
	
replace vertical = 1 if ///
	(cnameA == "HASKELL & BARKER CAR CO" & cnameB == "Midvale Steel and Ordnance") ///
	| (cnameA == "Midvale Steel and Ordnance" & cnameB == "HASKELL & BARKER CAR CO")
	
replace vertical = 1 if ///
	(cnameA == "HOUSTON OIL CO TEX" & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "HOUSTON OIL CO TEX")
	
replace vertical = 1 if ///
	(cnameA == "INDIAN REFNG CO" & cnameB == "International Mercantile Marine") ///
	| (cnameA == "International Mercantile Marine" & cnameB == "INDIAN REFNG CO")
replace horizontal = 1 if ///
	(cnameA == "INDIAN REFNG CO" & cnameB == "UNION OIL CO DEL") ///
	| (cnameA == "UNION OIL CO DEL" & cnameB == "INDIAN REFNG CO")
	
replace vertical = 1 if ///
	(cnameA == "INTERNATIONAL MOTOR TRUCK" & cnameB == "Midvale Steel and Ordnance") ///
	| (cnameA == "Midvale Steel and Ordnance" & cnameB == "INTERNATIONAL MOTOR TRUCK")
replace vertical = 1 if ///
	(cnameA == "INTERNATIONAL MOTOR TRUCK" & cnameB == "Nova Scotia Steel and Coal") ///
	| (cnameA == "Nova Scotia Steel and Coal" & cnameB == "INTERNATIONAL MOTOR TRUCK")
	
replace horizontal = 1 if ///
	(cnameA == "INTERNATIONAL NICKEL CO CDA LTD" & cnameB == "Inspiration Consolidated Copper Company") ///
	| (cnameA == "Inspiration Consolidated Copper Company" & cnameB == "INTERNATIONAL NICKEL CO CDA LTD")
replace horizontal = 1 if ///
	(cnameA == "INTERNATIONAL NICKEL CO CDA LTD" & cnameB == "KENNECOTT COPPER CORP") ///
	| (cnameA == "KENNECOTT COPPER CORP" & cnameB == "INTERNATIONAL NICKEL CO CDA LTD")
replace horizontal = 1 if ///
	(cnameA == "INTERNATIONAL NICKEL CO CDA LTD" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "INTERNATIONAL NICKEL CO CDA LTD")
replace vertical = 1 if ///
	(cnameA == "INTERNATIONAL NICKEL CO CDA LTD" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "INTERNATIONAL NICKEL CO CDA LTD")
	
replace horizontal = 1 if ///
	(cnameA == "ISLAND CREEK COAL CO" & cnameB == "US Smelting Refining and Mining Co") ///
	| (cnameA == "US Smelting Refining and Mining Co" & cnameB == "ISLAND CREEK COAL CO")
	
replace vertical = 1 if ///
	(cnameA == "Ingersoll-Rand Company" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "Ingersoll-Rand Company")
	
replace horizontal = 1 if ///
	(cnameA == "Inspiration Consolidated Copper Company" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "Inspiration Consolidated Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Inspiration Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Inspiration Consolidated Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "International Agricultural Corporation" & cnameB == "NATIONAL ACME CO") ///
	| (cnameA == "NATIONAL ACME CO" & cnameB == "International Agricultural Corporation")
	
replace vertical = 1 if ///
	(cnameA == "International Harvester Corp" & cnameB == "Lackawanna Steel") ///
	| (cnameA == "Lackawanna Steel" & cnameB == "International Harvester Corp")
	
replace vertical = 1 if ///
	(cnameA == "International Mercantile Marine" & cnameB == "New York Dock") ///
	| (cnameA == "New York Dock" & cnameB == "International Mercantile Marine")
replace horizontal = 1 if ///
	(cnameA == "International Mercantile Marine" & cnameB == "Pacific Mail Steamship Co.") ///
	| (cnameA == "Pacific Mail Steamship Co." & cnameB == "International Mercantile Marine")
replace vertical = 1 if ///
	(cnameA == "International Mercantile Marine" & cnameB == "UNION OIL CO DEL") ///
	| (cnameA == "UNION OIL CO DEL" & cnameB == "International Mercantile Marine")
replace vertical = 1 if ///
	(cnameA == "International Mercantile Marine" & cnameB == "WHITE OIL CORP") ///
	| (cnameA == "WHITE OIL CORP" & cnameB == "International Mercantile Marine")
	
replace vertical = 1 if ///
	(cnameA == "Jefferson and Clearfield Coal and Iron Company" & cnameB == "WICKWIRE SPENCER STL CO") ///
	| (cnameA == "WICKWIRE SPENCER STL CO" & cnameB == "Jefferson and Clearfield Coal and Iron Company")
	
replace vertical = 1 if ///
	(cnameA == "Jewel Tea" & cnameB == "Kress") ///
	| (cnameA == "Kress" & cnameB == "Jewel Tea")
replace vertical = 1 if ///
	(cnameA == "Jewel Tea" & cnameB == "STERN BROS") ///
	| (cnameA == "STERN BROS" & cnameB == "Jewel Tea")
replace vertical = 1 if ///
	(cnameA == "Jewel Tea" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "Jewel Tea")
	
replace vertical = 1 if ///
	(cnameA == "KELSEY WHEEL CO" & cnameB == "Studebaker Corp") ///
	| (cnameA == "Studebaker Corp" & cnameB == "KELSEY WHEEL CO")
	
replace horizontal = 1 if ///
	(cnameA == "KENNECOTT COPPER CORP" & cnameB == "Nevada Consolidated Copper Company") ///
	| (cnameA == "Nevada Consolidated Copper Company" & cnameB == "KENNECOTT COPPER CORP")
replace horizontal = 1 if ///
	(cnameA == "KENNECOTT COPPER CORP" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "KENNECOTT COPPER CORP")
replace horizontal = 1 if ///
	(cnameA == "KENNECOTT COPPER CORP" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "KENNECOTT COPPER CORP")
	
replace horizontal = 1 if ///
	(cnameA == "Kayser & Co (Julius)" & cnameB == "MALLINSON & CO INC") ///
	| (cnameA == "MALLINSON & CO INC" & cnameB == "Kayser & Co (Julius)")
	
replace vertical = 1 if ///
	(cnameA == "Kress" & cnameB == "PHILLIPS JONES CORP") ///
	| (cnameA == "PHILLIPS JONES CORP" & cnameB == "Kress")
	
replace vertical = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "Pressed Steel Car") ///
	| (cnameA == "Pressed Steel Car" & cnameB == "Lackawanna Steel")
replace vertical = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "Savage Arms") ///
	| (cnameA == "Savage Arms" & cnameB == "Lackawanna Steel")
replace horizontal = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "Superior Steel") ///
	| (cnameA == "Superior Steel" & cnameB == "Lackawanna Steel")
replace vertical = 1 if ///
	(cnameA == "Lackawanna Steel" & cnameB == "The Pullman Co") ///
	| (cnameA == "The Pullman Co" & cnameB == "Lackawanna Steel")
	
replace vertical = 1 if ///
	(cnameA == "Lee Rubber and Tire" & cnameB == "MARTIN PARRY CORP") ///
	| (cnameA == "MARTIN PARRY CORP" & cnameB == "Lee Rubber and Tire")
replace vertical = 1 if ///
	(cnameA == "Lee Rubber and Tire" & cnameB == "OHIO BODY & BLOWER CO") ///
	| (cnameA == "OHIO BODY & BLOWER CO" & cnameB == "Lee Rubber and Tire")
replace vertical = 1 if ///
	(cnameA == "Lee Rubber and Tire" & cnameB == "PARISH & BINGHAM") ///
	| (cnameA == "PARISH & BINGHAM" & cnameB == "Lee Rubber and Tire")
	
replace horizontal = 1 if ///
	(cnameA == "MARTIN PARRY CORP" & cnameB == "Stutz Motor Car") ///
	| (cnameA == "Stutz Motor Car" & cnameB == "MARTIN PARRY CORP")
	
replace horizontal = 1 if ///
	(cnameA == "MULLINS BODY CORP" & cnameB == "OHIO BODY & BLOWER CO") ///
	| (cnameA == "OHIO BODY & BLOWER CO" & cnameB == "MULLINS BODY CORP")
replace vertical = 1 if ///
	(cnameA == "MULLINS BODY CORP" & cnameB == "PARISH & BINGHAM") ///
	| (cnameA == "PARISH & BINGHAM" & cnameB == "MULLINS BODY CORP")
replace vertical = 1 if ///
	(cnameA == "MULLINS BODY CORP" & cnameB == "Transue and Williams Steel Forging") ///
	| (cnameA == "Transue and Williams Steel Forging" & cnameB == "MULLINS BODY CORP")
replace vertical = 1 if ///
	(cnameA == "MULLINS BODY CORP" & cnameB == "United Alloy Steel") ///
	| (cnameA == "United Alloy Steel" & cnameB == "MULLINS BODY CORP")
	
replace vertical = 1 if ///
	(cnameA == "Maxwell Motors" & cnameB == "Sloss-Sheffield Steel & Iron") ///
	| (cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Maxwell Motors")
replace vertical = 1 if ///
	(cnameA == "Maxwell Motors" & cnameB == "US Rubber") ///
	| (cnameA == "US Rubber" & cnameB == "Maxwell Motors")
	
replace vertical = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "National Cloak and Suit Company") ///
	| (cnameA == "National Cloak and Suit Company" & cnameB == "May Department Stores")
replace horizontal = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "May Department Stores")
replace vertical = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "Underwood Typewriter") ///
	| (cnameA == "Underwood Typewriter" & cnameB == "May Department Stores")
replace vertical = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "United Cigar Manufacturers") ///
	| (cnameA == "United Cigar Manufacturers" & cnameB == "May Department Stores")
replace horizontal = 1 if ///
	(cnameA == "May Department Stores" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "May Department Stores")
	
replace horizontal = 1 if ///
	(cnameA == "Mexican Petroleum" & cnameB == "Pan American Petroleum and Transport") ///
	| (cnameA == "Pan American Petroleum and Transport" & cnameB == "Mexican Petroleum")
	
replace horizontal = 1 if ///
	(cnameA == "Miami Copper Company" & cnameB == "Tennessee Copper Company") ///
	| (cnameA == "Tennessee Copper Company" & cnameB == "Miami Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "Midvale Steel and Ordnance" & cnameB == "NATIONAL ACME CO") ///
	| (cnameA == "NATIONAL ACME CO" & cnameB == "Midvale Steel and Ordnance")
replace vertical = 1 if ///
	(cnameA == "Midvale Steel and Ordnance" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "Midvale Steel and Ordnance")
replace vertical = 1 if ///
	(cnameA == "Midvale Steel and Ordnance" & cnameB == "Worthington Pump and Machinery") ///
	| (cnameA == "Worthington Pump and Machinery" & cnameB == "Midvale Steel and Ordnance")
	
replace horizontal = 1 if ///
	(cnameA == "Moline Plow" & cnameB == "Willys Overland") ///
	| (cnameA == "Willys Overland" & cnameB == "Moline Plow")
	
replace horizontal = 1 if ///
	(cnameA == "Montgomery Ward and Co" & cnameB == "UNITED RETAIL STORES") ///
	| (cnameA == "UNITED RETAIL STORES" & cnameB == "Montgomery Ward and Co")
	
replace vertical = 1 if ///
	(cnameA == "NATIONAL ACME CO" & cnameB == "Nova Scotia Steel and Coal") ///
	| (cnameA == "Nova Scotia Steel and Coal" & cnameB == "NATIONAL ACME CO")
	
replace vertical = 1 if ///
	(cnameA == "National Cloak and Suit Company" & cnameB == "STERN BROS") ///
	| (cnameA == "STERN BROS" & cnameB == "National Cloak and Suit Company")
replace vertical = 1 if ///
	(cnameA == "National Cloak and Suit Company" & cnameB == "Sears, Roebuck & Co") ///
	| (cnameA == "Sears, Roebuck & Co" & cnameB == "National Cloak and Suit Company")
replace vertical = 1 if ///
	(cnameA == "National Cloak and Suit Company" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "National Cloak and Suit Company")
	
replace horizontal = 1 if ///
	(cnameA == "National Conduit and Cable" & cnameB == "Pacific Coast Company") ///
	| (cnameA == "Pacific Coast Company" & cnameB == "National Conduit and Cable")
replace vertical = 1 if ///
	(cnameA == "National Conduit and Cable" & cnameB == "Sinclair Oil and Refining") ///
	| (cnameA == "Sinclair Oil and Refining" & cnameB == "National Conduit and Cable")
replace vertical = 1 if ///
	(cnameA == "National Conduit and Cable" & cnameB == "TRANSCONTINENTAL OIL CO") ///
	| (cnameA == "TRANSCONTINENTAL OIL CO" & cnameB == "National Conduit and Cable")
replace vertical = 1 if ///
	(cnameA == "National Conduit and Cable" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "National Conduit and Cable")
	
replace horizontal = 1 if ///
	(cnameA == "Nevada Consolidated Copper Company" & cnameB == "Ray Consolidated Copper Company") ///
	| (cnameA == "Ray Consolidated Copper Company" & cnameB == "Nevada Consolidated Copper Company")
replace horizontal = 1 if ///
	(cnameA == "Nevada Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Nevada Consolidated Copper Company")
	
replace vertical = 1 if ///
	(cnameA == "New York Air Brake" & cnameB == "REPLOGLE STL CO") ///
	| (cnameA == "REPLOGLE STL CO" & cnameB == "New York Air Brake")
	
replace vertical = 1 if ///
	(cnameA == "New York Dock" & cnameB == "Wells Fargo and Co") ///
	| (cnameA == "Wells Fargo and Co" & cnameB == "New York Dock")
	
replace vertical = 1 if ///
	(cnameA == "OHIO BODY & BLOWER CO" & cnameB == "PARISH & BINGHAM") ///
	| (cnameA == "PARISH & BINGHAM" & cnameB == "OHIO BODY & BLOWER CO")
replace vertical = 1 if ///
	(cnameA == "OHIO BODY & BLOWER CO" & cnameB == "Transue and Williams Steel Forging") ///
	| (cnameA == "Transue and Williams Steel Forging" & cnameB == "OHIO BODY & BLOWER CO")
replace vertical = 1 if ///
	(cnameA == "OHIO BODY & BLOWER CO" & cnameB == "United Alloy Steel") ///
	| (cnameA == "United Alloy Steel" & cnameB == "OHIO BODY & BLOWER CO")
	
replace vertical = 1 if ///
	(cnameA == "OTIS STL CO" & cnameB == "Pettibone-Mulliken") ///
	| (cnameA == "Pettibone-Mulliken" & cnameB == "OTIS STL CO")
replace vertical = 1 if ///
	(cnameA == "OTIS STL CO" & cnameB == "REMINGTON TYPEWRITER CO") ///
	| (cnameA == "REMINGTON TYPEWRITER CO" & cnameB == "OTIS STL CO")
replace vertical = 1 if ///
	(cnameA == "OTIS STL CO" & cnameB == "VANADIUM CORP AMER") ///
	| (cnameA == "VANADIUM CORP AMER" & cnameB == "OTIS STL CO")
replace vertical = 1 if ///
	(cnameA == "OTIS STL CO" & cnameB == "White Motor") ///
	| (cnameA == "White Motor" & cnameB == "OTIS STL CO")
replace vertical = 1 if ///
	(cnameA == "OTIS STL CO" & cnameB == "Willys Overland") ///
	| (cnameA == "Willys Overland" & cnameB == "OTIS STL CO")
replace vertical = 1 if ///
	(cnameA == "OTIS STL CO" & cnameB == "Worthington Pump and Machinery") ///
	| (cnameA == "Worthington Pump and Machinery" & cnameB == "OTIS STL CO")
	
replace vertical = 1 if ///
	(cnameA == "PARISH & BINGHAM" & cnameB == "Transue and Williams Steel Forging") ///
	| (cnameA == "Transue and Williams Steel Forging" & cnameB == "PARISH & BINGHAM")
replace vertical = 1 if ///
	(cnameA == "PARISH & BINGHAM" & cnameB == "United Alloy Steel") ///
	| (cnameA == "United Alloy Steel" & cnameB == "PARISH & BINGHAM")
	
replace vertical = 1 if ///
	(cnameA == "PUNTA ALEGRE SUGAR CO" & cnameB == "UNITED STATES FOOD PRODUCTS CORP") ///
	| (cnameA == "UNITED STATES FOOD PRODUCTS CORP" & cnameB == "PUNTA ALEGRE SUGAR CO")
replace vertical = 1 if ///
	(cnameA == "PUNTA ALEGRE SUGAR CO" & cnameB == "United Drug") ///
	| (cnameA == "United Drug" & cnameB == "PUNTA ALEGRE SUGAR CO")
	
replace vertical = 1 if ///
	(cnameA == "Pacific Coast Company" & cnameB == "Sinclair Oil and Refining") ///
	| (cnameA == "Sinclair Oil and Refining" & cnameB == "Pacific Coast Company")
	
replace vertical = 1 if ///
	(cnameA == "Pacific Mail Steamship Co." & cnameB == "WHITE OIL CORP") ///
	| (cnameA == "WHITE OIL CORP" & cnameB == "Pacific Mail Steamship Co.")
replace vertical = 1 if ///
	(cnameA == "Pacific Mail Steamship Co." & cnameB == "Wells Fargo and Co") ///
	| (cnameA == "Wells Fargo and Co" & cnameB == "Pacific Mail Steamship Co.")
	
replace horizontal = 1 if ///
	(cnameA == "Pan American Petroleum and Transport" & cnameB == "Sinclair Oil and Refining") ///
	| (cnameA == "Sinclair Oil and Refining" & cnameB == "Pan American Petroleum and Transport")
	
replace vertical = 1 if ///
	(cnameA == "Pettibone-Mulliken" & cnameB == "Worthington Pump and Machinery") ///
	| (cnameA == "Worthington Pump and Machinery" & cnameB == "Pettibone-Mulliken")
	
replace vertical = 1 if ///
	(cnameA == "Pierce Arrow Motor Car" & cnameB == "REPLOGLE STL CO") ///
	| (cnameA == "REPLOGLE STL CO" & cnameB == "Pierce Arrow Motor Car")
	
replace vertical = 1 if ///
	(cnameA == "Pittsburgh Coal Company" & cnameB == "Pressed Steel Car") ///
	| (cnameA == "Pressed Steel Car" & cnameB == "Pittsburgh Coal Company")
	
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "Westinghouse Air Brake") ///
	| (cnameA == "Westinghouse Air Brake" & cnameB == "Pressed Steel Car")
replace vertical = 1 if ///
	(cnameA == "Pressed Steel Car" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "Pressed Steel Car")
	
replace vertical = 1 if ///
	(cnameA == "REPLOGLE STL CO" & cnameB == "VANADIUM CORP AMER") ///
	| (cnameA == "VANADIUM CORP AMER" & cnameB == "REPLOGLE STL CO")
	
replace horizontal = 1 if ///
	(cnameA == "REPUBLIC MOTOR TRUCK" & cnameB == "Willys Overland") ///
	| (cnameA == "Willys Overland" & cnameB == "REPUBLIC MOTOR TRUCK")
	
replace horizontal = 1 if ///
	(cnameA == "Ray Consolidated Copper Company" & cnameB == "Utah Copper Company") ///
	| (cnameA == "Utah Copper Company" & cnameB == "Ray Consolidated Copper Company")
	
replace horizontal = 1 if ///
	(cnameA == "Royal Dutch Petroleum" & cnameB == "SHELL TRANS & TRADING LTD") ///
	| (cnameA == "SHELL TRANS & TRADING LTD" & cnameB == "Royal Dutch Petroleum")
replace vertical = 1 if ///
	(cnameA == "Royal Dutch Petroleum" & cnameB == "SHELL TRANS & TRADING LTD") ///
	| (cnameA == "SHELL TRANS & TRADING LTD" & cnameB == "Royal Dutch Petroleum")
	
replace vertical = 1 if ///
	(cnameA == "STERN BROS" & cnameB == "United Cigar Manufacturers") ///
	| (cnameA == "United Cigar Manufacturers" & cnameB == "STERN BROS")
	
replace vertical = 1 if ///
	(cnameA == "Sears, Roebuck & Co" & cnameB == "Underwood Typewriter") ///
	| (cnameA == "Underwood Typewriter" & cnameB == "Sears, Roebuck & Co")
replace vertical = 1 if ///
	(cnameA == "Sears, Roebuck & Co" & cnameB == "United Cigar Manufacturers") ///
	| (cnameA == "United Cigar Manufacturers" & cnameB == "Sears, Roebuck & Co")
	
replace vertical = 1 if ///
	(cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Studebaker Corp") ///
	| (cnameA == "Studebaker Corp" & cnameB == "Sloss-Sheffield Steel & Iron")
replace vertical = 1 if ///
	(cnameA == "Sloss-Sheffield Steel & Iron" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "Sloss-Sheffield Steel & Iron")
	
replace vertical = 1 if ///
	(cnameA == "The Pullman Co" & cnameB == "US Steel") ///
	| (cnameA == "US Steel" & cnameB == "The Pullman Co")
	
replace vertical = 1 if ///
	(cnameA == "Transue and Williams Steel Forging" & cnameB == "United Alloy Steel") ///
	| (cnameA == "United Alloy Steel" & cnameB == "Transue and Williams Steel Forging")
	
replace vertical = 1 if ///
	(cnameA == "Underwood Typewriter" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "Underwood Typewriter")
	
replace vertical = 1 if ///
	(cnameA == "United Cigar Manufacturers" & cnameB == "Woolworth (F W) Co") ///
	| (cnameA == "Woolworth (F W) Co" & cnameB == "United Cigar Manufacturers")
	
replace vertical = 1 if ///
	(cnameA == "United Drug" & cnameB == "VIVAUDOU V INC") ///
	| (cnameA == "VIVAUDOU V INC" & cnameB == "United Drug")
	
replace vertical = 1 if ///
	(cnameA == "VANADIUM CORP AMER" & cnameB == "White Motor") ///
	| (cnameA == "White Motor" & cnameB == "VANADIUM CORP AMER")
replace vertical = 1 if ///
	(cnameA == "VANADIUM CORP AMER" & cnameB == "Willys Overland") ///
	| (cnameA == "Willys Overland" & cnameB == "VANADIUM CORP AMER")
	
replace vertical = 1 if ///
	(cnameA == "Westinghouse Air Brake" & cnameB == "Westinghouse Electric and Manufacturing") ///
	| (cnameA == "Westinghouse Electric and Manufacturing" & cnameB == "Westinghouse Air Brake")
	
replace horizontal = 1 if ///
	(cnameA == "White Motor" & cnameB == "Willys Overland") ///
	| (cnameA == "Willys Overland" & cnameB == "White Motor")
	
replace vertical = 1 if ///
	(cnameA == "Willys Overland" & cnameB == "Worthington Pump and Machinery") ///
	| (cnameA == "Worthington Pump and Machinery" & cnameB == "Willys Overland")
	
replace no_relationship = 1 if interlock & vertical + horizontal == 0 & year_std == 1920
	
	
g byte v_possible = inlist(indB, "Chemicals", "Farming Machinery", ///
								"Food & Beverages", "Land/Real Estate") ///
	if indA == "Agriculture"
replace v_possible = inlist(indB, "Engines", "General Manufacturing", "Rubber", "Steel") ///
	if indA == "Automobiles"
replace v_possible = inlist(indB, "Agriculture", "Sugar", "Tobacco") ///
	if indA == "Chemicals"
replace v_possible = inlist(indB, "Leather", "Retail", "Textiles") ///
	if indA == "Consumer Goods"
replace v_possible = inlist(indB, "Automobiles", "Farming Machinery", ///
								"General Manufacturing", "Locomotives") ///
	if indA == "Engines"
replace v_possible = 0 if indA == "Entertainment"
replace v_possible = inlist(indB, "Locomotives", "Mining / Smelting & Refining", "Shipping") ///
	if indA == "Express"
replace v_possible = inlist(indB, "Agriculture", "Engines", "General Manufacturing", ///
								"Steel", "Sugar", "Tobacco") ///
	if indA == "Farming Machinery"
replace v_possible = inlist(indB, "Agriculture", "Retail", "Sugar") ///
	if indA == "Food & Beverages"
replace v_possible = inlist(indB, "Automobiles", "Engines", "Farming Machinery", ///
								"Locomotives", "Steel") ///
	if indA == "General Manufacturing"
replace v_possible = 0 if inlist(indA, "Holding", "Insurance")
replace v_possible = inlist(indB, "Agriculture") ///
	if indA == "Land/Real Estate"
replace v_possible = inlist(indB, "Consumer Goods", "Leather", "Retail", "Textiles") ///
	if indA == "Leather"
replace v_possible = inlist(indB, "Engines", "Express", "General Manufacturing", ///
								"Mining / Smelting & Refining", "Steel") ///
	if indA == "Locomotives"
replace v_possible = inlist(indB, "Express", "Locomotives", "Mining / Smelting & Refining", ///
								"Steel") ///
	if indA == "Mining / Smelting & Refining"
replace v_possible = 0 if inlist(indA, "Oil", "Paper", "Pharmaceuticals")
replace v_possible = inlist(indB, "Consumer Goods", "Food & Beverages", "Leather", ///
								"Textiles", "Tobacco", "Wholesale Dry Goods") ///
	if indA == "Retail"
replace v_possible = inlist(indB, "Automobiles") ///
	if indA == "Rubber"
replace v_possible = inlist(indB, "Express") ///
	if indA == "Shipping"
replace v_possible = inlist(indB, "Automobiles", "Farming Machinery", "General Manufacturing", ///
								"Locomotives", "Mining / Smelting & Refining") ///
	if indA == "Steel"
replace v_possible = inlist(indB, "Chemicals", "Farming Machinery") ///
	if indA == "Sugar"
replace v_possible = inlist(indB, "Consumer Goods", "Leather", "Retail") ///
	if indA == "Textiles"
replace v_possible = inlist(indB, "Chemicals", "Farming Machinery", "Retail") ///
	if indA == "Tobacco"
replace v_possible = inlist(indB, "Retail") ///
	if indA == "Wholesale Dry Goods"
replace v_possible = 0 if v_possible == .
	
gen same_ind = indA == indB
	
save "Thesis/Interlocks/interlocks_coded.dta", replace