/*
Lauren Mostrom
Running the Regression / Cohort
*/

clear all
cap log close
set more off

cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Regressions"

#delimit ;

*******************************************************************************;

import excel "RR_Addenda_Accounting.xlsx", first;
save "RR_Addenda_Accounting.dta", replace;

clear all;
import excel "RR_Addenda_Accounting-died.xlsx", first;
save "RR_Addenda_Accounting-died.dta", replace;

append using RR_Addenda_Accounting;
save RR_Financials1890, replace;

use acctgdat, clear;
keep if year == 1910;
keep cname RRid year assets lassets q bvlev bfdebt3 surplus3;
save RR_Addenda_Accounting_1910, replace;

*******************************************************************************;

use "RR_1880-1920_clean.dta", clear;

local num = 10;

merge m:m fullname_m year_std using "UW_1880-1920_top`num'.dta", keep(1 3);

gen uw = _merge == 3;
gen nuw = _merge == 1;

collapse (sum) nuw uw, by(RRid year_std sector cohort);

gen Puw = uw > 0;
sort year_std sector cohort RRid;
*by year_std sector cohort: summ Puw;

reshape wide Puw nuw uw, i(RRid) j(year_std);

gen acquiredUW = (Puw1910 - Puw1890 == 1);
gen numacquiredUWs = uw1910 - uw1890;

*Decomposition of changes;
summ Puw1890;
*proportion with a top 10 underwriter in 1890 = 22/104;
*proportion with a top 25 underwriter in 1890 = 30/104;
summ Puw1910;
*proportion with a top 10 underwriter in 1910 = 45/71;
*proportion with a top 25 underwriter in 1910 = 53/71;

gen new = (cohort > 1890 | cohort == .);
gen survived = 1 if (cohort == 1880 | cohort == 1890) & Puw1910 != .;
replace survived = 0 if (cohort == 1880 | cohort == 1890) & Puw1910 == .;
/*
keep if Puw1890 != . | Puw1910 != .;

tab Puw1890 Puw1910;
tab Puw1890 survived;

tab Puw1910 if new == 1;
*/
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
