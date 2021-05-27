/*
all_nyse_partners_append.do

*/
cap cd "C:/Users/lmostrom/Documents/PersonalResearch/Gilded Age Boards/"

import excel "../NYSE 1883.xlsx", clear first case(lower)
	replace first = "N" ///
			if first == "" & firmname == "Thouron, N., & Co (Philadelphia)"
	replace last = "Thouron" ///
			if last == "" & firmname == "Thouron, N., & Co (Philadelphia)"
	replace last = "Kuhn" if last == "Kuhn, of Frank fort-on-the-Main"
	replace last = proper(last)
	ren firmname cname
gen fullname_m = substr(first,1,1) + substr(middle,1,1) + last + suffix
	drop if fullname_m == "Bk of Com & Ind'ty Darmstadt"
replace fullname_m = subinstr(fullname_m," ","",.)
gen year_std = 1885
tempfile nyse1885
save `nyse1885', replace

import excel "../NYSE 1895.xlsx", clear first case(lower)
	ren firmname cname
	replace last = proper(last)
gen fullname_m = substr(first,1,1) + substr(middle,1,1) + last + suffix
replace fullname_m = subinstr(fullname_m," ","",.)
gen year_std = 1895
tempfile nyse1895
save `nyse1895', replace

use "CB_1880-1920_NY.dta", clear
	keep if inlist(cname, "Farmers Loan & Trust Co", ///
		"Equitable Trust Co", "Bankers Trust Co")
tempfile bef
save `bef', replace
	
use "../IB_clean.dta", clear
	replace last = proper(last)
	replace last = "Trask" if last == "Trash" & first == "Wayland"
		replace fullname_m = "WTrask" if fullname_m == "WTrash"
	gen year_std = year
		replace year_std = 1905 if year == 1906

/* Joining to see where names don't quite match
joinby fullname_m using `nyse1885', unm(both) _merge(_m85)
	replace last = last85 if last == ""
joinby fullname_m using `nyse1895', unm(both) _merge(_m95)
	replace last = last95 if last == ""
*/
append using `nyse1885'
append using `nyse1895'
append using `bef'
append using "UW_1880-1920_top25.dta"

replace fullname_m = subinstr(fullname_m, "_s", "", 1)
replace fullname_m = subinstr(fullname_m," ","",.)

keep fullname_m year_std cname
duplicates drop

save "UW_1880-1920_allnyse.dta", replace