/*
top_bankers_industrials.do

*/


*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use year_std fullname_m cname using "UW_1880-1920_top10.dta", clear
include clean_banknames.do
duplicates drop
rename cname bank10_
tempfile temp10
save `temp10', replace

use year_std fullname_m cname using "UW_1880-1920_top25.dta", clear
include clean_banknames.do
duplicates drop
rename cname bank25_
tempfile temp25
save `temp25', replace

use year_std fullname_m cname using "UW_1880-1920_allnyse.dta", clear
include clean_banknames.do
duplicates drop
rename cname bankAll_
tempfile tempNYSE
save `tempNYSE', replace

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use `tempNYSE', clear
	duplicates drop
	

	joinby fullname_m year_std using "IndUtil_boards_final.dta", _merge(_m)
	keep bankAll_ fullname_m year_std cname bankname_stn
	duplicates drop

collapse (count) bank_boardseats = year_std, by(bankname_stn)
gsort -bank_boardseats

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use year_std fullname_m cname using "UW_1880-1920_allnyse.dta", clear
include clean_banknames.do
keep if inlist(bankname_stn, "BANKERS TRUST CO", "EQUITABLE TRUST CO", ///
		"FARMERS LOAN & TRUST CO", "FIRST NATIONAL", "GOLDMAN SACHS & CO", ///
		"GUARANTY", "HAYDEN STONE & CO", "LEE HIGGINSON & CO", ///
		"MORGAN J P & CO") | bankname_stn == "NATIONAL CITY"
save "UW_1880-1920_Indtop10.dta", replace