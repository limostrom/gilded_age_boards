/*
interlock_regs.do


*/
clear all
cap log close
pause on

cap cd "C:\Users\lmostrom\Documents\PersonalResearch\"

*%% Prep Number of Directors Variable %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

use fullname_m cname year_std director using "Thesis/Merges/Ind_boards_wtitles.dta", clear
append using "Thesis/Merges/Util_boards_final.dta", keep(fullname_m cname year_std director)
keep if director == 1 & fullname_m != ""

collapse (count) n_directors = director, by(cname year_std)
ren cname cnameA

tempfile nd
save `nd', replace

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

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

use "Thesis/Interlocks/interlocks_coded.dta", clear


keep cnameA cidA year_std
duplicates drop
ren cnameA cnameB
ren cidA cidB
tempfile self
save `self', replace
ren cnameB cnameA
ren cidB cidA

preserve
	isid cnameA year_std
	ren cnameA cname
	merge 1:1 cname year_std using "assets_ind.dta", keep(3) nogen
	collapse (p1) pctl1 = assets (p5) pctl5 = assets (p10) pctl10 = assets ///
			(p15) pctl15 = assets (p20) pctl20 = assets (p25) pctl25 = assets ///
			(p30) pctl30 = assets (p35) pctl35 = assets (p40) pctl40 = assets ///
			(p45) pctl45 = assets (p50) pctl50 = assets (p55) pctl55 = assets ///
			(p60) pctl60 = assets (p65) pctl65 = assets (p70) pctl70 = assets ///
			(p75) pctl75 = assets (p80) pctl80 = assets (p85) pctl85 = assets ///
			(p90) pctl90 = assets (p95) pctl95 = assets (p99) pctl99 = assets, by(year_std)
	keep if year_std >= 1910
	export delimited "Thesis/Interlocks/assets_summ.csv", replace
	keep if inlist(year_std, 1915, 1920)
	keep year_std pctl15 pctl25
	tempfile bounds
	save `bounds', replace
restore
preserve
	isid cnameA year_std
	ren cnameA cname
	merge 1:1 cname year_std using "assets_ind.dta", keep(3) nogen
	merge m:1 year_std using `bounds', nogen keep(3)
	keep if inrange(assets, pctl15, pctl25)
	keep cname year_std assets
	export delimited "Thesis/Interlocks/firms_assets_pct15-25.csv", replace
restore

joinby year_std using `self'

ren cnameA cname
merge m:1 cname year_std using "assets_ind.dta", keep(3) nogen
	ren assets assetsA
merge m:1 cname year_std using `industries', nogen keep(1 3) keepus(Industry Entrant)
	ren Industry indA
	ren Entrant entrantA
ren cname cnameA
ren cnameB cname
merge m:1 cname year_std using "assets_ind.dta", keep(3) nogen
	ren assets assetsB
merge m:1 cname year_std using `industries', nogen keep(1 3) keepus(Industry Entrant)
	ren Industry indB
	ren Entrant entrantB
ren cname cnameB

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

gen inc_inc = (entrantA + entrantB == 0)
gen inc_ent = (entrantA + entrantB == 1)
gen ent_ent = (entrantA + entrantB == 2)

egen entrantA_tagged = tag(cnameA entrantA year_std)
egen entrantB_tagged = tag(cnameB entrantB year_std)

bys indA year_std: egen indA_entrants = total(entrantA_tagged)
bys indB year_std: egen indB_entrants = total(entrantB_tagged)
gen sum_entrants = indA_entrants + indB_entrants
	lab var sum_entrants "Total Entrants in Both Industries"

merge 1:1 cnameA cnameB year_std using "Thesis/Interlocks/interlocks_coded.dta", ///
	keepus(interlock banker banker_indtop10 vertical horizontal no_relationship assetsA assetsB)
gen sum_assets = assetsA + assetsB
gen ln_sum_assets = ln(sum_assets)
	replace sum_assets = sum_assets/1000000
	lab var sum_assets "Total Assets of Both Firms ($ M)"

drop if interlock == 0 & cnameA == cnameB
assert inlist(interlock, ., 1)
replace interlock = 0 if interlock == .
	replace banker = 0 if interlock == 0
	replace banker_indtop10 = 0 if interlock == 0
recast byte interlock

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
	
egen pairid = group(cidA cidB)
xtset pairid year_std


foreach var of varlist inc_inc inc_ent ent_ent {
    gen `var'1915 = `var' if year_std == 1915
	replace `var'1915 = l5.`var' if year_std == 1920
	gen L5`var' = l5.`var'
}

bys pairid: egen maxyr = max(year_std)
bys pairid: egen minyr = min(year_std)
*keep if maxyr == 1920
*drop if minyr == 1920
drop maxyr

preserve
	drop if minyr == 1920
	egen firm_tag = tag(cidA year_std)
	gen int_same_ind = same_ind & interlock
	gen int_v_poss = v_possible & interlock
	egen interlock_tag = tag(interlock cidA year_std)
		replace interlock_tag = 0 if interlock == 0
	foreach var of varlist same_ind v_possible horizontal vertical no_relationship {
	    egen `var'_tag = tag(`var' interlock cidA year_std)
			replace `var'_tag = 0 if interlock == 0 | `var' == 0
	}
	replace assetsA = assetsA/1000000
	collapse (sum) firm_tag interlock interlock_tag banker entrants = entrantA_tag ///
			 (sum) same_ind_tag v_possible_tag horizontal vertical no_relationship ///
					horizontal_tag vertical_tag no_relationship_tag ///
			 (p25) assets_p25 = assetsA (median) assets_med = assetsA ///
			 (mean) assets_mean = assetsA (p75) assets_p75 = assetsA, ///
		by(indA year_std)
	gen sh_firms_wint = interlock_tag/firm_tag
	gen sh_firms_wsame = same_ind_tag/firm_tag
	gen sh_firms_wvposs = v_possible_tag/firm_tag
	gen sh_firms_wh = horizontal_tag/firm_tag
	gen sh_firms_wv = vertical_tag/firm_tag
	
	lab var year_std "Year"
	lab var indA "Industry"
	lab var firm_tag "No. of Firms"
	lab var entrants "No. of Entrants"
	lab var interlock "No. of Interlocks"
	lab var banker "No. of Banker Int's"
	lab var horizontal "No. of Horizontal Int's"
	lab var vertical "No. of Vertical Int's"
	lab var sh_firms_wint "% of Firms w/ an Interlock"
	lab var sh_firms_wsame "% of Firms w/ a Same Ind. Interlock"
	lab var sh_firms_wh "% of Firms w/ a Horizontal Interlock"
	lab var sh_firms_wvposs "% of Firms w/ a Poss. Vert. Interlock"
	lab var sh_firms_wv "% of Firms w/ a Vertical Interlock"
	lab var assets_p25 "Assets p25"
	lab var assets_med "Assets Median"
	lab var assets_mean "Assets Mean"
	lab var assets_p75 "Assets p75"
	export excel year_std indA firm_tag entrants interlock banker horizontal vertical ///
					sh_firms_wint sh_firms_wsame sh_firms_wh sh_firms_wvposs sh_firms_wv ///
					assets_p25 assets_med assets_mean assets_p75 ///
			using "Thesis/Interlocks/interlock_regs.xlsx", ///
						first(varl) sheet("Summary Stats - Industries", replace)
restore

*-------------------- Firm-Level Summary Stats ---------------------------------
#delimit ;
forval y = 1900(5)1920 {;
	preserve;
		keep if year_std == `y';
		
		replace same_ind = . if interlock == 0;
		replace v_possible = . if interlock == 0;
		br;
		pause;
		
		collapse (sum) interlock_tot = interlock banker_tot = banker
						banker_indtop10_tot = banker_indtop10 
						same_ind_tot = same_ind horizontal_tot = horizontal
						v_possible_tot = v_possible vertical_tot = vertical
						no_relationship_tot = no_relationship
				 (max) interlock_unique = interlock banker_unique = banker
						banker_indtop10_unique = banker_indtop10 
						same_ind_unique = same_ind horizontal_unique = horizontal
						v_possible_unique = v_possible vertical_unique = vertical
						no_relationship_unique = no_relationship assetsA
				, by(cnameA cnameB year_std);
				pause;
		collapse (sum) interlock_* banker_*	same_ind_* horizontal_*
						v_possible_* vertical_*	no_relationship_*
				 (max) assetsA, by(cnameA year_std);
				 
		merge 1:1 cnameA year_std using `nd', keep(3) nogen;
		replace assetsA = assetsA/1000000;
		lab var assetsA "Assets ($ Mil)";
		eststo firm_summ_`y':
			estpost summ interlock_* banker_tot banker_unique
							banker_indtop10_tot banker_indtop10_unique
							same_ind_* horizontal_* v_possible_* vertical_*
							no_relationship_* assetsA n_directors, d;
	restore;
};

lab var assetsA "Assets ($ Mil)";
esttab firm_summ_* using "Thesis/Interlocks/firm_summs.csv", replace
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1900" "1905" "1910" "1915" "1920") label;

#delimit cr
*-------------------------------------------------------------------------------

g byte overCA = (assetsA > 10000000/0.85 & assetsB > 10000000/0.85) if !inlist(., assetsA, assetsB)
lab var overCA "Both firms over Clayton Act Threshold (baseline spec: $10m / 0.85)"
gen assets_ratio = assetsA/assetsB
		drop if assets_ratio < 1
		drop if assetsA == . & assetsB != .
	lab var assets_ratio "Ratio of Assets (Large/Small)"
forval y = 1915(5)1920 {
    * Sum of Assets
	qui summ sum_assets if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_q1 = (sum_assets < `r(p25)') & overCA if year_std == `y'
		if `y' == 1920 replace overCA_q1 = (sum_assets < `r(p25)') & overCA if year_std == `y'
	qui summ sum_assets if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_q2 = (sum_assets >= `r(p25)') & (sum_assets < `r(p50)') & overCA ///
			if year_std == `y'
		if `y' == 1920 replace overCA_q2 = (sum_assets >= `r(p25)') & (sum_assets < `r(p50)') & overCA ///
			if year_std == `y'
	qui summ sum_assets if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_q3 = (sum_assets >= `r(p50)') & (sum_assets < `r(p75)') & overCA ///
			if year_std == `y'
		if `y' == 1920 replace overCA_q3 = (sum_assets >= `r(p50)') & (sum_assets < `r(p75)') & overCA ///
			if year_std == `y'
	qui summ sum_assets if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_q4 = (sum_assets >= `r(p75)') & overCA if year_std == `y'
		if `y' == 1920 replace overCA_q4 = (sum_assets >= `r(p75)') & overCA if year_std == `y'
		
	*Size Ratio of Large Firm to Small Firms
	qui summ assets_ratio if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_rat1 = (assets_ratio < `r(p25)') & overCA if year_std == `y'
		if `y' == 1920 replace overCA_rat1 = (assets_ratio < `r(p25)') & overCA if year_std == `y'
	qui summ assets_ratio if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_rat2 = (assets_ratio >= `r(p25)') & (assets_ratio < `r(p50)') & overCA ///
			if year_std == `y'
		if `y' == 1920 replace overCA_rat2 = (assets_ratio >= `r(p25)') & (assets_ratio < `r(p50)') & overCA ///
			if year_std == `y'
	qui summ assets_ratio if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_rat3 = (assets_ratio >= `r(p50)') & (assets_ratio < `r(p75)') & overCA ///
			if year_std == `y'
		if `y' == 1920 replace overCA_rat3 = (assets_ratio >= `r(p50)') & (assets_ratio < `r(p75)') & overCA ///
			if year_std == `y'
	qui summ assets_ratio if overCA & minyr < 1920, d
		if `y' == 1915 g byte overCA_rat4 = (assets_ratio >= `r(p75)') & overCA if year_std == `y'
		if `y' == 1920 replace overCA_rat4 = (assets_ratio >= `r(p75)') & overCA if year_std == `y'
}
foreach var of varlist overCA* {
	gen same_indX`var' = same_ind * `var'
	gen v_possX`var' = v_possible * `var'
}
estimates clear
/*
forval y = 1910(5)1920 {
	eststo r`y'a: reg interlock same_ind v_possible if year_std == `y', vce(r)
	eststo r`y'b: reg interlock same_ind v_possible over10m same_indXover10m v_possXover10m ///
				if year_std == `y', vce(r)
	eststo r`y'c: reg interlock same_ind v_possible over10m same_indXover10m v_possXover10m ///
				inc_inc inc_ent sum_entrants if year_std == `y', vce(r)
	eststo r`y'd: reg interlock same_ind v_possible over10m same_indXover10m v_possXover10m ///
				inc_inc inc_ent sum_entrants ln_sum_assets if year_std == `y', vce(r)
}

esttab r1910? r1915? r1920? using "Thesis/Interlocks/interlock_regs.csv", replace


forval y = 1910(5)1920 {
	eststo l`y'a: logit interlock same_ind v_possible if year_std == `y', vce(r)
	eststo l`y'b: logit interlock same_ind v_possible over10m same_indXover10m v_possXover10m ///
				if year_std == `y', vce(r)
	eststo l`y'c: logit interlock same_ind v_possible over10m same_indXover10m v_possXover10m ///
				 inc_inc inc_ent sum_entrants if year_std == `y', vce(r)
}

esttab l1910? l1915? l1920? using "Thesis/Interlocks/interlock_logits.csv", replace eform

*/

est clear


*keep if overCA != .
*keep if (year_std == 1920 & overCA == l5.overCA) ///
		| (year_std == 1915 & overCA == f5.overCA) ///
		| (year_std == 1910 & overCA == f10.overCA) ///
		| (year_std == 1905 & overCA == f15.overCA) ///
		| (year_std == 1900 & overCA == f20.overCA)
		

lab var same_ind "Same Industry"
lab var v_possible "Potential Vertical Relationship"
lab var horizontal "Horizontal Relationship"
lab var vertical "Vertical Relationship"
lab var no_relationship "No Relationship"
lab var banker "Interlocked by Banker"
lab var interlock "Interlocked"
lab var inc_inc1915 "Incumbent-Incumbent (in 1915)"
lab var inc_ent1915 "Incumbent-Entrant (in 1915)"
lab var ent_ent1915 "Entrant-Entrant (in 1915)"
lab var L5inc_inc "Incumbent-Incument (5 years ago)"
lab var L5inc_ent "Incumbent-Entrant (5 years ago)"
lab var L5ent_ent "Entrant-Entrant (5 years ago)"

#delimit ;
local summs_varlist "same_ind v_possible L5inc_inc L5inc_ent L5ent_ent sum_entrants sum_assets";
					
forval y = 1900(5)1920 {;
	eststo s_all_`y': estpost summ interlock banker banker_indtop10 `summs_varlist'
								if year_std == `y' & minyr < 1920, d;

	eststo s_notint_`y': estpost summ `summs_varlist'
								if year_std == `y' & !interlock & minyr < 1920, d;

	eststo s_int_`y': estpost summ banker banker_indtop10 horizontal vertical no_relationship `summs_varlist'
						if year_std == `y' & interlock & minyr < 1920, d;

	eststo s_intbnk_`y': estpost summ horizontal vertical no_relationship `summs_varlist'
						if year_std == `y' & interlock & banker & minyr < 1920, d;

	eststo s_intnotb_`y': estpost summ horizontal vertical no_relationship `summs_varlist'
						if year_std == `y' & interlock & !banker & minyr < 1920, d;
};

esttab s_all_* using "Thesis/Interlocks/interlock_summs.csv", replace
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1900" "1905" "1910" "1915" "1920") label note(" ")
	title("Full Sample - Pairs Existing in 1915 & 1920 (w/ constant OverCA)");
esttab s_notint_* using "Thesis/Interlocks/interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1900" "1905" "1910" "1915" "1920") label note(" ")
	title("Pairs Not Interlocked");
esttab s_int_* using "Thesis/Interlocks/interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1900" "1905" "1910" "1915" "1920") label note(" ")
	title("Pairs Interlocked");
esttab s_intbnk_* using "Thesis/Interlocks/interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1900" "1905" "1910" "1915" "1920") label note(" ")
	title("Banker Interlocks (Top 10 Underwriters)");
esttab s_intnotb_* using "Thesis/Interlocks/interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1900" "1905" "1910" "1915" "1920") label note(" ")
	title("Non-Banker Interlocks");
	

#delimit cr
	
g byte h_X_overCA = horizontal * overCA
g byte v_X_overCA = vertical * overCA

foreach y in 1900 1905 1910 1915 1920 {
g byte y`y' = year_std == `y'
g byte overCA_X_`y' = y`y' * overCA
g byte same_ind_X_`y' = same_ind * y`y'
	g byte h_X_`y' = horizontal * y`y'
g byte v_poss_X_`y' = y`y' * v_possible
	g byte v_X_`y' = y`y' * vertical
g byte overCA_X_`y'_X_same_ind = same_ind * overCA * y`y'
	g byte overCA_X_`y'_X_h = horizontal * overCA * y`y'
g byte overCA_X_`y'_X_vposs = v_possible * overCA * y`y'
	g byte overCA_X_`y'_X_v = vertical * overCA * y`y'
}

foreach q in overCA_q1 overCA_q2 overCA_q3 overCA_q4 ///
				overCA_rat1 overCA_rat2 overCA_rat3 overCA_rat4 {
	g byte `q'_X_1920 = y1920 * `q'
	g byte h_X_`q' = horizontal * `q'
	g byte v_X_`q' = vertical * `q'
	g byte `q'_X_1920_X_same_ind = same_ind * y1920 * `q'
	g byte `q'_X_1920_X_h = same_ind * y1920 * `q'
	g byte `q'_X_1920_X_vposs = same_ind * y1920 * `q'
	g byte `q'_X_1920_X_v = same_ind * y1920 * `q'
}

#delimit ;

est clear;

* Interlocks;
eststo r1a1, title("Interlocks (Same-Ind Only)"):
		reg interlock y1920 same_ind overCA
		same_indXoverCA same_ind_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind, vce(cluster pairid);
eststo ex1a, title("Interlocks (Same-Ind Only)"):
		reg interlock y19?? same_ind overCA
		same_indXoverCA same_ind_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind, vce(cluster pairid);
eststo r1b1, title("Interlocks (w/ V Possible)"):
		reg interlock y1920 same_ind v_possible overCA
		same_indXoverCA same_ind_X_1920 v_possXoverCA v_poss_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind overCA_X_1920_X_vposs, vce(cluster pairid);
eststo ex1b, title("Interlocks (w/ V Possible)"):
		reg interlock y19?? same_ind v_possible overCA
		same_indXoverCA same_ind_X_19?? v_possXoverCA v_poss_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind overCA_X_19??_X_vposs, vce(cluster pairid);
		
eststo r2a1, title("Interlocks (Same-Ind Only) w/ Controls"):
		reg interlock y1920 same_ind overCA
		same_indXoverCA same_ind_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind
		/*L5inc_inc L5inc_ent*/ ln_sum_assets sum_entrants, vce(cluster pairid);
eststo ex2a, title("Interlocks (Same-Ind Only) w/ Controls"):
		reg interlock y19?? same_ind overCA
		same_indXoverCA same_ind_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind
		ln_sum_assets sum_entrants, vce(cluster pairid);
eststo r2b1, title("Interlocks (w/ V Possible) w/ Controls"):
		reg interlock y1920 same_ind v_possible overCA
		same_indXoverCA same_ind_X_1920 v_possXoverCA v_poss_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind overCA_X_1920_X_vposs
		ln_sum_assets sum_entrants, vce(cluster pairid);
eststo ex2b, title("Interlocks (w/ V Possible) w/ Controls"):
		reg interlock y19?? same_ind v_possible overCA
		same_indXoverCA same_ind_X_19?? v_possXoverCA v_poss_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind overCA_X_19??_X_vposs
		ln_sum_assets sum_entrants, vce(cluster pairid);
		
* Bankers;
replace banker = 0 if banker == .;
eststo r3a, title("Banker (Same-Ind Only)"):
		reg banker y1920 same_ind overCA
		same_indXoverCA same_ind_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind, vce(cluster pairid);
eststo r3b, title("Banker (w/ V Possible)"):
		reg banker y1920 same_ind v_possible overCA
		same_indXoverCA same_ind_X_1920 v_possXoverCA v_poss_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind overCA_X_1920_X_vposs, vce(cluster pairid);
eststo r3c, title("Banker (Same-Ind Only) w/ Controls"):
		reg banker y1920 same_ind overCA
		same_indXoverCA same_ind_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind
		ln_sum_assets sum_entrants, vce(cluster pairid);
eststo r3d, title("Banker (w/ V Possible) w/ Controls"):
		reg banker y1920 same_ind v_possible overCA
		same_indXoverCA same_ind_X_1920 v_possXoverCA v_poss_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind overCA_X_1920_X_vposs
		ln_sum_assets sum_entrants, vce(cluster pairid);
		
*                  including all year dummies and interactions;
eststo ex3a, title("Banker (Same-Ind Only)"):
		reg banker y19?? same_ind overCA
		same_indXoverCA same_ind_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind, vce(cluster pairid);
eststo ex3b, title("Banker (w/ V Possible)"):
		reg banker y19?? same_ind v_possible overCA
		same_indXoverCA same_ind_X_19?? v_possXoverCA v_poss_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind overCA_X_19??_X_vposs, vce(cluster pairid);
eststo ex3c, title("Banker (Same-Ind Only) w/ Controls"):
		reg banker y19?? same_ind overCA
		same_indXoverCA same_ind_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind
		ln_sum_assets sum_entrants, vce(cluster pairid);
eststo ex3d, title("Banker (w/ V Possible) w/ Controls"):
		reg banker y19?? same_ind v_possible overCA
		same_indXoverCA same_ind_X_19?? v_possXoverCA v_poss_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind overCA_X_19??_X_vposs
		ln_sum_assets sum_entrants, vce(cluster pairid);
replace banker = . if interlock == 0;


* Bankers conditional on interlock;
eststo r4, title("Banker | Interlock"):
		reg banker y1920 same_ind v_possible overCA
		same_indXoverCA same_ind_X_1920 v_possXoverCA v_poss_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind overCA_X_1920_X_vposs if interlock, vce(cluster pairid);
eststo ex4, title("Banker | Interlock"):
		reg banker y19?? same_ind v_possible overCA
		same_indXoverCA same_ind_X_19?? v_possXoverCA v_poss_X_19?? overCA_X_1920
		overCA_X_19??_X_same_ind overCA_X_19??_X_vposs if interlock, vce(cluster pairid);
		
eststo r5, title("Banker | Interlock w/ Controls"):
		reg banker y1920 same_ind v_possible overCA
		same_indXoverCA same_ind_X_1920 v_possXoverCA v_poss_X_1920 overCA_X_1920
		overCA_X_1920_X_same_ind overCA_X_1920_X_vposs
		ln_sum_assets sum_entrants if interlock, vce(cluster pairid);
eststo ex5, title("Banker | Interlock w/ Controls"):
		reg banker y19?? same_ind v_possible overCA
		same_indXoverCA same_ind_X_19?? v_possXoverCA v_poss_X_19?? overCA_X_19??
		overCA_X_19??_X_same_ind overCA_X_19??_X_vposs
		ln_sum_assets sum_entrants if interlock, vce(cluster pairid);

esttab r* using "Thesis/Interlocks/interlock_regs.csv", replace mtitles
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
	order(y1920 overCA same_ind v_possible /*horizontal vertical no_relationship*/
			overCA_X_1920_X_same_ind overCA_X_1920_X_vposs);
			
esttab ex* using "Thesis/Interlocks/interlock_regs_expanded.csv", replace mtitles
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001);
est clear;

/*
xtset pairid year_std;

forval yr = 1905(5)1920 {;
	if `yr' == 1905 local abc "a";
	if `yr' == 1910 local abc "b";
	if `yr' == 1915 local abc "c";
	if `yr' == 1920 local abc "d";
	eststo s1`abc', title("Interlock       `yr'"):
			reg interlock same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr' /*& minyr < 1920*/, vce(cluster pairid);
				
	eststo s2`abc', title("Banker         (Orig. Top 10 Bankers)            `yr'"):
			reg banker same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr' /*& minyr < 1920*/, vce(cluster pairid);

	eststo s3`abc', title("Banker         (New Top 10 Ind Bankers)          `yr'"):
			reg banker_indtop10 same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr' /*& minyr < 1920*/, vce(cluster pairid);
	eststo s4`abc', title("Banker | Interlock         (Orig. Top 10 Bankers)            `yr'"):
			reg banker same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr' & interlock /*& minyr < 1920*/, vce(cluster pairid);

	eststo s5`abc', title("Banker | Interlock         (New Top 10 Ind Bankers)          `yr'"):
			reg banker_indtop10 same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr' & interlock /*& minyr < 1920*/, vce(cluster pairid);
};
esttab s1* s2* s3* s4* s5* using "Thesis/Interlocks/simplified_interlock_regs.csv", replace 
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles
	order(same_ind v_possible ln_sum_assets assets_ratio);
			
	*/			
#delimit cr
sdf
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xtset pairid year_std

ren overCA_X_*_X_same_ind overCA_X_same_ind_X_*

cap mkdir "Thesis/Interlocks/Interaction Term Plots/"
cd "Thesis/Interlocks/Interaction Term Plots/"

foreach yvar in "interlock" "banker" {
	local Yvar = proper("`yvar'") + "s"
	if "`yvar'" == "interlock" local stemlist "same_ind_X_ overCA_X_ overCA_X_same_ind_X_"
	if "`yvar'" == "banker" local stemlist "same_ind_X_ overCA_X_"

foreach wc in /*""*/ "_wCont" {
    if "`wc'" == "_wCont" {
	    local controls "ln_sum_assets sum_entrants"
		local subti2 "(with Controls)"
		
	}
	if "`wc'" == "" {
	    local controls ""
		local subti2 ""
	}
	* INTERLOCKS & BANKERS, UNCONDITIONAL, NO FE
	if "`yvar'" == "interlock" {
		#delimit ;
		reg `yvar' y19?? same_ind overCA
			same_indXoverCA same_ind_X_19?? overCA_X_19??
			overCA_X_same_ind_X_19?? `controls', vce(cluster pairid);
		
		mat M = r(table)["b", "same_ind_X_1900".."overCA_X_same_ind_X_1920"]
					\ r(table)["ll".."ul", "same_ind_X_1900".."overCA_X_same_ind_X_1920"];
		
		#delimit cr
	}
	if "`yvar'" == "banker" {
	    #delimit ;
		reg `yvar' y19?? same_ind overCA
			same_indXoverCA same_ind_X_19?? overCA_X_19?? `controls', vce(cluster pairid);
		
		mat M = r(table)["b", "same_ind_X_1900".."overCA_X_1920"]
					\ r(table)["ll".."ul", "same_ind_X_1900".."overCA_X_1920"];
		
		#delimit cr
	}
	preserve
		drop *
		svmat2 M, n(col) r(coeff)
		
		foreach var of local stemlist {
		    gen `var'1915 = 0
		}
		
		reshape long `stemlist', i(coeff) j(year_std)
		reshape wide `stemlist', i(year_std) j(coeff) string
		
		foreach stem of local stemlist {
		    #delimit ;
			tw (rcap `stem'll `stem'ul year_std, lc(gs7))
			   (scatter `stem'b year_std, msym("o") mc(black)),
			   legend(order(1 "95% Confidence Interval"))
			   yline(0, lc(gs12)) xti("")
			   yti("Coefficient Magnitude" "`stem'*")
			   title("`Yvar'") subti("`subti2'");
			graph export "Ind_`yvar'_`stem'coeffs`wc'.png", replace as(png) wid(1200) hei(700);
			  
			#delimit cr
		}
	restore
		
	* INTERLOCKS & BANKERS, UNCONDITIONAL, W/ FE
	if "`yvar'" == "interlock" {
		#delimit ;
		xtreg `yvar' y19??
			same_ind_X_19?? overCA_X_19??
			overCA_X_same_ind_X_19?? `controls', fe vce(cluster pairid);
		
		mat M = r(table)["b", "same_ind_X_1900".."overCA_X_same_ind_X_1920"]
					\ r(table)["ll".."ul", "same_ind_X_1900".."overCA_X_same_ind_X_1920"];
		
		#delimit cr
	}
	if "`yvar'" == "banker" {
		#delimit ;
		xtreg `yvar' y19??
			same_ind_X_19?? overCA_X_19?? `controls', fe vce(cluster pairid);
		
		mat M = (r(table)["b", "same_ind_X_1900".."overCA_X_1900"], 
						r(table)["b", "overCA_X_1910".."overCA_X_1920"])
					\ (r(table)["ll".."ul", "same_ind_X_1900".."overCA_X_1900"], 
						r(table)["ll".."ul", "overCA_X_1910".."overCA_X_1920"]);
		
		#delimit cr
	}
	
	preserve
		drop *
		svmat2 M, n(col) r(coeff)
		
		foreach var of local stemlist {
		    gen `var'1915 = 0
		}
		
		reshape long `stemlist', i(coeff) j(year_std)
		reshape wide `stemlist', i(year_std) j(coeff) string
		
		foreach stem of local stemlist {
		    #delimit ;
			tw (rcap `stem'll `stem'ul year_std, lc(gs7))
			   (scatter `stem'b year_std, msym("o") mc(black)),
			   legend(order(1 "95% Confidence Interval"))
			   yline(0, lc(gs12)) xti("")
			   yti("Coefficient Magnitude" "`stem'*")
			   title("`Yvar'") subti("with Fixed Effects & Controls")
			   note("Controls include ln_sum_assets and sum_entrants");
			graph export "Ind_`yvar'_`stem'coeffs`wc'_wFE.png", replace as(png) wid(1200) hei(700);
			  
			#delimit cr
		}
	restore
		
	* BANKERS, CONDITIONAL, NO FE
	if "`yvar'" == "banker" {
		#delimit ;
		reg `yvar' y19?? same_ind overCA
			same_indXoverCA same_ind_X_19?? overCA_X_19??
			overCA_X_same_ind_X_19?? `controls' if interlock, vce(cluster pairid);
		
		mat M = r(table)["b", "same_ind_X_1900".."overCA_X_1920"]
					\ r(table)["ll".."ul", "same_ind_X_1900".."overCA_X_1920"];
		
		#delimit cr
		preserve
			drop *
			svmat2 M, n(col) r(coeff)
			
			gen same_ind_X_1915 = 0
			gen overCA_X_1915 = 0
			
			reshape long same_ind_X_ overCA_X_, i(coeff) j(year_std)
			reshape wide same_ind_X_ overCA_X_, i(year_std) j(coeff) string
			
			foreach stem in "same_ind_X_" "overCA_X_" {
				#delimit ;
				tw (rcap `stem'll `stem'ul year_std, lc(gs7))
				   (scatter `stem'b year_std, msym("o") mc(black)),
				   legend(order(1 "95% Confidence Interval"))
				   yline(0, lc(gs12)) xti("")
				   yti("Coefficient Magnitude" "`stem'*")
				   title("Bankers") subti("Conditional on Interlock" "`subti2'");
				graph export "Ind_`yvar'_`stem'coeffs_conditional`wc'.png",
					replace as(png) wid(1200) hei(700);
				  
				#delimit cr
			}
		
		restore
	}
}
}






*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sdf

local summs_varlist "same_ind v_possible inc_inc inc_ent ent_ent sum_entrants sum_assets"

drop _merge code_pnum assets? entrant? ind?_entrants entrant?_tagged  cid? *_*1915 *X* y1920
reshape wide interlock banker `summs_varlist' vertical horizontal no_relationship ///
				ln_sum_assets overCA*, i(pairid cnameA cnameB) j(year_std)
forval y = 1915(5)1920 {
	lab var interlock`y' "Interlock Realized in `y'"
	lab var banker`y' "Interlock Created by a Top 10 Underwriter in `y'"
	lab var same_ind`y' "Both Firms in Same Industry in `y'"
	lab var v_possible`y' "Potential Vertical Relationship in `y'"
	lab var inc_inc`y' "Both Incumbents in `y'"
	lab var ent_ent`y' "Both Entrants in `y'"
	lab var inc_ent`y' "One Incumbent & One Entrant in `y'"
	lab var sum_entrants`y' "Total Entrants (in Both Industries, Combined) in `y'"
	lab var sum_assets`y' "Total Assets (Both Firms, Combined) in `y'"
	lab var vertical`y' "Vertical Interlock in `y'"
	lab var horizontal`y' "Horizontal Interlock in `y'"
	lab var no_relationship`y' "Unrelated Interlock in `y'"
}
gen overCA_constant = overCA1915 == overCA1920
preserve
	keep if overCA_constant
	local constant_N: dis _N
restore
preserve
	keep if !overCA_constant
	local changed_N: dis _N
restore
dis "`constant_N', `changed_N'"


#delimit cr
local ii = 1
local varlist1520 ""
mat A = (`changed_N', `constant_N', ., .)
mat colnames A = changed_mean constant_mean diff pval	
foreach var in interlock banker vertical horizontal `summs_varlist' {
	forval y = 1915(5)1920 {
	    ttest `var'`y', by(overCA_constant)
		mat A = (A \ `r(mu_1)', `r(mu_2)', `r(mu_2)' - `r(mu_1)', `r(p)')

		local varlist1520 "`varlist1520' `var'`y'"
	}
}
mat rownames A = N `varlist1520'

preserve
	drop *
	svmat2 A, names(col) rnames(var)
	order var
	export delimited "Thesis/Interlocks/ttests.csv", replace
restore




