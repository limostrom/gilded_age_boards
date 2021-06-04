/*
RR_interlock_regs.do

*/
clear all
cap log close
pause on

cap cd "C:\Users\lmostrom\Documents\Gilded Age Boards - Scratch\"

*%% Prep Number of Directors Variable %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

use fullname_m cname year_std director using "Thesis/Merges/RR_boards_wtitles.dta", clear
keep if director == 1 & fullname_m != ""

collapse (count) n_directors = director, by(cname year_std)
ren cname cnameA

tempfile nd
save `nd', replace

*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cap cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Post-Thesis" // old computer
cap cd "C:\Users\lmostrom\Documents\Gilded Age Boards - Scratch\"

use "Thesis/Merges/UW_1880-1920_top10.dta", clear

egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname bankname

tempfile temp_uw
save `temp_uw', replace

*%%Prep Standardized RR Names to Merge In%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import delimited "Data/RR_names_years_corrected.csv", clear varn(1)

tempfile stn_cnames
save `stn_cnames', replace

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

use Data/assets, clear
	keep if sector == "RR"
	merge 1:1 cname year_std using `stn_cnames', keep(3) nogen
	tempfile assets
	save `assets', replace

use "Thesis/Merges/RR_boards_wtitles.dta", clear
	drop if cname == "KEOKUK AND DES MOINES RAILROAD" & year_std == 1890
merge m:1 cname year_std using `stn_cnames', keep(3) nogen
	egen id = group(cname_stn)
/*preserve
	keep year_std RRid
	duplicates drop
	reshape wide year, i(RRid) j(year_std)
	*keep if year1890 != . & year1910 != .
	keep RRid
	tempfile keep_rrs
	save `keep_rrs', replace
restore*/

*merge m:1 RRid using `keep_rrs', nogen keep(3)

merge m:1 cname_stn year_std using `assets', keepus(assets) keep(1 3)


*merge m:1 cname using "RR_Financials1890.dta", nogen keepus(region)

/*merge m:1 RRid using `financials', nogen keepus(cohort region receivership foreclosure)
merge m:1 RRid year_std using `financials', nogen ///
		keepus(marketcap totassets totdebt comstock surplus)
	ren totassets assets
	ren totdebt bfdebt
	gen bvlev = bfdebt/assets
merge m:1 RRid year_std using `acctg', nogen keepus(assets bfdebt bvlev) update */

drop if inlist(cname, "Metropolitan Elevated Railway", "New York Elevated Railroad", ///
					"New York and Elevated Railroad")
		
include "../GitHub/gilded_age_boards/assign_regions.do"
	
#delimit ;
* JTA: https://babel.hathitrust.org/cgi/pt?id=mdp.39015020928050&view=1up&seq=7;
gen jta = inlist(cname_stn, "Baltimore & Ohio",
						"Central of New Jersey",
						"Chesapeake & Ohio",
						"Cleve Cincin Chic & St Louis",
						"Delaware Lackaw & Western",
						"Erie",
						"Lake Shore & Mich Southern",
						"Lehigh Valley",
						"Michigan Central")
		| inlist(cname_stn, "NY Central & Hudson River",
						"NY Ontario & Western",
						"Pennsylvania RR",
						"Reading",
						"PITTSBURGH & WESTERN",
						"Pitts Cin Chic & St Louis",
						"TOLEDO, PEORIA & WESTERN",
						"Vandalia",
						"Wabash");			
#delimit cr

keep if director

preserve
	keep year_std fullname_m cname_stn id
	duplicates drop
	merge m:1 fullname_m year_std using `temp_uw', keep(1 3) keepus(bankname)
		gen banker = _merge == 3
		drop _merge bankname
	foreach var in cname_stn id {
		ren `var' `var'B
	}
	tempfile rrs
	save `rrs', replace

	foreach var in cname_stn id {
		ren `var'B `var'A
	}

	joinby fullname_m year_std using `rrs', _merge(_m_int)
	drop if fullname_m == ""
	gen interlock = _m_int == 3
		replace interlock = 0 if cname_stnA == cname_stnB
		replace banker = 0 if interlock == 0
		br fullname_m interlock banker cname_stnB cname_stnA year_std ///
			if year_std == 1905 
			*& cname_stnA == "Cleve Cincin Chic & St Louis"
		pause
	keep year_std interlock banker cname_stn? id?
	collapse  (sum) banker_tot = banker interlock_tot = interlock ///
			  (max) banker interlock (last) cname_stn?, by(year_std id?)
	tempfile interlocks
	save `interlocks', replace
restore

keep year_std cname cname_stn id region assets /*bfdebt bvlev*/ region jta
duplicates drop
foreach var in cname cname_stn id assets /*bfdebt bvlev*/ region jta {
	ren `var' `var'B
}
tempfile self
save `self', replace
foreach var in cname cname_stn id assets /*bfdebt bvlev*/ region jta {
	ren `var'B `var'A
}

joinby year_std using `self'
merge 1:1 year_std cname_stnA cname_stnB using `interlocks'

egen pairid = group(idA idB)

xtset pairid year_std
	foreach var of varlist interlock banker interlock_tot banker_tot {
	    replace `var' = 0 if `var' == .
	}
	gen same_reg = regionA == regionB
	gen sum_assets = assetsA + assetsB
	gen ln_sum_assets  = ln(sum_assets)
		replace sum_assets = sum_assets/1000000
		lab var sum_assets "Sum of RRs' Assets ($ M)"
	*gen avg_lev = (bvlevA + bvlevB)/2
	
*-------------------- Firm-Level Summary Stats ---------------------------------
lab var interlock "Interlocked"
lab var banker "Interlocked by Banker"
lab var same_reg "RRs in Same Region"

forval y = 1880(5)1920 {
    preserve
		lab var interlock ""
		ren interlock interlock_unique
		lab var banker ""
		ren banker banker_unique
		ren same_reg same_reg_unique
			replace same_reg_unique = 0 if interlock_unique == 0
		gen same_reg_tot = same_reg_unique * interlock_tot
		keep if year_std == `y'
		collapse (sum) interlock_* banker_* same_reg_tot same_reg_unique (max) assetsA, ///
			by(cnameA year_std)
		merge 1:1 cnameA year_std using `nd', keep(3) nogen
		replace assetsA = assetsA/1000000

		eststo rr_summ_`y': estpost summ interlock_tot interlock_unique ///
							banker_tot banker_unique same_reg_tot same_reg_unique ///
							assetsA n_directors, d
	restore
}

lab var interlock_tot "interlock_tot"
lab var banker_tot "banker_tot"
lab var assetsA "Assets ($ Mil)"
#delimit ;
esttab rr_summ_???? using "Thesis/Interlocks/RR_firm_summs.csv", replace
	cells("count mean(fmt(2)) sd(fmt(3)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	label note(" ");
#delimit cr
*-------------------------------------------------------------------------------
	
	keep if idA < idB
	gen assets_ratio = assetsA/assetsB
		replace assets_ratio = 1/assets_ratio if assets_ratio < 1
		lab var assets_ratio "Ratio of Assets (Large/Small)"
	forval y = 1880(5)1920 {
		* Sum of Assets
		qui summ sum_assets if year_std == `y', d
			if `y' == 1880 g byte assets_q1 = (sum_assets < `r(p25)') if year_std == `y'
			if `y' > 1880 replace assets_q1 = (sum_assets < `r(p25)') if year_std == `y'
		qui summ sum_assets if year_std == `y', d
			if `y' == 1880 g byte assets_q2 = (sum_assets >= `r(p25)') & (sum_assets < `r(p50)') ///
				if year_std == `y'
			if `y' > 1880 replace assets_q2 = (sum_assets >= `r(p25)') & (sum_assets < `r(p50)') ///
				if year_std == `y'
		qui summ sum_assets if year_std == `y', d
			if `y' == 1880 g byte assets_q3 = (sum_assets >= `r(p50)') & (sum_assets < `r(p75)') ///
				if year_std == `y'
			if `y' > 1880 replace assets_q3 = (sum_assets >= `r(p50)') & (sum_assets < `r(p75)') ///
				if year_std == `y'
		qui summ sum_assets if year_std == `y', d
			if `y' == 1880 g byte assets_q4 = (sum_assets >= `r(p75)') if year_std == `y'
			if `y' > 1880 replace assets_q4 = (sum_assets >= `r(p75)') if year_std == `y'
			
		*Size Ratio of Large Firm to Small Firms
		qui summ assets_ratio if year_std == `y', d
			if `y' == 1880 g byte assets_rat1 = (assets_ratio < `r(p25)') if year_std == `y'
			if `y' > 1880 replace assets_rat1 = (assets_ratio < `r(p25)') if year_std == `y'
		qui summ assets_ratio if year_std == `y', d
			if `y' == 1880 g byte assets_rat2 = (assets_ratio >= `r(p25)') & (assets_ratio < `r(p50)') ///
				if year_std == `y'
			if `y' > 1880 replace assets_rat2 = (assets_ratio >= `r(p25)') & (assets_ratio < `r(p50)') ///
				if year_std == `y'
		qui summ assets_ratio if year_std == `y', d
			if `y' == 1880 g byte assets_rat3 = (assets_ratio >= `r(p50)') & (assets_ratio < `r(p75)') ///
				if year_std == `y'
			if `y' > 1880 replace assets_rat3 = (assets_ratio >= `r(p50)') & (assets_ratio < `r(p75)') ///
				if year_std == `y'
		qui summ assets_ratio if year_std == `y', d
			if `y' == 1880 g byte assets_rat4 = (assets_ratio >= `r(p75)') if year_std == `y'
			if `y' > 1880 replace assets_rat4 = (assets_ratio >= `r(p75)') if year_std == `y'
	}

	drop if cnameA == "" | cnameB == "" // supposed to have been dropped, not present 1890-1910
	
	gen post = year_std > 1898
	gen jta = jtaA + jtaB == 2
		lab var jta "Both RRs in JTA"
	
	gen jta_X_post = jta & post
	gen same_reg_X_post = same_reg & post
	gen same_reg_X_jta = same_reg & jta
	gen same_reg_X_jta_X_post = same_reg & jta & post
	
	gen oth_reg = !same_reg
	
	replace banker = 0 if banker == .

	foreach y in 1880 1885 1895 1900 1905 1910 1915 1920 {
		gen y`y' = year_std == `y'
		gen same_reg_X_`y' = same_reg & y`y'
		gen oth_reg_X_`y' = oth_reg & y`y'
	}
	
xtset pairid year_std

#delimit ;
/*
eststo r1a1, title("Interlocks     JTA Only"):
				xtreg interlock jta_X_post, vce(cluster pairid) fe;
eststo r1a3, title("Interlocks        Same Reg & JTA"):
				xtreg interlock
				same_reg_X_post jta_X_post
				same_reg_X_jta_X_post, vce(cluster pairid) fe;
eststo r1c1, title("Interlocks     JTA Only      (w/ Controls)"):
				xtreg interlock jta_X_post
				ln_sum_assets assets_ratio, vce(cluster pairid) fe;
eststo r1c3, title("Interlocks        Same Reg & JTA         (w/ Controls)"):
				xtreg interlock
				same_reg_X_post jta_X_post
				same_reg_X_jta_X_post
				ln_sum_assets assets_ratio, vce(cluster pairid) fe;

eststo r2a1, title("Bankers     JTA Only"):
				xtreg banker jta_X_post, vce(cluster pairid) fe;
eststo r2a2, title("Bankers        Same Reg & JTA"):
				xtreg banker 
				same_reg_X_post jta_X_post
				same_reg_X_jta_X_post, vce(cluster pairid) fe;
eststo r2b1, title("Bankers     JTA Only         (w/ Controls)"):
				xtreg banker jta_X_post
				ln_sum_assets assets_ratio, vce(cluster pairid) fe;
eststo r2b2, title("Bankers        Same Reg & JTA         (w/ Controls)"):
				xtreg banker 
				same_reg_X_post jta_X_post
				same_reg_X_jta_X_post
				ln_sum_assets assets_ratio, vce(cluster pairid) fe;
				
/*eststo r3a1, title("Bankers    JTA Only           Cond. on Int."):
				xtreg banker jta_X_post if interlock, vce(cluster pairid) fe;
eststo r3a2, title("Bankers        Same Reg & JTA          Cond. on Int."):
				xtreg banker 
				same_reg_X_post  jta_X_post same_reg_X_jta_X_post
				if interlock, vce(cluster pairid) fe;
eststo r3c1, title("Bankers    JTA Only       (w/ Controls)          Cond. on Int."):
				xtreg banker jta_X_post
				ln_sum_assets assets_ratio if interlock, vce(cluster pairid) fe;
eststo r3c2, title("Bankers        Same Reg & JTA (w/ Controls)          Cond. on Int."):
				xtreg banker 
				same_reg_X_post jta_X_post  same_reg_X_jta_X_post
				ln_sum_assets assets_ratio if interlock, vce(cluster pairid) fe;*/
	
esttab r* using "Thesis/Interlocks/RR_interlock_xtregs.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) mtitles se;
*/

est clear;
forval yr = 1890(5)1920 {;
	if `yr' == 1890 local abc "a";
	if `yr' == 1895 local abc "b";
	if `yr' == 1900 local abc "c";
	if `yr' == 1905 local abc "d";
	if `yr' == 1910 local abc "e";
	if `yr' == 1915 local abc "f";
	if `yr' == 1920 local abc "g";
	
	
	eststo r1`abc', title("Interlock       `yr'"):
				reg interlock jta same_reg same_reg_X_jta
					ln_sum_assets assets_ratio
					if year_std == `yr', vce(robust);
					
	eststo r2`abc', title("Banker          `yr'"):
				reg banker jta same_reg same_reg_X_jta
					ln_sum_assets assets_ratio
					if year_std == `yr', vce(robust);
	
	eststo s1`abc', title("Interlock       `yr'"):
				reg interlock same_reg ln_sum_assets assets_ratio
					if year_std == `yr', vce(robust);
					
	eststo s2`abc', title("Banker          `yr'"):
				reg banker same_reg ln_sum_assets assets_ratio
					if year_std == `yr', vce(robust);
	/*eststo s3`abc', title("Banker | Interlock          `yr'"):
				reg banker same_reg ln_sum_assets assets_ratio
					if year_std == `yr' & interlock, vce(cluster pairid);*/
};

esttab r1* r2* using "Thesis/Interlocks/RR_interlock_regs.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles
	order(jta same_reg same_reg_X_jta ln_sum_assets assets_ratio);
esttab s1* s2* /*s3**/ using "Thesis/Interlocks/RR_simplified_interlock_regs.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles
	order(same_reg ln_sum_assets assets_ratio);
				

#delimit cr
/*
lab var same_reg_X_jta "RRs in Same Region & in JTA"

forval y = 1880(5)1920 {
	eststo tab_full`y': estpost summ interlock banker same_reg jta same_reg_X_jta ///
		if year_std == `y'
	
	eststo tab_notint`y': estpost summ same_reg jta same_reg_X_jta ///
		if year_std == `y' & !interlock
		
	eststo tab_int`y': estpost summ banker same_reg jta same_reg_X_jta ///
		if year_std == `y' & interlock
		
	eststo tab_intbnk`y': estpost summ same_reg jta same_reg_X_jta ///
		if year_std == `y' & interlock & banker
		
	eststo tab_intnotbnk`y': estpost summ same_reg jta same_reg_X_jta ///
		if year_std == `y' & interlock & !banker
*-------------------------------------------------------------------------------
	eststo tab_jta`y': estpost summ interlock banker same_reg ///
		if year_std == `y' & jta
	eststo tab_notjta`y': estpost summ interlock banker same_reg ///
		if year_std == `y' & !jta
*-------------------------------------------------------------------------------
	eststo assets_full`y': estpost summ sum_assets assets_ratio ///
			if year_std == `y', d
	
	eststo assets_notint`y': estpost summ sum_assets assets_ratio ///
			if year_std == `y' & !interlock, d
		
	eststo assets_int`y': estpost summ sum_assets assets_ratio ///
			if year_std == `y' & interlock, d
		
	eststo assets_intbnk`y': estpost summ sum_assets assets_ratio ///
			if year_std == `y' & interlock & banker, d
		
	eststo assets_intnotbnk`y': estpost summ sum_assets assets_ratio ///
			if year_std == `y' & interlock & !banker, d
}

#delimit ;

esttab tab_full???? using "Thesis/Interlocks/RR_interlock_summs.csv", replace
	cells("count mean(fmt(2))") label note(" ")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	title("Full Sample - Pairs Existing 1890-1910");
esttab tab_notint???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2))") label note(" ")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	title("Pairs Not Interlocked");
esttab tab_int???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2))") label note(" ")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	title("Pairs Interlocked");
esttab tab_intbnk???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2))") label note(" ")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	title("Banker Interlocks (Top 10 Underwriters)");
esttab tab_intnotbnk???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2))") label note("---------------------")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	title("Non-Banker Interlocks");
	
esttab tab_jta???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2))") label note(" ")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	title("Both RRs in JTA");
esttab tab_notjta???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2))") label note("---------------------")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	title("Non-JTA Railroad Pairs");

esttab assets_full???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	label note(" ") title("Full Sample - Pairs Existing 1890-1910");
esttab assets_notint???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	label note(" ") title("Pairs Not Interlocked");
esttab assets_int???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	label note(" ") title("Pairs Interlocked");
esttab assets_intbnk???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	label note(" ") title("Banker Interlocks (Top 10 Underwriters)");
esttab assets_intnotbnk???? using "Thesis/Interlocks/RR_interlock_summs.csv", append
	cells("count mean(fmt(2)) sd(fmt(3)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2))")
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915" "1920")
	label note(" ") title("Non-Banker Interlocks");
	
	*/
#delimit cr
	sdf
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
foreach y in 1880 1885 1895 1900 1905 1910 1915 1920 {
	*gen y`y' = year_std == `y'
	gen jta_X_`y' = jta*y`y'
	*gen same_reg_X_`y' = same_reg * y`y'
	gen same_reg_X_jta_X_`y' = same_reg * jta * y`y'
}

drop same_reg_X_post jta_X_post same_reg_X_jta_X_post

cap mkdir "Thesis/Interlocks/Interaction Term Plots/"
cd "Thesis/Interlocks/Interaction Term Plots/"

foreach yvar in "interlock" /*"banker"*/ {
forval jta_only = 0/1 {
	local Yvar = proper("`yvar'") + "s"
	/*if "`yvar'" == "interlock" {*/
	if `jta_only' == 0 {
		local stemlist "same_reg_X_ jta_X_ same_reg_X_jta_X_"
		local _ext ""
	}
	if `jta_only' == 1 {
		local stemlist "jta_X_"
		local _ext "_JTAonly"
	}
	if `jta_only' drop same_reg_X_*
	*if "`yvar'" == "banker" local stemlist "same_reg_X_ jta_X_"

foreach wc in /*""*/ "_wCont" {
    if "`wc'" == "_wCont" {
	    local controls "ln_sum_assets assets_ratio"
		local subti2 "(with Controls)"
		local note "note(Controls include ln_sum_assets and assets_ratio)"
	}
	if "`wc'" == "" {
	    local controls ""
		local subti2 ""
		local note ""
	}
	/* INTERLOCKS & BANKERS, UNCONDITIONAL, NO FE
	if "`yvar'" == "interlock" {
		#delimit ;
		if `jta_only' == 0 reg `yvar' y???? same_reg jta
			same_reg_X_jta same_reg_X_???? jta_X_????
			same_reg_X_jta_X_???? `controls', vce(cluster pairid);
		else reg `yvar' y???? jta jta_X_???? `controls', vce(cluster pairid);
		
		mat M = (r(table)["b", "same_reg_X_1880".."jta_X_1920"],
						r(table)["b", "same_reg_X_jta_X_1895".."same_reg_X_jta_X_1920"])
					\ (r(table)["ll".."ul", "same_reg_X_1880".."jta_X_1920"],
						r(table)["ll".."ul", "same_reg_X_jta_X_1895".."same_reg_X_jta_X_1920"]);
		
		#delimit cr
	}
	if "`yvar'" == "banker" {
	    #delimit ;
		if `jta_only' == 0 reg `yvar' y???? same_reg jta
			same_reg_X_jta same_reg_X_???? jta_X_????
			same_reg_X_jta_X_???? `controls', vce(cluster pairid);
		else reg `yvar' y???? jta jta_X_???? `controls', vce(cluster pairid);
		
		mat M = r(table)["b", "same_reg_X_1880".."same_reg_X_jta_X_1920"]
					\ r(table)["ll".."ul", "same_reg_X_1880".."same_reg_X_jta_X_1920"];
		
		
		#delimit cr
	}
	preserve
		drop *
		svmat2 M, n(col) r(coeff)
		
		foreach var of local stemlist {
		    gen `var'1890 = 0
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
			   title("`Yvar'") subti("`subti2'")
			   `note';
			graph export "RR_`yvar'_`stem'coeffs`wc'`_ext'.png", replace as(png) wid(600) hei(350);
			  
			#delimit cr
		}
	restore
		*/
	* INTERLOCKS & BANKERS, UNCONDITIONAL, W/ FE
	if "`yvar'" == "interlock" {
		#delimit ;
		if `jta_only' == 0 {;
			xtreg `yvar' y???? same_reg_X_???? jta_X_????
			same_reg_X_jta_X_???? `controls', fe vce(cluster pairid);
			
			mat M`jta_only' = r(table)["b", "same_reg_X_1880".."same_reg_X_jta_X_1920"]
					\ r(table)["ll".."ul", "same_reg_X_1880".."same_reg_X_jta_X_1920"];
		};
		else {;
			xtreg `yvar' y???? jta_X_???? `controls', fe vce(cluster pairid);
			
			mat M`jta_only' = r(table)["b", "jta_X_1880".."jta_X_1920"]
					\ r(table)["ll".."ul", "jta_X_1880".."jta_X_1920"];
		};
		
		
		
		#delimit cr
	}
	if "`yvar'" == "banker" {
		#delimit ;
		if `jta_only' == 0 xtreg `yvar' y???? same_reg_X_???? jta_X_????
			same_reg_X_jta_X_???? `controls', fe vce(cluster pairid);
		if `jta_only' == 0 xtreg `yvar' y???? same_reg_X_???? jta_X_????
			same_reg_X_jta_X_???? `controls', fe vce(cluster pairid);
		
		mat M`jta_only' = r(table)["b", "jta_X_1880".."jta_X_1920"]
					\ r(table)["ll".."ul", "jta_X_1880".."jta_X_1920"];
		
		#delimit cr
	}
}
	
	preserve
		drop *
		svmat2 M, n(col) r(coeff)
		
		foreach var of local stemlist {
		    gen `var'1890 = 0
		}
		
		reshape long `stemlist', i(coeff) j(year_std)
		reshape wide `stemlist', i(year_std) j(coeff) string
		
		foreach stem of local stemlist {
		    #delimit ;
			tw (rcap `stem'll `stem'ul year_std, lc(gs7))
			   (scatter `stem'b year_std, msym("o") mc(black)),
			   legend(order(1 "95% Confidence Interval"))
			   yline(0, lc(gs12)) xline(1898, lc(gs12) lp(-))
			   xti("") yti("Coefficient Magnitude" "`stem'*")
			   title("`Yvar'") subti("with Fixed Effects & Controls")
			   `note';
			graph export "RR_`yvar'_`stem'coeffs`wc'_wFE`_ext'.png", replace as(png) wid(600) hei(350);
			  
			#delimit cr
		}
	restore
		
	/* BANKERS, CONDITIONAL, W/ FE
	if "`yvar'" == "banker" {
		#delimit ;
		xtreg `yvar' y???? /*same_reg jta
			same_reg_X_jta*/ same_reg_X_???? jta_X_????
			same_reg_X_jta_X_???? `controls' if interlock, fe vce(cluster pairid);
		
		mat M = r(table)["b", "same_reg_X_1880".."jta_X_1920"]
					\ r(table)["ll".."ul", "same_reg_X_1880".."jta_X_1920"];
		
		#delimit cr
		preserve
			drop *
			svmat2 M, n(col) r(coeff)
			
			foreach var in same_reg_X_ jta_X_ {
				gen `var'1890 = 0
			}
			
			reshape long same_reg_X_ jta_X_ , i(coeff) j(year_std)
			reshape wide same_reg_X_ jta_X_ , i(year_std) j(coeff) string
		
			foreach stem in "same_reg_X_" "jta_X_" {
				#delimit ;
				tw (rcap `stem'll `stem'ul year_std, lc(gs7))
				   (scatter `stem'b year_std, msym("o") mc(black)),
				   legend(order(1 "95% Confidence Interval"))
				   yline(0, lc(gs12)) xti("")
				   yti("Coefficient Magnitude" "`stem'*")
				   title("Bankers") subti("Conditional on Interlock" "with Fixed Effects & Controls")
				   `note';
				graph export "RR_`yvar'_`stem'coeffs_conditional`wc'`_ext'.png",
					replace as(png) wid(600) hei(350);
				  
				#delimit cr
			}
		
		restore
	}
		*/
}
} // jta_only loop
} // interlock/banker loop


*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/*
*** BASELINE ***
reg interlock jta y1885 y1890 y1895 y1900 y1905 y1910 y1915 y1920 ///
	jta_X_1885 jta_X_1890 jta_X_1895 jta_X_1900 ///
	jta_X_1905 jta_X_1910 jta_X_1915 jta_X_1920
	
local b_jta = e(b)[1,1]
mat Myears = e(b)[1,2..9]
mat Mints = e(b)[1,10..17]
local cons = e(b)[1,18]

local b1 = `cons' + `b_jta'
mat P = (1880, 0, `cons' \ 1880, 1, `b1')
local ii 1
forval y= 1885(5)1920 {
	local b0 = `cons' + Myears[1,`ii']
	local b1 = `cons' + `b_jta' + Myears[1,`ii'] + Mints[1,`ii']
	mat P = (P \ `y', 0, `b0' \ `y', 1, `b1')
	local ++ii
}

mat colnames P = year jta b
preserve
drop *
svmat2 P, n(matcol)

#delimit ;
tw (line Pb Pyear if Pjta == 0, lp(_) lc(black))
   (line Pb Pyear if Pjta == 1, lp(l) lc(black))
   (scatter Pb Pyear if Pjta == 0 , mc(white) msym(O))
   (scatter Pb Pyear if Pjta == 1 , mc(white) msym(O))
   (scatter Pb Pyear if Pjta == 0 , mc(black) msym(Oh))
   (scatter Pb Pyear if Pjta == 1 , mc(black) msym(Oh)),
  legend(order(2 "Both RRs in JTA" 1 "Non-JTA Pairs") r(1))
  xti("") yti("% Interlocked") subti("Baseline Model")
  xline(1898, lc(gs7));
graph export "Thesis/Interlocks/jta_base_byYear.png", replace as(png) wid(1200) hei(700);
#delimit cr
restore

*** WITH CONTROLS (ASSETS) ***
reg interlock jta y1885 y1890 y1895 y1900 y1905 y1910 y1915 y1920 ///
	jta_X_1885 jta_X_1890 jta_X_1895 jta_X_1900 ///
	jta_X_1905 jta_X_1910 jta_X_1915 jta_X_1920 ln_sum_assets assets_ratio
	
local b_jta = e(b)[1,1]
mat Myears = e(b)[1,2..9]
mat Mints = e(b)[1,10..17]
local cons = e(b)[1,20]

local b1 = `cons' + `b_jta'
mat P = (1880, 0, `cons' \ 1880, 1, `b1')
local ii 1
forval y= 1885(5)1920 {
	local b0 = `cons' + Myears[1,`ii']
	local b1 = `cons' + `b_jta' + Myears[1,`ii'] + Mints[1,`ii']
	mat P = (P \ `y', 0, `b0' \ `y', 1, `b1')
	local ++ii
}

mat colnames P = year jta b

drop *
svmat2 P, n(matcol)

#delimit ;
tw (line Pb Pyear if Pjta == 0, lp(_) lc(black))
   (line Pb Pyear if Pjta == 1, lp(l) lc(black))
   (scatter Pb Pyear if Pjta == 0 , mc(white) msym(O))
   (scatter Pb Pyear if Pjta == 1 , mc(white) msym(O))
   (scatter Pb Pyear if Pjta == 0 , mc(black) msym(Oh))
   (scatter Pb Pyear if Pjta == 1 , mc(black) msym(Oh)),
  legend(order(2 "Both RRs in JTA" 1 "Non-JTA Pairs") r(1))
  xti("") yti("Interlock Coefficients") subti("With Controls")
  xline(1898, lc(gs7));
graph export "Thesis/Interlocks/jta_wcontrols_byYear.png", replace as(png) wid(1200) hei(700);
#delimit cr





