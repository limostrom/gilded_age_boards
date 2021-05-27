/*
Lauren Mostrom
Tables of receivership & which firms did not survive 1890-1910
	based (i) interlocks with the biggest NY commercial banks
	and (ii) that banker's primary business affiliation
*/

clear all
cap log close
set more off
pause on

cap cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Regressions"
cap cd "C:\Users\lmostrom\Documents\PersonalResearch\"

*******************************************************************************;
import excel "RR_Addenda_Accounting.xlsx", first
save "RR_Addenda_Accounting.dta", replace

clear all
import excel "RR_Addenda_Accounting-died.xlsx", first
save "RR_Addenda_Accounting-died.dta", replace

append using RR_Addenda_Accounting
save RR_Financials1890, replace

use acctgdat, clear
keep if year == 1910
keep cname RRid year assets lassets q bvlev bfdebt3 surplus3
save RR_Addenda_Accounting_1910, replace
*******************************************************************************;

use "Thesis/Merges/CB_1880-1920_NY.dta", clear
#delimit ;
keep if inlist(cname, "National Bank of Commerce",
						"National Park", "National Park Bank",
						"Hanover National", "Hanover National Bank",
						"Chase National", "Chase National Bank",
						"Western National", "Western National Bank")
		| inlist(cname, "Importers & Traders National",
							"Importers & Traders Nat. Bank",
						"Chemical National", "Chemical National Bank",
						"Fourth National", "Fourth National Bank",
						"Bank of the Manhattan Co", "Bank of America");
#delimit cr
tempfile bigCBs
save `bigCBs', replace

use "All_1880-1920_clean.dta", clear
	include clean_full_dir_list.do

joinby fullname_m year_std using `bigCBs', unm(master)

preserve
	import excel "Thesis/Merges/biggest_CB_NY_interlock_names.xlsx", first clear
	keep fullname_m prim_ind classification_rule
	duplicates drop
	isid fullname_m
	tempfile prim
	save `prim', replace
restore

merge m:1 fullname_m using `prim', keep(1 3) gen(_mprimary)

gen cb = _merge == 3
gen notcb = _merge == 1

replace prim_ind = "" if notcb
replace prim_ind = subinstr(prim_ind, "/", "", .)
tab prim_ind, gen(prim)
	drop prim_ind
	ren prim1 primCB
	ren prim2 primCap
	ren prim3 primIB
	ren prim4 primInd
	ren prim5 primLand
	ren prim6 primLaw
	ren prim7 primMB
	ren prim8 primRR
	ren prim9 primTI


collapse (sum) cb prim* notcb (first) cname, by(firmid year_std sector cohort)

foreach var of varlist cb prim* {
	gen P`var' = `var' > 0 & `var' != .
	bys year_std sector cohort: summ P`var'
}

drop notcb
bys firmid: ereplace cname = mode(cname)
reshape wide Pcb cb Pprim* prim*, i(firmid sector cohort cname) j(year_std)

foreach var in cb primCB primCap primIB primInd ///
	primLand primLaw primMB primRR primTI  {
	gen acq`var' = (P`var'1910 - P`var'1890 == 1)
	gen Nacq`var' = `var'1910 - `var'1890
}

*COMMERCIAL BANKERS - Decomposition of Changes
log using "table_by_prim_aff.txt", text replace
bys sector: summ Pcb1890 // 23/104 RRs, 6/15 Inds w/ big CB in 1890
foreach var of varlist Pprim*1890 {
	dis "RR"
		summ `var' if sector == "RR"
			dis `r(mean)'*`r(N)'
	dis "Ind"
		summ `var' if sector == "Ind"
			dis `r(mean)'*`r(N)'
}
bys sector: summ Pcb1910 // 49/71 RRs, 57/123 Inds w/ CB in 1910
foreach var of varlist Pprim*1910 {
	dis "RR"
		summ `var' if sector == "RR"
			dis `r(mean)'*`r(N)'
	dis "Ind"
		summ `var' if sector == "Ind"
			dis `r(mean)'*`r(N)'
}
log close

/*
*UNDERWRITERS - Decomposition of changes;
summ Puw1890;
*proportion with a top 10 underwriter in 1890 = 22/104;
*proportion with a top 25 underwriter in 1890 = 30/104;
summ Puw1910;
*proportion with a top 10 underwriter in 1910 = 45/71;
*proportion with a top 25 underwriter in 1910 = 53/71;
*/

gen new = (cohort > 1890) if Pcb1910 != .
gen survived = Pcb1910 != .	if inlist(cohort, 1880, 1890)

log using "table_by_prim_aff.txt", text append

	foreach var in cb primCB primCap primIB primInd ///
			primLand primLaw primMB primRR primTI  {
		foreach sec in RR Ind {
			dis "`sec'"
			tab P`var'1890 P`var'1910 if sector == "`sec'"
			tab P`var'1890 survived if sector == "`sec'"

			tab P`var'1910 new if sector == "`sec'"
		}
	}

	foreach var in cb primCB primCap primIB primInd ///
			primLand primLaw primMB primRR primTI  {
		foreach sec in RR Ind {
			dis "`sec'"
			tab P`var'1890 P`var'1910 if sector == "`sec'"
			tab P`var'1910 if Pcb1890 == . & sector == "`sec'"

			tab `var'1890 if sector == "`sec'"
			tab `var'1910 if sector == "`sec'"

			tab Nacq`var' if sector == "`sec'"
			tab `var'1910 if cb1890 == . & sector == "`sec'"
		}
	}
log close



pause
*******************************************************************************;
/*
In 1910 (Top 10 Underwriters):
-proportion w/ a top 10 underwriter in 1890: 22/104
-proportion w/ a top 10 underwriter in 1910: 45/71

(+) New RRs w/ bankers: 13
(+) Old RRs adding bankers: 20
(+) Old RRs w/o bankers disappearing: 46
(-) Old RRs w/ bankers disappearing: 10
(-) New RRs w/o bankers appearing: 10

In 1910 (Top 25 Underwriters):
-proportion w/ a top 25 underwriter in 1890: 31/104
-proportion w/ a top 25 underwriter in 1910: 53/71

(+) New RRs w/ bankers: 16
(+) Old RRs adding bankers: 20
(+) Old RRs w/o bankers disappearing: 42
(-) Old RRs w/ bankers disappearing: 14
(-) New RRs w/o bankers appearing: 7
*/
****************************************************************************;
* MERGING IN 1910 ACCOUNTING DATA;
****************************************************************************;
/*
keep if Puw1910 != .;
merge 1:1 RRid using RR_Addenda_Accounting_1910, keep(1 3);

#delimit;
reg Puw1910 lassets, robust;
reg Puw1910 lassets q bvlev, robust;
*reg Puw1910 lassets q leverage S W cohort1890, robust;
*/
****************************************************************************;
* MERGING IN 1890 ACCOUNTING DATA;
****************************************************************************;

#delimit ;

keep if Puw1890 != .;
merge 1:1 RRid using "RR_Financials1890.dta", keep(1 3);

gen rcvr_1880s = (receivership >= 1880 & receivership < 1890);
replace rcvr_1880s = 0 if rcvr_1880s == .;
gen rcvr_1890s = (receivership >= 1890 & receivership < 1910);
replace rcvr_1890s = 0 if rcvr_1890s == .;

gen tobinsQ = (marketcap + totassets - comstock - surplus)/totassets;
gen leverage = totdebt/totassets;
gen logassets = ln(totassets);

*omit 1880;
gen cohort1890 = (cohort == 1890);
*omit Northern region;
gen S = (region == "S");
gen W = (region == "W");
/*
keep if flag_acctng != 1;

reg survived Puw1890, robust;
reg survived Puw1890 logassets, robust;
reg survived Puw1890 logassets tobinsQ leverage, robust;
reg survived Puw1890 S W cohort1890, robust;
reg survived Puw1890 logassets tobinsQ leverage S W cohort1890, robust;

reg Puw1890 logassets, robust;
reg Puw1890 logassets tobinsQ leverage, robust;
reg Puw1890 logassets tobinsQ leverage S W cohort1890, robust;



reg rcvr_1890s Puw1890, robust;
*est store reg1a;
reg rcvr_1890s Puw1890 logassets tobinsQ leverage, robust;
*est store reg1b;
reg rcvr_1890s Puw1890 logassets tobinsQ leverage S W cohort1890, robust;
*est store reg1c;

*est table reg1*, star(0.10 0.05 0.01) b(%9.4f);

reg Puw1890 logassets tobinsQ leverage, robust;
*est store reg2a;
reg Puw1890 logassets tobinsQ leverage S W cohort1890, robust;
*est store reg2b;

*est table reg2*, star(0.10 0.05 0.01) b(%9.4f);
/*
keep if Puw1890 == 0 & Puw1910 != .;


summ receivership S W cohort1890 totassets tobinsQ leverage, separator(4);

reg acquiredUW receivership, robust;
*est store reg3a;
reg acquiredUW receivership S W cohort1890, robust;
*est store reg3b;
reg acquiredUW receivership logassets tobinsQ leverage, robust;
*est store reg3c;
reg acquiredUW receivership S W cohort1890 logassets tobinsQ leverage, robust;
*est store reg3d;

*est table reg3*, star(0.10 0.05 0.01) b(%9.4f);

reg numacquiredUWs receivership;
*est store reg4a;
reg numacquiredUWs receivership S W cohort1890;
*est store reg4b;
reg numacquiredUWs receivership logassets tobinsQ leverage;
*est store reg4c;
reg numacquiredUWs receivership S W cohort1890 logassets tobinsQ leverage;
*est store reg4d;

*est table reg4*, star(0.10 0.05 0.01) b(%9.4f);
*/
