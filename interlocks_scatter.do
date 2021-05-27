/*
interlocks_scatter.do


*/

clear all
cap log close
pause on

cap cd "C:/Users/lmostrom/Documents/PersonalResearch"

	cap mkdir "Thesis/Interlocks/Scatter Plots/"
	
*%% Prep Industry Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

forval y = 1895(5)1920 {
    import excel cname cid Entrant Industry using "industrials_interlocks_coded.xlsx", ///
		clear sheet("`y'") cellrange(A2)
	gen year_std = `y'
	tempfile ind`y'
	save `ind`y'', replace
}


use `ind1895', clear
forval y = 1900(5)1920 {
	append using `ind`y''
}


tempfile industries
save `industries', replace

*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cap cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Post-Thesis" // old computer
cd "C:\Users\lmostrom\Documents\PersonalResearch\"

use "Thesis/Merges/UW_1880-1920_top10.dta", clear

egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname bankname

tempfile temp_uw
save `temp_uw', replace

*%%Load Railroad or Industrials Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cap cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Post-Thesis" // old computer
cd "C:\Users\lmostrom\Documents\PersonalResearch\"

use year_std cname fullname_m director sector RRid newly_added ///
	using "Thesis/Merges/RR_boards_wtitles.dta", clear
rename RRid cid
append using "Thesis/Merges/Ind_boards_wtitles.dta", ///
	keep(year_std cname fullname_m director sector cid newly_added)
append using "Thesis/Merges/Util_boards_final.dta", ///
	keep(year_std cname fullname_m  director sector utilid)
qui summ cid
	local rmax = r(max)
	replace cid = utilid + `rmax' if sector == "Util" & cid == .
	drop utilid
replace newly_added = 1 if sector == "Util" & newly_added == .

assert fullname_m != ""
keep if director == 1
local id cid
*-------------------------------------------------------------------------------
*identify the people on multiple boards
bys year_std fullname_m sector: gen dup_person = cond(_N==1, 0, _n)
egen num_boards = max(dup_person), by(fullname_m year_std sector)

preserve // --------------------------------------------------------------------

merge m:1 fullname_m year_std using `temp_uw', keep(1 3) keepusing(bankname)

egen total_interlocks = total(num_boards), by(`id' year_std sector)
egen total_banker_interlocks = total(num_boards) if _merge == 3, by(`id' year_std sector)

bys `id' year_std sector: egen v = min(total_banker_interlocks)
replace total_banker_interlocks = v if total_banker_interlocks == .
replace total_banker_interlocks = 0 if total_banker_interlocks == .
drop v

egen tagged = tag(`id' year_std sector)
keep if tagged

gen sh_bnkr_ints_tot = total_banker_interlocks/total_interlocks

collapse (median) med_tot_interlocks = total_interlocks ///
		(p90) p90_tot_interlocks = total_interlocks ///
		(mean) mean_tot_interlocks = total_interlocks ///
		(mean) mean_tot_bnkr_interlocks = total_banker_interlocks ///
		(mean) mean_sh_bnkr_ints_tot = sh_bnkr_ints_tot ///
		(max) max_tot_interlocks = total_interlocks ///
		(p75) p75_tot_interlocks = total_interlocks, by(year_std sector)

tempfile temp_totints
save `temp_totints'

restore // ---------------------------------------------------------------------

expand (num_boards-1) if num_boards != 0, gen(copy)

keep fullname_m year_std `id' cname copy num_boards sector

sort fullname_m year_std copy `id'

rename `id' firmA
rename cname cnameA

gen firmB = .
bys year_std fullname_m firmA sector: gen combination = _n

summ num_boards
forval n = 2/`r(max)' {
	bys year_std fullname_m: replace firmB = firmA[_n + combination*(num_boards-1)] ///
		if num_boards == `n'
	bys year_std fullname_m: replace firmB = firmA[_n - (num_boards - combination)*(num_boards-1)] ///
		if num_boards == `n' & firmB == .
}

merge m:1 fullname_m year_std using `temp_uw', keep(1 3) keepusing(bankname)
gen banker = (_merge == 3)
drop _merge

pause

gen new = 0
bys firmA firmB (year_std sector): replace new = 1 if _n==1

egen unique_interlock_bytype = tag(firmA firmB year_std banker sector)
keep if unique_interlock_bytype

sort sector firmA firmB year_std
keep if sector == "Ind"
collapse (max) new, by(cnameA firmA firmB year_std)

ren firmA cid
merge m:1 cid year_std using `industries', keep(1 2 3) keepus(cname Industry)
ren cid firmA
ren Industry indA
ren firmB cid
merge m:1 cid year_std using `industries', gen(_mergeB) keep(1 2 3) keepus(Industry)
ren cid firmB
ren Industry indB

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

drop if firmA == . & firmB == .

replace cnameA = cname if _merge == 2
bys firmA: egen minyrA = min(year_std)
gen entrantA = year_std == minyrA
bys firmB: egen minyrB = min(year_std)
gen entrantB = year_std == minyrB
	
	drop if firmA == . | firmB == .
	
sort cnameA firmA firmB year_std
*br year_std cnameA firmA firmB entrant*
	
gen type = 1 if entrantA + entrantB == 0 // both incumbents
replace type = 2 if entrantA + entrantB == 2 // both entrants
replace type = 3 if entrantA + entrantB == 1 // one incumbent, one entrant
lab def inttypes 1 "Incumbent-Incumbent" 2 "Entrant-Entrant" 3 "Incumbent-Entrant"
lab val type inttypes

gen same_ind = (indA == indB)
gen same_ind_new = same_ind * new

collapse (sum) same_ind same_ind_new, by(cnameA firmA year_std indA entrantA type)
drop if indA == "Miscellaneous"
isid firmA type year_std

tempfile firmlist
save `firmlist', replace

gen same_ind_atleast1 = same_ind > 0

preserve // --- Number of Incumbents & Entrants --------------------------------

	use "assets_ind.dta", clear
	drop if sector == ""
	bys cname: egen minyr = min(year_std)
	gen entrants = year_std == minyr
		gen assets_ent = assets * entrant
		gen assets_inc = assets * (1-entrant)

	merge m:1 cname year_std using `industries', keep(3) keepus(Industry)
	ren Industry ind

	foreach X in "" {
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

	isid cname year_std
	collapse (count) n_firms = cid (sum) entrants assets_ent assets_inc, by(ind year_std)
	drop if ind == "Miscellaneous"
	gen incumbents = n_firms - entrants
	gen avgassets_inc = assets_inc/incumbents
	gen avgassets_ent = assets_ent/entrants
	replace assets_ent = assets_ent / 1000000
		lab var assets_ent "$ Millions"
	replace assets_inc = assets_inc / 1000000
		lab var assets_inc "$ Millions"
	replace avgassets_ent = assets_ent / 1000
		lab var avgassets_ent "$ Thousands"
	replace avgassets_inc = assets_inc / 1000
		lab var avgassets_inc "$ Thousands"

		forval y = 1910(5)1920 {
			if `y' == 1905 {
				*local addtext1 text(22 6 "Mining / Smelting & Refining")
				*local addtext2 text(150 185 "Shipping" 1700 50 "Steel")
			}
			if `y' == 1910 {
				local labs "0(5)25"
				*local addtext1 text(25 8 "Mining / Smelting & Refining")
				*local addtext2 text(1800 115 "Steel" 1000 175 "Mining / Smelting & Refining", size(medsmall))
			}
			if `y' == 1915 {
				local labs "0(5)35"
				*local addtext1 text(33 8 "Mining / Smelting & Refining")
				*local addtext2 text(2100 10 "Steel" 1500 110 "Mining / Smelting & Refining" 400 200 "Farming Machinery", size(medsmall))
			}
			if `y' == 1920 {
				local labs "0(5)30"
				*local addtext1 text(30 16 "Mining / Smelting & Refining")
				*local addtext2 text(3000 200 "Steel" 500 2800 "Oil" 1900 1700 "Mining / Smelting & Refining", size(medsmall))
			}
			
			tw (scatter incumbents entrants if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
				yti("Incumbent Firms in `y'") ylab(`labs') ///
				xti("Entrant Firms in `y'") xlab(`labs') ///
				`addtext1'
			graph export "Thesis/Interlocks/Scatter Plots/inc_vs_ent_firms_`y'.png", replace as(png)
			
			tw (scatter assets_inc assets_ent if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
				yti("Total Assets of Incumbent Firms in `y' ($ Mil.)") ///
				xti("Total Assets of Entrant Firms in `y' ($ Mil.)") ///
				`addtext2'
			graph export "Thesis/Interlocks/Scatter Plots/inc_vs_ent_assets_`y'.png", replace as(png)
			
			tw (scatter avgassets_inc avgassets_ent if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
				yti("Avg. Size of Incumbent Firms in `y' ($ Th., Assets)") ///
				xti("Avg. Size of Entrant Firms in `y' ($ Th., Assets)") ///
				`addtext2'
			graph export "Thesis/Interlocks/Scatter Plots/inc_vs_ent_avgassets_`y'.png", replace as(png)
		}
	reshape wide n_firms incumbents entrants assets_inc assets_ent ///
					avgassets_inc avgassets_ent, i(ind) j(year_std)
	ren ind indA
	tempfile firms_assets
	save `firms_assets', replace
		
restore // ---------------------------------------------------------------------
sdf
preserve // --- Within-Industry Interlocks, All Firms --------------------------
	egen tagged = tag(firmA year_std)
	gen tagged_ent = entrantA * tagged
	collapse (sum) same_ind same_ind_new n_firms = tagged entrants = tagged_ent ///
			 (max) same_ind_atleast1, by(indA year_std)

	
	ren same_ind ints
	ren same_ind_new ints_new
	gen sh_firms_int = same_ind_atleast1/n_firms
	drop same_ind*

	drop if indA == ""

	reshape wide ints sh_firms_int ints_new n_firms entrants, i(indA) j(year_std)
		
		export excel indA ints1895 sh*1895 ints1900 sh*1900 ints1905 sh*1905 ///
							ints1910 sh*1910 ints1915 sh*1915 ints1920 sh*1920 n_firms* ///
			using "industrials_interlocks_coded.xlsx", ///
					sh("Within-Ind Interlocks - raw", replace) first(var)
		
		export excel indA ints_new* using "industrials_interlocks_coded.xlsx", ///
					sh("Within-Ind New Ints - raw", replace) first(var)
	keep indA n_firms* entrants*
	tempfile firms
	save `firms', replace
restore // ---------------------------------------------------------------------

preserve // --- Within-Industry Interlocks, Incumbents/Entrants ----------------
	collapse (sum) same_ind* (count) n_firms = firmA, by(indA type year_std)

	ren same_ind ints
	ren same_ind_new ints_new
	gen sh_firms_int = same_ind_atleast1/n_firms
	drop same_ind*

	drop if indA == ""

	reshape wide ints sh_firms_int ints_new n_firms, i(indA type) j(year_std)
	
		export excel indA type ints1895 sh*1895 ints1900 sh*1900 ints1905 sh*1905 ///
							ints1910 sh*1910 ints1915 sh*1915 ints1920 sh*1920 n_firms* ///
			using "industrials_interlocks_coded.xlsx", ///
						sh("Within-Ind Inc vs Ent - raw", replace) first(var)
						
		export excel indA type ints_new* using "industrials_interlocks_coded.xlsx", ///
						sh("Within-Ind New Inc vs Ent - raw", replace) first(var)
	drop n_firms* sh_firms_int*					
	reshape wide ints*, i(indA) j(type)
	merge 1:1 indA using `firms_assets', nogen assert(3)
	
	drop ints_new????2 ints_new????3

	forval y = 1895(5)1920 {
	    gen ints`y'1_scaled = ints`y'1 / (incumbents`y' * (incumbents`y' - 1)) * 100
			lab var ints`y'1_scaled "% of Potential Inc-Inc Interlocks Realized in `y'"
		gen ints`y'2_scaled = ints`y'2 / (entrants`y' * (entrants`y' - 1)) * 100
			lab var ints`y'2_scaled "% of Potential Ent-Ent Interlocks Realized in `y'"
		gen ints`y'3_scaled = ints`y'3 / (incumbents`y' * entrants`y') * 100
			lab var ints`y'1_scaled "% of Potential Inc-Ent Interlocks Realized in `y'"
	}
	
	gen pctd_ints1_1920 = ints19201_scaled - ints19151_scaled
	gen pctd_ints1_1915 = ints19151_scaled - ints19101_scaled
	gen pctd_ints1_1910 = ints19101_scaled - ints19051_scaled
	
	forval y = 1910(5)1920 {
	    local y_5 = `y' - 5
		tw (scatter pctd_ints1_`y' entrants`y' ///
				if !inlist(indA, "Retail", "Rubber", "Shipping", "Tobacco", "Wholesale Dry Goods"), msym("oh")), ///
			yti("Change in % of Potential Incumbent-Incumbent" "Interlocks Realized*, `y_5'-`y'") ///
			xti("Number of Entrants in `y'") ///
			note("*Percentage point difference from `y_5' to `y' in I-I Interlocks/(Ni*(Ni-1))*100%")
		graph export "Thesis/Interlocks/Scatter Plots/inc_pctd_vs_n_entrants_`y'.png", replace as(png)
		
		tw (scatter pctd_ints1_`y' assets_ent`y' ///
				if !inlist(indA, "Retail", "Rubber", "Shipping", "Tobacco", "Wholesale Dry Goods"), msym("oh")), ///
			yti("Change in % of Potential Incumbent-Incumbent" "Interlocks Realized*, `y_5'-`y'") ///
			xti("Total Assets of Entrants in `y'") ///
			note("*Percentage point difference from `y_5' to `y' in I-I Interlocks/(Ni*(Ni-1))*100%")
		graph export "Thesis/Interlocks/Scatter Plots/inc_pctd_vs_assets_ent_`y'.png", replace as(png)
		
		tw (scatter ints`y'1_scaled assets_ent`y', msym("oh")), ///
			yti("% of Potential Incumbent-Incumbent" "Interlocks Realized (`y')") ///
			xti("Total Assets of Entrants in `y'") ///
			note("Scaled number of I-I Interlocks by (Ni*(Ni-1))*100%")
		graph export "Thesis/Interlocks/Scatter Plots/inc-inc_scaled_vs_assets_ent_`y'.png", replace as(png)
		
		tw (scatter ints`y'1_scaled entrants`y', msym("oh")), ///
			yti("% of Potential Incumbent-Incumbent" "Interlocks Realized (`y')") ///
			xti("Number of Entrants in `y'") ///
			note("Scaled number of I-I Interlocks by (Ni*(Ni-1))*100%")
		graph export "Thesis/Interlocks/Scatter Plots/inc-inc_scaled_vs_entrants_`y'.png", replace as(png)
	
		tw (scatter ints`y'1_scaled ints`y'3_scaled, msym("oh")), ///
			yti("% of Potential Incumbent-Incumbent" "Interlocks Realized (`y')") ///
			xti("% of Potential Entrant-Entrant" "Interlocks Realized (`y')") ///
			note("Scaled number of interlocks by N*(N-1)")
		graph export "Thesis/Interlocks/Scatter Plots/inc-inc_vs_ent-ent_scaled_`y'.png", replace as(png)
		
		tw (scatter ints`y'2_scaled ints`y'3_scaled, msym("oh")), ///
			yti("% of Potential Incumbent-Entrant" "Interlocks Realized (`y')") ///
			xti("% of Potential Entrant-Entrant" "Interlocks Realized (`y')") ///
			note("Scaled number of I-E interlocks by N*M" "Scaled number of E-E interlocks by N*(N-1)")
		graph export "Thesis/Interlocks/Scatter Plots/ent-ent_vs_inc-ent_scaled_`y'.png", replace as(png)
	}
	/*
	tw (scatter ints_new19201 ints19151 if indA != "Mining / Smelting & Refining", msym("oh")), ///
			yti("New Incumbent-Incumbent Interlocks in 1920") ///
			xti("Total Incumbent-Incumbent Interlocks in 1915")
		graph export "Thesis/Interlocks/Scatter Plots/inc-inc_1915_vs_New1920.png", replace as(png)
		
	tw (scatter ints_new19201 ints19201 if indA != "Mining / Smelting & Refining", msym("oh")), ///
			yti("New Incumbent-Incumbent Interlocks in 1920") ///
			xti("Total Incumbent-Incumbent Interlocks in 1920")
		graph export "Thesis/Interlocks/Scatter Plots/inc-inc_1920_Tot_vs_New.png", replace as(png)
		
	tw (scatter ints_new19201 n_firms1915 if indA != "Mining / Smelting & Refining", msym("oh")), ///
			yti("New Incumbent-Incumbent Interlocks in 1920") ///
			xti("Number of Firms in 1915")
		graph export "Thesis/Interlocks/Scatter Plots/inc-inc_1920_vs_firms1915.png", replace as(png)
		
	tw (scatter ints_new19201 n_firms1920 if indA != "Mining / Smelting & Refining", msym("oh")), ///
			yti("New Incumbent-Incumbent Interlocks in 1920") ///
			xti("Number of Firms in 1920")
		graph export "Thesis/Interlocks/Scatter Plots/inc-inc_1920_vs_firms1920.png", replace as(png)
		
	tw (scatter ints19203 n_firms1915 if indA != "Mining / Smelting & Refining", msym("oh")), ///
			yti("Incumbent-Entrant Interlocks in 1920") ///
			xti("Number of Firms in 1915")
		graph export "Thesis/Interlocks/Scatter Plots/inc-ent_1920_vs_firms1915.png", replace as(png)
		
	tw (scatter ints19202 n_firms1915 if indA != "Mining / Smelting & Refining", msym("oh")), ///
			yti("Entrant-Entrant Interlocks in 1920") ///
			xti("Number of Firms in 1915")
		graph export "Thesis/Interlocks/Scatter Plots/ent-ent_1920_vs_firms1920.png", replace as(png)
	*/
	
restore // ---------------------------------------------------------------------

do interlocks_code.do

keep if inrange(year_std, 1900, 1920)

gen bankerV = banker & vertical
gen bankerH = banker & horizontal
gen bankerNR = banker & no_relationship

collapse (sum) interlocks = interlock nV = vertical nH = horizontal nNR = no_relationship ///
		 (max) has_V = vertical has_H = horizontal has_NR = no_relationship ///
			   bankerV bankerH bankerNR assets = assetsA, ///
	by(year_std cnameA cidA entrantA indA)
		 
gen assets_ent = assets*entrantA
		 
collapse (count) n_firms = cidA ///
		 (sum) interlocks nV nH nNR has_V has_H has_NR bankerV bankerH bankerNR ///
		 entrants = entrantA assets_ent assets_ind = assets, ///
	by(year_std indA)

gen pct_wV = has_V/n_firms*100
gen pct_wH = has_H/n_firms*100
gen pct_wNR = has_NR/n_firms*100

gen pct_wbnkV = bankerV/n_firms*100
gen pct_wbnkH = bankerH/n_firms*100
gen pct_wbnkNR = bankerNR/n_firms*100

foreach var of varlist assets_* {
	replace `var' = `var'/1000000
	lab var `var' "In $ Millions"
}

gen assets_inc = assets_ind - assets_ent

gen avgassets_ent = assets_ent/entrants
gen avgassets_inc = assets_inc/(n_firms-entrants)

gen arat_ie = assets_inc/assets_ent
	lab var arat_ie "Ratio of Incumbents' Assets to Entrants' Assets)"
gen avgarat_ie = avgassets_inc/avgassets_ent
	lab var arat_ie "Ratio of Avg. Incumbent Size to Avg. Entrant Size)"
egen id_ind = group(ind)
xtset id_ind year_std
	
foreach bnk in "" "bnk" {
	if "`bnk'" == "bnk" local bnk_yti "From a Banker (Top 10)"
	if "`bnk'" == "" local bnk_yti ""
forval y = 1910(5)1920 {
	local y_5 = `y' - 5
	*Number of Entrant Firms
	tw (scatter pct_w`bnk'H entrants if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Horizontal* Interlock in `y'" "`bnk_yti'") ///
			xti("Number of Entrants in `y'") ///
			note("*'Horizontal' is narrowly defined within the same product space, not just the same industry")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'H_vs_NEntrants_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'V entrants if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Vertical Interlock in `y'" "`bnk_yti'") ///
			xti("Number of Entrants in `y'")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'V_vs_NEntrants_`y'.png", replace as(png)
	
	tw (scatter l5.pct_w`bnk'V entrants if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Vertical Interlock in `y_5'" "`bnk_yti'") ///
			xti("Number of Entrants in `y'")
	graph export "Thesis/Interlocks/Scatter Plots/L5pct`bnk'V_vs_NEntrants_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'NR entrants if year_std == `y', msym("oh")), ///
			yti("% of Firms with an Unrelated Interlock in `y'" "`bnk_yti'") ///
			xti("Number of Entrants in `y'")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'NR_vs_NEntrants_`y'.png", replace as(png)
	
	*Total Assets of Entrant Firms
	tw (scatter pct_w`bnk'H assets_ent if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Horizontal* Interlock in `y'" "`bnk_yti'") ///
			xti("Total Assets of Entrants in `y' ($ Mil.)") ///
			note("*'Horizontal' is narrowly defined within the same product space, not just the same industry")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'H_vs_AEntrants_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'V assets_ent if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Vertical Interlock in `y'" "`bnk_yti'") ///
			xti("Total Assets of Entrants in `y' ($ Mil.)")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'V_vs_AEntrants_`y'.png", replace as(png)
	
	tw (scatter l5.pct_w`bnk'V assets_ent if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Vertical Interlock in `y_5'" "`bnk_yti'") ///
			xti("Total Assets of Entrants in `y' ($ Mil.)")
	graph export "Thesis/Interlocks/Scatter Plots/L5pct`bnk'V_vs_AEntrants_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'NR assets_ent if year_std == `y', msym("oh")), ///
			yti("% of Firms with an Unrelated Interlock in `y'" "`bnk_yti'") ///
			xti("Total Assets of Entrants in `y' ($ Mil.)")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'NR_vs_AEntrants_`y'.png", replace as(png)
	
	*Avg. Assets of Entrant Firms
	tw (scatter pct_w`bnk'H avgassets_ent if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with a Horizontal* Interlock in `y'" "`bnk_yti'") ///
			xti("Avg. Assets of Entrants in `y' ($ Th.)") ///
			note("*'Horizontal' is narrowly defined within the same product space, not just the same industry")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'H_vs_avgAEntrants_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'V avgassets_ent if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with a Vertical Interlock in `y'" "`bnk_yti'") ///
			xti("Avg. Assets of Entrants in `y' ($ Th.)")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'V_vs_avgAEntrants_`y'.png", replace as(png)
	
	tw (scatter l5.pct_w`bnk'V avgassets_ent if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with a Vertical Interlock in `y_5'" "`bnk_yti'") ///
			xti("Avg. Assets of Entrants in `y' ($ Th.)")
	graph export "Thesis/Interlocks/Scatter Plots/L5pct`bnk'V_vs_avgAEntrants_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'NR avgassets_ent if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with an Unrelated Interlock in `y'" "`bnk_yti'") ///
			xti("Avg. Assets of Entrants in `y' ($ Th.)")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'NR_vs_avgAEntrants_`y'.png", replace as(png)
	
	*Ratio of Assets in Incumbent Firms / Assets in Entrant Firms
	tw (scatter pct_w`bnk'H arat_ie if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Horizontal* Interlock in `y'" "`bnk_yti'") ///
			xti("Ratio of Incumbents' to Entrants' Assets in `y'") ///
			note("*'Horizontal' is narrowly defined within the same product space, not just the same industry")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'H_vs_Arat_IE_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'V arat_ie if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Vertical Interlock in `y'" "`bnk_yti'") ///
			xti("Ratio of Incumbents' to Entrants' Assets in `y'")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'V_vs_Arat_IE_`y'.png", replace as(png)
	
	tw (scatter l5.pct_w`bnk'V arat_ie if year_std == `y', msym("oh")), ///
			yti("% of Firms with a Vertical Interlock in `y_5'" "`bnk_yti'") ///
			xti("Ratio of Incumbents' to Entrants' Assets in `y'")
	graph export "Thesis/Interlocks/Scatter Plots/L5pct`bnk'V_vs_Arat_IE_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'NR arat_ie if year_std == `y', msym("oh")), ///
			yti("% of Firms with an Unrelated Interlock in `y'" "`bnk_yti'") ///
			xti("Ratio of Incumbents' to Entrants' Assets in `y'")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'NR_vs_Arat_IE_`y'.png", replace as(png)
	
	*Ratio of Avg. Assets in Incumbent Firms / Avg. Assets in Entrant Firms
	tw (scatter pct_w`bnk'H avgarat_ie if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with a Horizontal* Interlock in `y'" "`bnk_yti'") ///
			xti("Ratio of Avg. Incumbent Size to Entrant Size in `y'") ///
			note("*'Horizontal' is narrowly defined within the same product space, not just the same industry")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'H_vs_avgArat_IE_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'V avgarat_ie if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with a Vertical Interlock in `y'" "`bnk_yti'") ///
			xti("Ratio of Avg. Incumbent Size to Entrant Size `y'")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'V_vs_avgArat_IE_`y'.png", replace as(png)
	
	tw (scatter l5.pct_w`bnk'V avgarat_ie if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with a Vertical Interlock in `y_5'" "`bnk_yti'") ///
			xti("Ratio of Avg. Incumbent Size to Entrant Size `y'")
	graph export "Thesis/Interlocks/Scatter Plots/L5pct`bnk'V_vs_avgArat_IE_`y'.png", replace as(png)
	
	tw (scatter pct_w`bnk'NR avgarat_ie if year_std == `y', msym("oh") /*mlabel(ind)*/), ///
			yti("% of Firms with an Unrelated Interlock in `y'" "`bnk_yti'") ///
			xti("Ratio of Avg. Incumbent Size to Entrant Size `y'")
	graph export "Thesis/Interlocks/Scatter Plots/pct`bnk'NR_vs_avgArat_IE_`y'.png", replace as(png)
}
}
	