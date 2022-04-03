/*
interlock_regs.do


*/
clear all
cap log close
pause on

cap cd "C:\Users\lmostrom\Documents\PersonalResearch\"
cap cd "C:/Users/17036/Dropbox/Personal Document Backup/Gilded Age Boards - Scratch"
global repo "C:/Users/17036/OneDrive/Documents/GitHub/gilded_age_boards"

use fullname_m cname year_std director using "Thesis/Merges/Ind_boards_wtitles.dta", clear
append using "Thesis/Merges/Util_boards_final.dta", keep(fullname_m cname year_std director)
keep if director == 1 & fullname_m != ""

collapse (count) n_directors = director, by(cname year_std)
ren cname cnameA

tempfile nd
save `nd', replace


*%% Prep Industry Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

forval y = 1895(5)1920 {
    import excel cname cid Entrant Industry using "Data/industrials_interlocks_coded.xlsx", ///
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
	merge 1:1 cname year_std using "Data/assets_ind.dta", keep(3) nogen
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
	merge 1:1 cname year_std using "Data/assets_ind.dta", keep(3) nogen
	merge m:1 year_std using `bounds', nogen keep(3)
	keep if inrange(assets, pctl15, pctl25)
	keep cname year_std assets
	export delimited "Thesis/Interlocks/firms_assets_pct15-25.csv", replace
restore

joinby year_std using `self'

ren cnameA cname
merge m:1 cname year_std using "Data/assets_ind.dta", keep(3) nogen
	ren assets assetsA
merge m:1 cname year_std using `industries', nogen keep(1 3) keepus(Industry Entrant)
	ren Industry indA
	ren Entrant entrantA
ren cname cnameA
ren cnameB cname
merge m:1 cname year_std using "Data/assets_ind.dta", keep(3) nogen
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
	keepus(interlock banker banker_indtop10 n_totints n_bnkints n_bnkints_indtop10 ///
			vertical horizontal no_relationship assetsA assetsB)
* --- V Possible & Same Ind ----------------------------------------------------
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
* ------------------------------------------------------------------------------
gen sum_assets = assetsA + assetsB
gen ln_sum_assets = ln(sum_assets)
	replace sum_assets = sum_assets/1000000
	lab var sum_assets "Total Assets of Both Firms ($ M)"
replace assetsA = assetsA/1000000
	lab var assetsA "Assets ($ Mil)"
replace assetsB = assetsB/1000000
	lab var assetsB "Assets ($ Mil)"

drop if interlock == 0 & cnameA == cnameB
assert inlist(interlock, ., 1)


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
	*drop if minyr == 1920
	egen firm_tag = tag(cidA year_std)
	gen int_same_ind = same_ind & interlock
	gen int_v_poss = v_possible & interlock
	egen interlock_tag = tag(interlock cidA year_std)
		replace interlock_tag = 0 if interlock == 0
	foreach var of varlist same_ind v_possible horizontal vertical no_relationship {
	    egen `var'_tag = tag(`var' interlock cidA year_std)
			replace `var'_tag = 0 if interlock == 0 | `var' == 0
	}
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
	lab var assets_p25 "Assets p25 ($ Mil)"
	lab var assets_med "Assets Median ($ Mil)"
	lab var assets_mean "Assets Mean ($ Mil)"
	lab var assets_p75 "Assets p75 ($ Mil)"
	export excel year_std indA firm_tag entrants interlock banker horizontal vertical ///
					sh_firms_wint sh_firms_wsame sh_firms_wh sh_firms_wvposs sh_firms_wv ///
					assets_p25 assets_med assets_mean assets_p75 ///
			using "Thesis/Interlocks/interlock_regs.xlsx", ///
						first(varl) sheet("Summary Stats - Industries", replace)
restore

*-------------------- Firm-Level Summary Stats ---------------------------------
gen unr_ind = same_ind == 0 & v_possible == 0

gen interlocks_unique = interlock
ren n_totints interlocks_tot
gen bnkints_unique = banker
ren n_bnkints bnkints_tot
gen bnkints_indtop10_unique = banker_indtop10
ren n_bnkints_indtop10 bnkints_indtop10_tot

gen vertical_tot = vertical * interlocks_tot
gen vertical_unique = vertical
gen horizontal_tot = horizontal * interlocks_tot
gen horizontal_unique = horizontal
gen no_relationship_tot = no_relationship * interlocks_tot
gen no_relationship_unique = no_relationship
gen v_possible_tot = v_possible * interlocks_tot
gen v_possible_unique = v_possible * interlock
gen v_possible_bnkr_tot = v_possible * bnkints_tot
gen v_possible_bnkr_unique = v_possible * banker
gen same_ind_tot = same_ind * interlocks_tot
gen same_ind_unique = same_ind * interlock
gen same_ind_bnkr_tot = same_ind * bnkints_tot
gen same_ind_bnkr_unique = same_ind * banker
gen unr_ind_tot = unr_ind * interlocks_tot
gen unr_ind_unique = unr_ind * interlock
		
#delimit ;
forval y = 1895(5)1920 {;
	preserve;
		keep if year_std == `y';
	
		*pause;
		#delimit ;
		collapse (sum) interlocks_* bnkints_* vertical_* horizontal_* no_relationship_*
						v_possible_* same_ind_* unr_ind_*
				 (max) assetsA, by(cnameA cnameB year_std);
				 
		collapse (sum) interlocks_* bnkints_* vertical_* horizontal_* no_relationship_*
						v_possible_* same_ind_* unr_ind_*
				 (max) assetsA, by(cnameA year_std);
				 
		merge 1:1 cnameA year_std using `nd', keep(3) nogen;
		eststo firm_summ_`y':
			estpost summ interlocks_unique interlocks_tot
							bnkints_unique bnkints_tot
							bnkints_indtop10_unique bnkints_indtop10_tot
							horizontal_unique horizontal_tot same_ind_unique same_ind_tot
							same_ind_bnkr_unique same_ind_bnkr_tot
							vertical_unique vertical_tot v_possible_unique v_possible_tot
							v_possible_bnkr_unique v_possible_bnkr_tot
							no_relationship_unique no_relationship_tot
							unr_ind_unique unr_ind_tot assetsA n_directors, d;
	restore;
};

esttab firm_summ_* using "Thesis/Interlocks/firm_summs.csv", replace
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1895" "1900" "1905" "1910" "1915" "1920") label;

#delimit cr
*-------------------------------------------------------------------------------

g byte overCA = (assetsA > 10/0.85 | assetsB > 10/0.85) if !inlist(., assetsA, assetsB)
lab var overCA "Both firms over Clayton Act Threshold (baseline spec: $10m / 0.85)"

drop if cidA > cidB // just keep one of each pair (order doesn't matter)
gen assets_ratio = assetsA/assetsB
	replace assets_ratio = 1/assets_ratio if assets_ratio < 1 
	lab var assets_ratio "Ratio of Assets (Large/Small)"
	
est clear
	

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
/*
#delimit ;
local summs_varlist "same_ind v_possible L5inc_inc L5inc_ent L5ent_ent sum_entrants sum_assets";
					
forval y = 1900(5)1920 {;
	eststo s_all_`y': estpost summ interlock banker banker_indtop10 `summs_varlist'
								if year_std == `y' /*& minyr < 1920*/, d;

	eststo s_notint_`y': estpost summ `summs_varlist'
								if year_std == `y' & !interlock /*& minyr < 1920*/, d;

	eststo s_int_`y': estpost summ banker banker_indtop10 horizontal vertical no_relationship `summs_varlist'
						if year_std == `y' & interlock /*& minyr < 1920*/, d;

	eststo s_intbnk_`y': estpost summ horizontal vertical no_relationship `summs_varlist'
						if year_std == `y' & interlock & banker /*& minyr < 1920*/, d;

	eststo s_intnotb_`y': estpost summ horizontal vertical no_relationship `summs_varlist'
						if year_std == `y' & interlock & !banker /*& minyr < 1920*/, d;
};

esttab s_all_* using "Thesis/Interlocks/interlock_summs.csv", replace
	cells("count mean(fmt(2)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	mtitles("1900" "1905" "1910" "1915" "1920") label note(" ")
	title("Full Sample");
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
	*/
foreach y in /*1900 1905 1910 1915*/ 1920 {
g byte y`y' = year_std == `y'
g byte overCA_X_`y' = y`y' * overCA
g byte same_ind_X_`y' = same_ind * y`y'
g byte v_possible_X_`y' = v_possible * y`y'
g byte overCA_X_`y'_X_same_ind = same_ind * overCA * y`y'
}

xtset pairid year_std

#delimit ;

est clear;

replace interlock = 0 if interlock == .;
replace banker = 0 if banker == .;
replace banker_indtop10 = 0 if banker_indtop10 == .;

xtset pairid year_std;

est clear;
eststo r1, title("Clayton Act     Panel     Interlocks"):
		xtreg interlock overCA overCA_X_1920 same_ind_X_1920 overCA_X_1920_X_same_ind
			, vce(cluster pairid) fe;
		estadd ysumm, mean;
eststo r2, title("Clayton Act     Panel     Interlocks"):
		xtreg interlock overCA overCA_X_1920 same_ind_X_1920 overCA_X_1920_X_same_ind
			ln_sum_assets assets_ratio, vce(cluster pairid) fe;
		estadd ysumm, mean;
eststo r3, title("Clayton Act     Panel     Interlocks"):
		xtreg interlock overCA overCA_X_1920 same_ind_X_1920 v_possible_X_1920
			overCA_X_1920_X_same_ind ln_sum_assets assets_ratio, vce(cluster pairid) fe;
		estadd ysumm, mean;
eststo r4, title("Clayton Act     Panel     Bankers"):
		xtreg banker overCA overCA_X_1920 same_ind_X_1920 overCA_X_1920_X_same_ind
			, vce(cluster pairid) fe;
		estadd ysumm, mean;
eststo r5, title("Clayton Act     Panel     Bankers"):
		xtreg banker overCA overCA_X_1920 same_ind_X_1920 overCA_X_1920_X_same_ind
			ln_sum_assets assets_ratio, vce(cluster pairid) fe;
		estadd ysumm, mean;
eststo r6, title("Clayton Act     Panel     Bankers"):
		xtreg banker overCA overCA_X_1920 same_ind_X_1920 v_possible_X_1920
			overCA_X_1920_X_same_ind ln_sum_assets assets_ratio, vce(cluster pairid) fe;
		estadd ysumm, mean;
esttab r? using "Thesis/Interlocks/interlock_regs_ca_panel.csv", replace 
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles scalars("ymean Mean of D.V.")
	order(overCA overCA_X_1920 same_ind_X_1920 v_possible_X_1920 overCA_X_1920_X_same_ind
			ln_sum_assets assets_ratio)
	addnotes("SEs clustered on pairid");


forval yr = 1900(5)1920 {;
	if `yr' == 1900 local abc "a";
	if `yr' == 1905 local abc "b";
	if `yr' == 1910 local abc "c";
	if `yr' == 1915 local abc "d";
	if `yr' == 1920 local abc "e";
	
	eststo s1`abc', title("Interlock       `yr'"):
			reg interlock same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr', vce(robust);
		estadd ysumm, mean;
				
	eststo s2`abc', title("Banker         (Orig. Top 10 Bankers)            `yr'"):
			reg banker same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr', vce(robust);
		estadd ysumm, mean;

	eststo s3`abc', title("Banker         (New Top 10 Ind Bankers)          `yr'"):
			reg banker_indtop10 same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr', vce(robust);
		estadd ysumm, mean;
	eststo s4`abc', title("Banker | Interlock         (Orig. Top 10 Bankers)            `yr'"):
			reg banker same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr' & interlock /*& minyr < 1920*/, vce(robust);
		estadd ysumm, mean;

	eststo s5`abc', title("Banker | Interlock         (New Top 10 Ind Bankers)          `yr'"):
			reg banker_indtop10 same_ind v_possible ln_sum_assets assets_ratio
				if year_std == `yr' & interlock /*& minyr < 1920*/, vce(robust);
		estadd ysumm, mean;
};
esttab s1* s2* s3* using "Thesis/Interlocks/interlock_regs_byyr.csv", replace 
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles scalars("ymean Mean(Dep. Var.)")
	order(same_ind v_possible ln_sum_assets assets_ratio)
	addnotes("Robust SEs");
			
			
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




