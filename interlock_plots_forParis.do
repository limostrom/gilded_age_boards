/*
Title: collusion_bysector.do
Date: 10/21/2018
Description: Same as collusion.do, but this time plotting both sectors on the same
	graphs instead of individually
*/


cap log close
set more off
pause on

local png_ops "as(png) replace width(1500)"

cap cd "C:\Users\lmostrom\Documents\PersonalResearch\"

********************************************************************************
local run_1 0 // # RRs over time
local run_2 0 // Mean # directors over time
local run_3 0 // Mean # banker-directors (from top 10 underwriting firms)
local run_4 0 // Mean # total interlocks (i.e. number of directors on the board of
				// another railroad) vs # total interlocks made by
				// banker-directors by sector
local run_5 0 // Mean number of unique interlocks (i.e. number of RRs who share 
				// one of your directors) vs # unique interlocks made by
				// banker-directors by sector
local run_6 1 // Mean # same industry/region or vertical interlocks and
				// those created by banker-directors
local receiverships 0 // plots number of receiverships by year
local int_mats 0 // saves matrices of interlocks among industrials firms

local prop_top10 0 // proportion of firms with a top 10 underwriter by sector
local prop_top25 0 // proportion of firms with a  top 25 underwriter by sector
local prop_nyse 0 // proportion of firms with any NYSE IB partner
local prop_CB 0 // proportion of firms w/ a commercial banker by sector
local prop_majCB 0 // proportion of firms w/ a *major* commercial banker by sector
local prop_bigCB 0 // proportion of firms w/ a dir of one of the biggest CBs
local prop_majCBxUW 0 // proportion of firms w/ a *major* commercial banker by sector
local prop_bigCBxUW 0 // proportion of firms w/ a dir of one of the biggest CBs
local prop_majUW 0 // proportion of firms w/ a *major* underwriter by sector
local prop_GFB 0 // proportion of firms w/ George F Baker on the board by sector

local prop_JayCooke 0 // proportion of firms with an underwriter from one of the banks
						// mentioned in the Jay Cooke biography
local prop_top10_plus_early 0 // proportion of firms with an underwriter from
					// either the top10 list or from the Jay Cooke biography
local assets 0 // total, avg, and median assets over time by sector
local int_byind 0 // tab interlocks within newly assigned "industries"
local ngram 0 // load in google ngram results and plots
********************************************************************************

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
*%%Create Folder for Plots%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
local filepath: pwd
cap mkdir "`filepath'/Plots - Apr 2021"
local plot_dir "`filepath'/Plots - Apr 2021/"
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

********************************************************************************
** Number of Directors & Banker-Directors
if `run_1' == 1 {
********************************************************************************
preserve

egen tagged = tag(`id' year_std  sector)
keep if tagged

collapse (count) `id', by(year_std sector)

gen secfactor = 1 if sector == "RR"
replace secfactor = 2 if sector == "Ind"
xtset secfactor year_std

if `run_1' == 1 {
#delimit ;
tw (line `id' year_std if sector == "RR", lc(black) lp(l))
   (line `id' year_std if sector == "Ind", lc(black) lp(_))
   (scatter `id' year_std if sector == "RR", mc(white) msym(O))
   (scatter `id' year_std if sector == "Ind", mc(white) msym(O))
   (scatter `id' year_std if sector == "RR", mc(black) msym(Oh))
   (scatter `id' year_std if sector == "Ind", mc(black) msym(Oh)),
 legend(order(1 "Railroads" 2 "Industrials & Utilities"))
 title(Number of Firms) yti("") xti("")
 graphregion(color(white)) bgcolor(white);
graph export "`plot_dir'g1_num_firms_ts_bysector.png", `png_ops';
#delimit cr
}

restore
}

********************************************************************************
** Number of Directors & Banker-Directors
if `run_2' == 1 | `run_3' == 1 {
********************************************************************************
preserve

merge m:1 year_std fullname_m using `temp_uw', keepusing(bankname) keep(1 3)
gen bnkr_dir = (_merge == 3)
pause

bys `id' year_std sector: egen n_directors = count(fullname_m)
bys `id' year_std sector: egen n_bnkr_directors = sum(bnkr_dir)

egen tagged = tag(`id' year_std sector)
keep if tagged

sort year_std sector cname
export excel year_std sector cname `id' newly_added n_directors n_bnkr_directors ///
	using "n_bnkr_directors_byFirm.xls", replace first(var)

collapse (mean) mean_directors = n_directors ///
		(mean) mean_bnkr_directors = n_bnkr_directors, by(year_std sector)

gen secfactor = 1 if sector == "RR"
replace secfactor = 2 if sector == "Ind"
xtset secfactor year_std

if `run_2' == 1 {
#delimit ;
tw (line mean_directors year_std if sector == "RR", lc(black) lp(l))
   (line mean_directors year_std if sector == "Ind", lc(black) lp(_))
   (scatter mean_directors year_std if sector == "RR", mc(white) msym(O))
   (scatter mean_directors year_std if sector == "Ind", mc(white) msym(O))
   (scatter mean_directors year_std if sector == "RR", mc(black) msym(Oh))
   (scatter mean_directors year_std if sector == "Ind", mc(black) msym(Oh)),
 legend(order(1 "Railroads" 2 "Industrials & Utilities"))
 title(Mean Number of Directors & Officers) yti("") xti("")
 graphregion(color(white)) bgcolor(white);
graph export "`plot_dir'g2_mn_directors_ts_bysector.png", `png_ops';
#delimit cr
}
if `run_3' == 1 {
#delimit ;
tw (line mean_bnkr_directors year_std if sector == "RR", lc(black) lp(l))
   (line mean_bnkr_directors year_std if sector == "Ind", lc(black) lp(_))
   (scatter mean_bnkr_directors year_std if sector == "RR", mc(white) msym(O))
   (scatter mean_bnkr_directors year_std if sector == "Ind", mc(white) msym(O))
   (scatter mean_bnkr_directors year_std if sector == "RR", mc(black) msym(Oh))
   (scatter mean_bnkr_directors year_std if sector == "Ind", mc(black) msym(Oh)),
 legend(order(1 "Railroads" 2 "Industrials & Utilities"))
 title(Mean Number of Banker-Directors) yti("") xti("")
 graphregion(color(white)) bgcolor(white);
graph export "`plot_dir'g3_mn_bnkr_directors_ts_bysector.png", `png_ops';
#delimit cr
}
/*
if `run_2' == 1 & `run_3' == 1 {
tsline mean_directors mean_bnkr_directors, ///
	graphregion(color(white)) bgcolor(white) ///
	lp(solid solid) lc(green midblue) ///
	title(Mean Banker-Directors and Total Directors) by(sector)
graph export "`plot_dir'g2-3_bnkr_vs_tot_dirs_ts_bysector.png", `png_ops'
}
*/
restore
}
********************************************************************************
** Number of Interlocks Between `Companies'
if `run_4' == 1 | `run_5' == 1 | `int_mats' == 1 {
********************************************************************************

*identify the people on multiple boards
bys year_std fullname_m sector: gen dup_person = cond(_N==1, 0, _n)

* ------------ Matrix of Industrials Interlocks ------------ *
forval yr = 1895(5)1920 {
	preserve
		keep if sector == "Ind" & year_std == `yr'
			drop dup_person cid newly_added
			egen tagged = tag(fullname_m cname)
			keep if tagged
		gen val = 1
		replace cname = subinstr(cname, " ", "", .)
		replace cname = subinstr(cname, ".", "", .)
		replace cname = subinstr(cname, ",", "", .)
		replace cname = subinstr(cname, "(", "", .)
		replace cname = subinstr(cname, ")", "", .)
		replace cname = subinstr(cname, "'", "", .)
		replace cname = subinstr(cname, "-", "", .)
		replace cname = subinstr(cname, "&", "and", .)
		replace cname = substr(cname, 1, 29)
		reshape wide val, i(fullname_m) j(cname) string
			foreach var of varlist val* {
				replace `var' = 0 if `var' == .
			}

		ren val* int*
		tempfile names_wide
		save `names_wide', replace
	restore
	preserve
		keep if sector == "Ind" & year_std == `yr'
		merge m:1 fullname_m using `names_wide', nogen keep(1 3)
			collapse (max) int*, by(cname cid)
		 export excel "industrials_interlocks_matrices.xlsx", sh("`yr'", replace) first(var)
	restore
}
* ---------------------------------------------------------- *
egen num_boards = max(dup_person), by(fullname_m year_std sector)

preserve

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

restore

preserve

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
gen banker = (_merge == 3) if sector == "RR"
drop _merge

gen new = 0
bys year_std firmA firmB sector: replace new = 1 if _n==1

egen unique_interlock_bytype = tag(firmA firmB year_std banker sector)
keep if unique_interlock_bytype

sort sector firmA firmB year_std banker
egen tagged = tag(firmA firmB year_std sector)
drop if !tagged & !new
pause

collapse (sum) unique_interlock = unique_interlock_bytype banker ///
		 (first) cnameA, by(year_std firmA sector)

sort year_std sector cnameA firmA unique_interlock banker
export excel year_std sector cnameA firmA unique_interlock banker ///
	using "n_unique_interlocks between_RRs.xls", replace first(var)
		 
gen sh_bnkr_ints_un = banker/unique_interlock

collapse (median) med_unique_interlocks = unique_interlock ///
		(p90) p90_unique_interlocks = unique_interlock ///
		(mean) mean_unique_interlocks = unique_interlock ///
		(mean) mean_unique_banker_interlocks = banker ///
		(mean) mean_sh_bnkr_ints_un = sh_bnkr_ints_un ///
		(max) max_unique_interlocks = unique_interlock ///
		(p75) p75_unique_interlocks = unique_interlock, by(year_std sector)

merge 1:1 year_std sector using `temp_totints', nogen

gen secfactor = 1 if sector == "RR"
replace secfactor = 2 if sector == "Ind"
xtset secfactor year_std

#delimit ;

if `run_4' == 1 {;
tw (line mean_tot_interlocks year_std if sector == "RR", lc(black) lp(l))
   (line mean_tot_bnkr_interlocks year_std if sector == "RR", lc(gs7) lp(l))
   (scatter mean_tot_interlocks year_std if sector == "RR", mc(white) msym(O))
   (scatter mean_tot_bnkr_interlocks year_std if sector == "RR", mc(white) msym(O))
   (scatter mean_tot_interlocks year_std if sector == "RR", mc(black) msym(Oh))
   (scatter mean_tot_bnkr_interlocks year_std if sector == "RR", mc(gs7) msym(Oh)),
 legend(order(1 "Total Interlocks" 2 "Total Interlocks by Banker-Directors"))
 title(Mean Interlocks among Boards of Railroads) xti("") yti("")
	/*note("Note: The number of total interlocks would count two mutual directors")
	note("of firm A and firm B as two interlocks, even though both interlocks")
	note("indicate a single relationship between firms.")*/;
graph export "`plot_dir'g4a_mn_tot_vs_bnkr_interlocks_ts_RRs.png", `png_ops';

tw (line mean_tot_interlocks year_std if sector == "Ind", lc(black) lp(_))
   (line mean_tot_bnkr_interlocks year_std if sector == "Ind", lc(gs7) lp(_))
   (scatter mean_tot_interlocks year_std if sector == "Ind", mc(white) msym(O))
   (scatter mean_tot_bnkr_interlocks year_std if sector == "Ind", mc(white) msym(O))
   (scatter mean_tot_interlocks year_std if sector == "Ind", mc(black) msym(Oh))
   (scatter mean_tot_bnkr_interlocks year_std if sector == "Ind", mc(gs7) msym(Oh)),
 legend(order(1 "Total Interlocks" 2 "Total Interlocks by Banker-Directors"))
 title(Mean Interlocks among Boards of Industrials & Utilities Firms) xti("") yti("")
	/*note("Note: The number of total interlocks would count two mutual directors")
	note("of firm A and firm B as two interlocks, even though both interlocks")
	note("indicate a single relationship between firms.")*/;
graph export "`plot_dir'g4b_mn_tot_vs_bnkr_interlocks_ts_Inds.png", `png_ops';
};
if `run_5' == 1 {;
tw (line mean_unique_interlocks year_std if sector == "RR", lc(black) lp(l))
   (line mean_unique_banker_interlocks year_std if sector == "RR", lc(gs7) lp(l))
   (scatter mean_unique_interlocks year_std if sector == "RR", mc(white) msym(O))
   (scatter mean_unique_banker_interlocks year_std if sector == "RR", mc(white) msym(O))
   (scatter mean_unique_interlocks year_std if sector == "RR", mc(black) msym(Oh))
   (scatter mean_unique_banker_interlocks year_std if sector == "RR", mc(gs7) msym(Oh)),
 legend(order(1 "Unique Interlocks" 2 "Unique Interlocks by Banker-Directors"))
 title(Mean Interlocks among Boards of Railroads) xti("") yti("")
	/*note("Note: Whereas the number of total interlocks would count two mutual")
	note("directors of firm A and firm B as two interlocks, the number of")
	note("unique interlocks in that instance would be only one because it counts")
	note("the number of firm-level relationships.")*/;
graph export "`plot_dir'g5a_mn_unique_vs_bnkr_interlocks_ts_RRs.png", `png_ops';

tw (line mean_unique_interlocks year_std if sector == "Ind", lc(black) lp(_))
   (line mean_unique_banker_interlocks year_std if sector == "Ind", lc(gs7) lp(_))
   (scatter mean_unique_interlocks year_std if sector == "Ind", mc(white) msym(O))
   (scatter mean_unique_banker_interlocks year_std if sector == "Ind", mc(white) msym(O))
   (scatter mean_unique_interlocks year_std if sector == "Ind", mc(black) msym(Oh))
   (scatter mean_unique_banker_interlocks year_std if sector == "Ind", mc(gs7) msym(Oh)),
 legend(order(1 "Unique Interlocks" 2 "Unique Interlocks by Banker-Directors"))
 title(Mean Interlocks among Boards of Industrials & Utilities Firms)
 xti("") yti("") ylab(0(5)15)
	/*note("Note: Whereas the number of total interlocks would count two mutual")
	note("directors of firm A and firm B as two interlocks, the number of")
	note("unique interlocks in that instance would be only one because it counts")
	note("the number of firm-level relationships.")*/;
graph export "`plot_dir'g5b_mn_unique_vs_bnkr_interlocks_ts_Inds.png", `png_ops';
};
/*
if `run_4' == 1 & `run_5' == 1 {
tsline mean_tot_bnkr_interlocks mean_tot_interlocks, ///
	graphregion(color(white)) bgcolor(white) ///
	lp(solid solid solid solid solid dash dash) ///
	title(Total Interlocks & Total Banker-Facilitated Interlocks) ///
	lc(green midblue) by(sector)
graph export "`plot_dir'g4-5_bnkr_vs_tot_interlocks_ts_bysector.png", `png_ops'
}
if `run_4' == 1 & `run_6' == 1 {
tsline mean_unique_interlocks mean_tot_interlocks, ///
	graphregion(color(white)) bgcolor(white) ///
	lp(solid solid solid solid solid dash dash) ///
	title(Unique and Total Interlocks w/ Other `Companies') ///
	lc(green midblue) by(sector)
graph export "`plot_dir'g4-6_un_vs_tot_interlocks_ts_bysector.png", `png_ops'
}
if `run_7' == 1 & `run_6' == 1 {
tsline mean_unique_banker_interlocks mean_unique_interlocks, ///
	graphregion(color(white)) bgcolor(white) ///
	lp(solid solid solid solid solid dash dash) ///
	title(Unique Interlocks & Unique Banker-Facilitated Interlocks) ///
	lc(green midblue) by(sector)
graph export "`plot_dir'g6-7_bnkr_vs_un_interlocks_ts_bysector.png", `png_ops'
}
*/
restore;

#delimit cr

} // end 4 - 5

********************************************************************************
if `run_6' == 1 {
********************************************************************************
foreach unique in "tot" "unique" {
    if "`unique'" == "tot" local ti "Total"
    if "`unique'" == "unique" local ti "Unique"
foreach ind in "" "_indtop10" {
	if "`ind'" == "" local subti "Top 10 Underwriters by Volume"
	if "`ind'" == "_indtop10" local subti "Top 10 Underwriters by Ind Board Seats"
	
	use "Thesis/Interlocks/interlocks_coded.dta", clear

	if "`unique'" == "unique" {
		replace banker`ind' = 0 if interlock == 0
		gen interlocks_same = same_ind * interlock
		gen interlocks_vert = v_possible * interlock
		gen interlocks_both = same_ind * v_possible * interlock
		gen bankers_same = same_ind * banker`ind'
		gen bankers_vert = v_possible * banker`ind'
		gen bankers_both = same_ind * v_possible * banker`ind'
	}
	else {
		replace n_bnkints`ind' = 0 if interlock == 0
		gen interlocks_same = same_ind * n_totints
		gen interlocks_vert = v_possible * n_totints
		gen interlocks_both = same_ind * v_possible * n_totints
		gen bankers_same = same_ind * n_bnkints`ind'
		gen bankers_vert = v_possible * n_bnkints`ind'
		gen bankers_both = same_ind * v_possible * n_bnkints`ind'
	}
	
	collapse (sum) interlocks_same interlocks_vert interlocks_both n_totints ///
					bankers_same bankers_vert bankers_both n_bnkints`ind', by(cidA cnameA year_std)
	
	gen interlocks_nr = n_totints - interlocks_same - interlocks_vert + interlocks_both
	gen bankers_nr = n_bnkints`ind' - bankers_same - bankers_vert + bankers_both
	
	collapse (mean) interlocks_same interlocks_vert interlocks_nr ///
					bankers_same bankers_vert bankers_nr, by(year_std)

	#delimit ;
	tw (line interlocks_same year_std, lc(black) lp(_))
	   (line bankers_same year_std, lc(gs7) lp(_))
	   (scatter interlocks_same year_std, mc(white) msym(O))
	   (scatter bankers_same year_std, mc(white) msym(O))
	   (scatter interlocks_same year_std, mc(black) msym(Oh))
	   (scatter bankers_same year_std, mc(gs7) msym(Oh)),
	  legend(order(1 "Interlocks" 2 "Banker Interlocks") r(1))
	  yti("") xti("") ti("Mean `ti' Interlocks in the Same Industry")
	  subti("`subti'");
	graph export "Gilded Age Boards/mean_interlocks_`unique'`ind'_same_ind.png",
				replace as(png) wid(1200) hei(800);
				
	tw (line interlocks_vert year_std, lc(black) lp(_))
	   (line bankers_vert year_std, lc(gs7) lp(_))
	   (scatter interlocks_vert year_std, mc(white) msym(O))
	   (scatter bankers_vert year_std, mc(white) msym(O))
	   (scatter interlocks_vert year_std, mc(black) msym(Oh))
	   (scatter bankers_vert year_std, mc(gs7) msym(Oh)),
	  legend(order(1 "Interlocks" 2 "Banker Interlocks") r(1))
	  yti("") xti("") ti("Mean `ti' Interlocks in a Vertical Industry")
	  subti("`subti'");
	graph export "Gilded Age Boards/mean_interlocks_`unique'`ind'_vertical.png",
				replace as(png) wid(1200) hei(800);
				
	tw (line interlocks_nr year_std, lc(black) lp(_))
	   (line bankers_nr year_std, lc(gs7) lp(_))
	   (scatter interlocks_nr year_std, mc(white) msym(O))
	   (scatter bankers_nr year_std, mc(white) msym(O))
	   (scatter interlocks_nr year_std, mc(black) msym(Oh))
	   (scatter bankers_nr year_std, mc(gs7) msym(Oh)),
	  legend(order(1 "Interlocks" 2 "Banker Interlocks") r(1))
	  yti("") xti("") ti("Mean `ti' Interlocks in Unrelated Industries")
	  subti("`subti'");
	graph export "Gilded Age Boards/mean_interlocks_`unique'`ind'_unrelated.png",
				replace as(png) wid(1200) hei(800);
	#delimit cr
}
*-----------------------------------------------------

use "Gilded Age Boards/rr_interlocks_coded.dta", clear

if "`unique'" == "unique" {
    replace banker = 0 if interlock == 0
	gen interlocks_same = same_reg * interlock
	gen interlocks_vert = oth_reg * interlock
	gen bankers_same = same_reg * banker
	gen bankers_vert = oth_reg * banker
}
else {
    replace n_bnkints = 0 if interlock == 0
	gen interlocks_same = same_reg * n_totints
	gen interlocks_vert = oth_reg * n_totints
	gen bankers_same = same_reg * n_bnkints
	gen bankers_vert = oth_reg * n_bnkints
}

collapse (sum) interlocks_same interlocks_vert bankers_same bankers_vert, ///
				by(cnameA year_std)
collapse (mean) interlocks_same interlocks_vert bankers_same bankers_vert, by(year_std)

#delimit ;
tw (line interlocks_same year_std, lc(black) lp(l))
   (line bankers_same year_std, lc(gs7) lp(l))
   (scatter interlocks_same year_std, mc(white) msym(O))
   (scatter bankers_same year_std, mc(white) msym(O))
   (scatter interlocks_same year_std, mc(black) msym(Oh))
   (scatter bankers_same year_std, mc(gs7) msym(Oh)),
  legend(order(1 "Interlocks" 2 "Banker Interlocks") r(1))
  yti("") xti("") ti("Mean `ti' RR Interlocks in the Same Region");
graph export "Gilded Age Boards/mean_rr_interlocks_`unique'_same_ind.png",
			replace as(png) wid(1200) hei(800);
tw (line interlocks_vert year_std, lc(black) lp(l))
   (line bankers_vert year_std, lc(gs7) lp(l))
   (scatter interlocks_vert year_std, mc(white) msym(O))
   (scatter bankers_vert year_std, mc(white) msym(O))
   (scatter interlocks_vert year_std, mc(black) msym(Oh))
   (scatter bankers_vert year_std, mc(gs7) msym(Oh)),
  legend(order(1 "Interlocks" 2 "Banker Interlocks") r(1))
  yti("") xti("") ti("Mean `ti' RR Interlocks in Other Regions");
graph export "Gilded Age Boards/mean_rr_interlocks_`unique'_vertical.png",
			replace as(png) wid(1200) hei(800);
#delimit cr
}
}

********************************************************************************
if `receiverships' == 1 {
********************************************************************************
import excel "receiverships count.xlsx", clear
ren A year
ren B receiverships

#delimit ;
tw (line receiverships year, lc(black) lp(line))
   (scatter receiverships year, mc(white) msym(O))
   (scatter receiverships year, mc(black) msym(Oh)),
 title("Receiverships among Railroad Firms") xti("") yti("")
 legend(off);
graph export "`plot_dir'receiverships_byYr.png", `png_ops';
#delimit cr
} // end receiverships


cd Thesis/Merges
********************************************************************************
if `prop_top10' == 1 {
********************************************************************************
import delimited "all_Puw_top10_bysector.csv", varn(1) clear

#delimit ;
tw (line puw year_std if sector == "RR", lc(black) lp(l))
   (line puw year_std if sector == "Ind", lc(black) lp(_))
   (scatter puw year_std if sector == "RR", mc(white) msym(O))
   (scatter puw year_std if sector == "Ind", mc(white) msym(O))
   (scatter puw year_std if sector == "RR", mc(black) msym(Oh))
   (scatter puw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Top 10 Underwriter by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_top10_uw_bysector.png", `png_ops';
#delimit cr

import delimited "all_Puw_top10_RRs.csv", varn(1) clear
tempfile rrs
save `rrs', replace

import delimited "all_Puw_top10_Inds.csv", varn(1) clear
append using `rrs'

#delimit ;
tw (line puw year_std if sector == "RR", lc(black) lp(l))
   (line puw year_std if sector == "Ind", lc(black) lp(_))
   (scatter puw year_std if sector == "RR", mc(white) msym(O))
   (scatter puw year_std if sector == "Ind", mc(white) msym(O))
   (scatter puw year_std if sector == "RR", mc(black) msym(Oh))
   (scatter puw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Top 10 Underwriter by Sector")
 xti("") yti("") ylab(0(0.2)1) subti("Separate Top 10 Lists by RRs & Inds")
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_top10_uw_separate.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_top25' == 1 {
********************************************************************************
import delimited "all_Puw_top25_bysector.csv", varn(1) clear

#delimit ;
tw (line puw year_std if sector == "RR", lc(black) lp(l))
   (line puw year_std if sector == "Ind", lc(black) lp(_))
   (scatter puw year_std if sector == "RR", mc(white) msym(O))
   (scatter puw year_std if sector == "Ind", mc(white) msym(O))
   (scatter puw year_std if sector == "RR", mc(black) msym(Oh))
   (scatter puw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Top 25 Underwriter by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_top25_uw_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_nyse' == 1 {
********************************************************************************
*import delimited "all_Puw_top10_bysector.csv", varn(1) clear
import delimited "all_Puw_top10_RRs.csv", varn(1) clear
tempfile rrs
save `rrs', replace
import delimited "all_Puw_top10_Inds.csv", varn(1) clear
append using `rrs'
tempfile top10
save `top10', replace

import delimited "P_all_nyse_partners.csv", varn(1) clear
ren puw puwAll
replace puwAll = . if year_std == 1880
merge 1:1 year_std sector using `top10'
sort year_std
drop if year_std == 1890

#delimit ;
tw (line puwAll year_std if sector == "RR", lc(black) lp(l))
   (line puwAll year_std if sector == "Ind", lc(black) lp(_))
   (scatter puwAll year_std if sector == "RR", mc(white) msym(O))
   (scatter puwAll year_std if sector == "Ind", mc(white) msym(O))
   (scatter puwAll year_std if sector == "RR", mc(black) msym(Oh))
   (scatter puwAll year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with Any Underwriter")
 xti("") yti("") ylab(0(0.2)1) subti("Separate Top 10 Lists by RRs & Inds")
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_any_NYSE_IB_parter_newtop10.png", `png_ops';

tw (line puwAll year_std if sector == "RR", lc(gs8) lp(l))
   (line puw year_std if sector == "RR", lc(black) lp(l))
   (scatter puwAll year_std if sector == "RR", mc(white) msym(O))
   (scatter puw year_std if sector == "RR", mc(white) msym(O))
   (scatter puwAll year_std if sector == "RR", mc(gs8) msym(Oh))
   (scatter puw year_std if sector == "RR", mc(black) msym(Oh)),
 title("Proportion of Railroads with a Banker-Director")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(2 "Top 10 Underwriter" 1 "Any NYSE Underwriter"));
graph export "`plot_dir'prop_firms_All_vs_top10_RR.png", `png_ops';

tw (line puwAll year_std if sector == "Ind", lc(gs8) lp(_))
   (line puw year_std if sector == "Ind", lc(black) lp(_))
   (scatter puwAll year_std if sector == "Ind", mc(white) msym(O))
   (scatter puw year_std if sector == "Ind", mc(white) msym(O))
   (scatter puwAll year_std if sector == "Ind", mc(gs8) msym(Oh))
   (scatter puw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Industrials & Utilities" "with a Banker-Director")
 xti("") yti("") ylab(0(0.2)1) subti("New Top 10 Banks for Industrials")
 legend(order(2 "Top 10 Underwriter" 1 "Any Underwriter"));
graph export "`plot_dir'prop_firms_All_vs_top10_Ind_newtop10.png", `png_ops';
#delimit cr
}
********************************************************************************
if `prop_CB' == 1 {
********************************************************************************
import delimited "all_Pcb_NY.csv", varn(1) clear

#delimit ;
tw (line pcb year_std if sector == "RR", lc(black) lp(l))
   (line pcb year_std if sector == "Ind", lc(black) lp(_))
   (scatter pcb year_std if sector == "RR", mc(white) msym(O))
   (scatter pcb year_std if sector == "Ind", mc(white) msym(O))
   (scatter pcb year_std if sector == "RR", mc(black) msym(Oh))
   (scatter pcb year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Commercial Banker by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_CBs_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_majCB' == 1 {
********************************************************************************
import delimited "major_Pcb_NY.csv", varn(1) clear

#delimit ;
tw (line pcb year_std if sector == "RR", lc(black) lp(l))
   (line pcb year_std if sector == "Ind", lc(black) lp(_))
   (scatter pcb year_std if sector == "RR", mc(white) msym(O))
   (scatter pcb year_std if sector == "Ind", mc(white) msym(O))
   (scatter pcb year_std if sector == "RR", mc(black) msym(Oh))
   (scatter pcb year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Major Commercial Banker by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_major_CBs_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_bigCB' == 1 {
********************************************************************************
import delimited "biggest_Pcb_NY.csv", varn(1) clear

drop if year_std < 1890
#delimit ;
tw (line pcb year_std if sector == "RR", lc(black) lp(l))
   (line pcb year_std if sector == "Ind", lc(black) lp(_))
   (scatter pcb year_std if sector == "RR", mc(white) msym(O))
   (scatter pcb year_std if sector == "Ind", mc(white) msym(O))
   (scatter pcb year_std if sector == "RR", mc(black) msym(Oh))
   (scatter pcb year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Director" "of One of the Biggest Commercial Banks" "by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_biggest_CBs_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_majCBxUW' == 1 {
********************************************************************************
import delimited "major_Pcbxuw_NY.csv", varn(1) clear

#delimit ;
tw (line pcbxuw year_std if sector == "RR", lc(black) lp(l))
   (line pcbxuw year_std if sector == "Ind", lc(black) lp(_))
   (scatter pcbxuw year_std if sector == "RR", mc(white) msym(O))
   (scatter pcbxuw year_std if sector == "Ind", mc(white) msym(O))
   (scatter pcbxuw year_std if sector == "RR", mc(black) msym(Oh))
   (scatter pcbxuw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms" "with a Major Non-Underwriter Commercial Banker" "by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_major_CBs_exUWs_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_bigCBxUW' == 1 {
********************************************************************************
import delimited "biggest_Pcb_NY_exUWs.csv", varn(1) clear

#delimit ;
tw (line pcb year_std if sector == "RR", lc(black) lp(l))
   (line pcb year_std if sector == "Ind", lc(black) lp(_))
   (scatter pcb year_std if sector == "RR", mc(white) msym(O))
   (scatter pcb year_std if sector == "Ind", mc(white) msym(O))
   (scatter pcb year_std if sector == "RR", mc(black) msym(Oh))
   (scatter pcb year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Director" "of One of the Biggest Commercial Banks" "(Excluding Underwriters) by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_biggest_CBs_exUWs_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_majUW' == 1 {
********************************************************************************
import delimited "major_Puw_NY.csv", varn(1) clear

#delimit ;
tw (line puw year_std if sector == "RR", lc(black) lp(l))
   (line puw year_std if sector == "Ind", lc(black) lp(_))
   (scatter puw year_std if sector == "RR", mc(white) msym(O))
   (scatter puw year_std if sector == "Ind", mc(white) msym(O))
   (scatter puw year_std if sector == "RR", mc(black) msym(Oh))
   (scatter puw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Major Investment Banker by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_major_UWs_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_GFB' == 1 {
********************************************************************************
import delimited "Thesis/Merges/Pgfb.csv", varn(1) clear

#delimit ;
tw (line pgfb year_std if sector == "RR", lc(black) lp(l))
   (line pgfb year_std if sector == "Ind", lc(black) lp(_))
   (scatter pgfb year_std if sector == "RR", mc(white) msym(O))
   (scatter pgfb year_std if sector == "Ind", mc(white) msym(O))
   (scatter pgfb year_std if sector == "RR", mc(black) msym(Oh))
   (scatter pgfb year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with George F Baker by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_GFB_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_JayCooke' == 1 {
********************************************************************************
import delimited "Thesis/Merges/all_Puw_JayCooke_bysector.csv", varn(1) clear

#delimit ;
tw (line puw year_std if sector == "RR", lc(black) lp(l))
   (line puw year_std if sector == "Ind", lc(black) lp(_))
   (scatter puw year_std if sector == "RR", mc(white) msym(O))
   (scatter puw year_std if sector == "Ind", mc(white) msym(O))
   (scatter puw year_std if sector == "RR", mc(black) msym(Oh))
   (scatter puw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with an Early Underwriter by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_early_uw_bysector.png", `png_ops';
#delimit cr
}

********************************************************************************
if `prop_top10_plus_early' == 1 {
********************************************************************************
import delimited "all_Puw_top10_plus_early_bysector.csv", varn(1) clear

#delimit ;
tw (line puw year_std if sector == "RR", lc(black) lp(l))
   (line puw year_std if sector == "Ind", lc(black) lp(_))
   (scatter puw year_std if sector == "RR", mc(white) msym(O))
   (scatter puw year_std if sector == "Ind", mc(white) msym(O))
   (scatter puw year_std if sector == "RR", mc(black) msym(Oh))
   (scatter puw year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Proportion of Firms with a Top 10 or Early Underwriter by Sector")
 xti("") yti("") ylab(0(0.2)1)
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'prop_firms_w_top10_or_early_uw_bysector.png", `png_ops';
#delimit cr
}
********************************************************************************
if `assets' == 1 {
********************************************************************************
cap cd "C:\Users\lmostrom\Documents\PersonalResearch\"

use "assets.dta", clear
replace assets = assets/1000000

collapse (median) med_assets = assets (mean) avg_assets = assets ///
		 (sum) tot_assets = assets, by(year_std sector)
lab var med_assets "Median Assets (Millions)"
lab var avg_assets "Average Assets (Millions)"
replace tot_assets = tot_assets/1000
lab var tot_assets "Total Assets (Billions)"
		 
#delimit ;
tw (line med_assets year_std if sector == "RR", lc(black) lp(l))
   (line med_assets year_std if sector == "Ind", lc(black) lp(_))
   (scatter med_assets year_std if sector == "RR", mc(white) msym(O))
   (scatter med_assets year_std if sector == "Ind", mc(white) msym(O))
   (scatter med_assets year_std if sector == "RR", mc(black) msym(Oh))
   (scatter med_assets year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Median Assets (Millions)")
 xti("") yti("")
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'assets_med_bysector.png", `png_ops';

tw (line avg_assets year_std if sector == "RR", lc(black) lp(l))
   (line avg_assets year_std if sector == "Ind", lc(black) lp(_))
   (scatter avg_assets year_std if sector == "RR", mc(white) msym(O))
   (scatter avg_assets year_std if sector == "Ind", mc(white) msym(O))
   (scatter avg_assets year_std if sector == "RR", mc(black) msym(Oh))
   (scatter avg_assets year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Average Assets (Millions)")
 xti("") yti("")
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'assets_avg_bysector.png", `png_ops';

tw (line tot_assets year_std if sector == "RR", lc(black) lp(l))
   (line tot_assets year_std if sector == "Ind", lc(black) lp(_))
   (scatter tot_assets year_std if sector == "RR", mc(white) msym(O))
   (scatter tot_assets year_std if sector == "Ind", mc(white) msym(O))
   (scatter tot_assets year_std if sector == "RR", mc(black) msym(Oh))
   (scatter tot_assets year_std if sector == "Ind", mc(black) msym(Oh)),
 title("Total Assets (Billions)")
 xti("") yti("")
 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
graph export "`plot_dir'assets_tot_bysector.png", `png_ops';
#delimit cr
}
********************************************************************************
if `ngram' == 1 {
********************************************************************************
import delimited ngram year mentions using ///
	"googlebooks-eng-all-1gram-20120701-f.txt", clear

replace ngram = lower(ngram)
keep if ngram == "financialization"
keep if inrange(year, 1880, 2010)

collapse (sum) mentions, by(ngram year)
save "googlebooks_ngram_financialization.dta", replace
*--------------------------------------------------
import delimited ngram year mentions using ///
	"googlebooks-eng-all-2gram-20120701-ba.txt", clear

replace ngram = lower(ngram)
keep if ngram == "bank control"
keep if inrange(year, 1880, 2010)

collapse (sum) mentions, by(ngram year)
save "googlebooks_ngram_bank_control.dta", replace
*--------------------------------------------------
import delimited ngram year mentions using ///
	"googlebooks-eng-all-2gram-20120701-fi.txt", clear

replace ngram = lower(ngram)
keep if inlist(ngram, "finance capitalism", "financial oligarchy")
keep if inrange(year, 1880, 2010)

collapse (sum) mentions, by(ngram year)
save "googlebooks_ngram_finance_capitalism_financial_oligarchy.dta", replace
*-------------------------------------------------------------------------------
append using "googlebooks_ngram_financialization.dta"
append using "googlebooks_ngram_bank_control.dta"

encode ngram, replace

}








