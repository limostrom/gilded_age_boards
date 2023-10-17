/*
RR_banker_join_regs.do

*/


clear all
cap log close
pause on


cap cd "C:\Users\lmostrom\Documents\Gilded Age Boards - Scratch\"
cap cd "C:\Users\17036\Dropbox\Personal Document Backup\Gilded Age Boards - Scratch\"
cap cd "/Users/laurenmostrom/Dropbox/Personal Document Backup/Gilded Age Boards - Scratch/"
global repo "/Users/laurenmostrom/Documents/GitHub/gilded_age_boards"



*%%Prep Underwriter/CB Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use "Thesis/Merges/UW_1880-1920_top10.dta", clear
egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname bankname
tempfile top10uw
save `top10uw', replace

*%%Prep Standardized RR Names to Merge In %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import delimited "Data/RR_names_years_corrected.csv", clear varn(1)

tempfile stn_cnames
save `stn_cnames', replace


*%%Prep Assets Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use Data/assets, clear
	keep if sector == "RR"
	merge 1:1 cname year_std using `stn_cnames', keep(3) nogen
	tempfile assets
	save `assets', replace
	

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


use year_std cname fullname_m director using "Thesis/Merges/RR_boards_wtitles.dta", clear
	drop if cname == "KEOKUK AND DES MOINES RAILROAD" & year_std == 1890 // duplicate
	keep if director == 1
merge m:1 cname year_std using `stn_cnames', keep(3) nogen
	egen id = group(cname_stn)
	

merge m:1 fullname_m year_std using `top10uw', keep(1 3) keepus(bankname)
gen top10uw = _merge == 3

collapse (count) boardsize = _merge ///
		 (max) has_top10uw = top10uw (sum) n_top10uw = top10uw, by(id cname_stn year_std) 
		 

merge 1:1 cname_stn year_std using `assets', keep(1 3) nogen

gen ln_assets = ln(assets)

*%% Add Regions 

include "$repo/assign_regions.do"


gen north = region == "N"
gen west = region == "W"
encode region, gen(regioncode)

bys cname_stn: egen entry_yr = min(year_std)
gen entrant = entry_yr == year_std
gen hastop10_X_entrant = has_top10uw * entrant



*** Growth Regressions
xtset id year_std

gen f5_dln_assets = f5.ln_assets - ln_assets

est clear
#delimit ;

eststo m1, title("dln Assets (F5)"):
	reghdfe f5_dln_assets has_top10uw,
						a(year_std regioncode) vce(robust);
		estadd ysumm, mean;

eststo m2, title("dln Assets (F5)"):
	reghdfe f5_dln_assets has_top10uw entrant hastop10_X_entrant,
						a(year_std regioncode) vce(robust);
		estadd ysumm, mean;

eststo m3, title("dln Assets (F5)"):
	reghdfe f5_dln_assets has_top10uw entrant hastop10_X_entrant ln_assets,
						a(year_std regioncode) vce(robust);
		estadd ysumm, mean;
		

esttab m* using "Thesis/Interlocks/RR_growth_regs.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles scalars("ymean Mean(Dep. Var.)")
	addnotes("Robust SEs and Year and Region FEs");
#delimit cr


*** Banker Regressions

use "Data/RR_bankers_1890-1910.dta", clear

gen tobinsq = (marketcap + (totassets - comstock - surplus))/totassets
gen bvlev = totdebt/totassets
gen ln_assets = ln(totassets)
gen receivership10 = (receivership != .)
replace added_banker = (n_top10uw1910 > n_top10uw1890)

est clear
#delimit ;

eststo m1, title("Had Banker 1890"):
	reghdfe has_top10uw1890 ln_assets bvlev tobinsq receivership10, a(cohort) vce(robust);
		estadd ysumm, mean;

eststo m2, title("Had Banker 1910"):
	reghdfe has_top10uw1910 ln_assets bvlev tobinsq receivership10, a(cohort) vce(robust);
		estadd ysumm, mean;

eststo m3, title("Added Banker (All RRs)"):
	reghdfe added_banker ln_assets bvlev tobinsq receivership10, a(cohort) vce(robust);
		estadd ysumm, mean;

eststo m4, title("Added Banker (No Banker 1890)"):
	reghdfe added_banker ln_assets bvlev tobinsq receivership10
				if has_top10uw1890 == 0, a(cohort) vce(robust);
		estadd ysumm, mean;
		

esttab m* using "Thesis/Interlocks/RR_banker_regs.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles
	scalars("N Obs. r2 R-Sq. ymean Mean(Dep. Var.)")
	addnotes("Robust SEs and Cohort FEs");
#delimit cr

