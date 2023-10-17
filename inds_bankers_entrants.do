


* Industry codings // ----------------------------------------------------------
cap cd "/Users/laurenmostrom/Dropbox/Personal Document Backup/Gilded Age Boards - Scratch/"
use  "Thesis/Interlocks/interlocks_coded.dta", clear

keep cnameA indA year_std
duplicates drop

ren cnameA cname
ren indA industry
encode industry, gen(industry_code)

tempfile industries
save `industries', replace


* Underwriter Names (Top 10) // ------------------------------------------------
cd "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Merges/"

use "UW_1880-1920_top10.dta", clear

keep fullname_m year_std
duplicates drop

tempfile bankers
save `bankers', replace

*-------------------------------------------------------------------------------


* Industrial Boards Upon Firm Entry
cd "../Final Board Data"

use cname fullname_m year_std cid using "Ind_boards_final.dta", clear

replace cid = 338 if cid == 138 // Pullman Palace Car & Pullman Co
replace cid = 436 if cid == 247 // Case JI 
gen cname_stn = strupper(cname)
	replace cname_stn = subinstr(cname_stn, "THE ", "", .)
	replace cname_stn = subinstr(cname_stn, "'", "", .)
	replace cname_stn = subinstr(cname_stn, ",", "", .)
	replace cname_stn = subinstr(cname_stn, "&", "AND", .)
	replace cname_stn = subinstr(cname_stn, "COMPANY", "CO", .)
	replace cname_stn = subinstr(cname_stn, "  ", " ", .)
	replace cname_stn = subinstr(cname_stn, "  ", " ", .)
	replace cname_stn = subinstr(cname_stn, ".", "", .)
	replace cname_stn = subinstr(cname_stn, "NATINOAL", "NATIONAL", .)
	replace cname_stn = subinstr(cname_stn, "UNITED STATES", "US", .)
	replace cname_stn = subinstr(cname_stn, "U S", "US", .)
bys cid: ereplace cname_stn = mode(cname_stn)
* Note: looks like I have fixed companies that changed names but are the same
*	company, to avoid counting their entry twice
bys cid: egen entry_yr = min(year_std)
bys cid: egen exit_yr = max(year_std)
	replace exit_yr = . if exit_yr == 1920

	
preserve
	egen tagged = tag(cid year_std)

	gen entered = entry_yr == year_std
		replace entered = entered * tagged
	gen exited = exit_yr == year_std
		replace exited = exited * tagged
		
	collapse (sum) entered exited tagged, by(year_std)
	export delimited "../FHM/Latest Tables & Figures/industrials_churn_table.csv", replace
restore

gen entrant = year_std == entry_yr

merge m:1 fullname_m year_std using `bankers', keep(1 3)
gen banker = _merge == 3

preserve // Entrants plot
	keep if year_std == entry_yr
	collapse (max) banker, by(cid entry_yr)
	collapse (count) n_entrants = cid (sum) had_banker = banker, by(entry_yr)
	gen sh_had_banker = had_banker / n_entrants

	export delimited "../FHM/Latest Tables & Figures/industrials_entry_wTop10.csv", replace

	#delimit ;
	tw (line n_entrants entry_yr, lp(l) lc(black))
	   (scatter n_entrants entry_yr, msym(O) mc(white))
	   (scatter n_entrants entry_yr, msym(Oh) mc(black))
	   (line had_banker entry_yr, lp(_) lc(black))
	   (scatter had_banker entry_yr, msym(O) mc(white))
	   (scatter had_banker entry_yr, msym(Oh) mc(black)),
	  legend(order(1 "Entrants" 4 "Entrants w/ Top 10 UW") r(1))
	  ti("Entering Industrials Firms with Top 10 Underwriters")
	  xti("Year") yti("Number of Firms");
	graph export "../FHM/Latest Tables & Figures/industrials_entry_wTop10.pdf", replace as(pdf);

	replace sh_had_banker = sh_had_banker * 100;
	tw (line sh_had_banker entry_yr, lp(_) lc(black))
	   (scatter sh_had_banker entry_yr, msym(O) mc(white))
	   (scatter sh_had_banker entry_yr, msym(Oh) mc(black)),
	  legend(off)
	  ti("Entering Industrials Firms with Top 10 Underwriters")
	  xti("Year") yti("Percent of Entrants") ylab(0(10)50);
	graph export "../FHM/Latest Tables & Figures/industrials_entry_wTop10_pct.pdf", replace as(pdf);
	#delimit cr
restore


cd "../../Personal Document Backup/Gilded Age Boards - Scratch/"

collapse (count) boardsize = _merge (max) has_top10uw = banker ///
		 (sum) n_top10uw = banker (last) entrant entry_yr, ///
	by(cid cname cname_stn year_std) 

	gen hastop10_X_entrant = has_top10uw * entrant
	drop if cid == 436 & year_std == 1920 & cname == "CASE J I PLOW CO"
	
	
merge 1:1 cname year_std using `industries', nogen keep(1 3)

merge 1:1 cname year_std using "Data/assets_ind.dta", nogen keep(1 3)

gen ln_assets = ln(assets)



*** Banker Regressions
est clear
#delimit ;

eststo m1, title("Top 10 UW"):
	reg has_top10uw ln_assets, vce(robust);
		estadd ysumm, mean;

eststo m2, title("Top 10 UW + Entry Yr Dummies"):
	reg has_top10uw ln_assets i.entry_yr, vce(robust);
		estadd ysumm, mean;

eststo m3, title("Top 10 UW + Industry Dummies "):
	reg has_top10uw ln_assets i.industry_code, vce(robust);
		estadd ysumm, mean;

eststo m4, title("Top 10 UW + Year Dummies"):
	reg has_top10uw ln_assets i.year_std, vce(robust);
		estadd ysumm, mean;
		

esttab m* using "Thesis/Interlocks/Ind_banker_regs.csv", replace label
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles scalars("ymean Mean(Dep. Var.)")
	addnotes("Robust SEs");
#delimit cr


*** Growth Regressions
xtset cid year_std

gen f5_dln_assets = f5.ln_assets - ln_assets
*replace f5_dln_assets = (f10.ln_assets - ln_assets)/2 if f5_dln_assets == .
*replace f5_dln_assets = (f15.ln_assets - ln_assets)/3 if f5_dln_assets == .

est clear
#delimit ;

eststo m1, title("dln Assets (F5)"):
	reghdfe f5_dln_assets has_top10uw,
						a(industry_code year_std) vce(robust);
		estadd ysumm, mean;

eststo m2, title("dln Assets (F5)"):
	reghdfe f5_dln_assets has_top10uw entrant hastop10_X_entrant, 
						a(industry_code year_std) vce(robust);
		estadd ysumm, mean;

eststo m3, title("dln Assets (F5)"):
	reghdfe f5_dln_assets has_top10uw entrant hastop10_X_entrant ln_assets,
						a(industry_code year_std) vce(robust);
		estadd ysumm, mean;

		

esttab m* using "Thesis/Interlocks/Ind_growth_regs.csv", replace label
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles scalars("ymean Mean(Dep. Var.)")
	addnotes("Robust SEs and Year and Industry FEs");
#delimit cr









	
	