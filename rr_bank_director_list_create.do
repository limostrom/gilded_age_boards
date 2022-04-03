/*
rr_bank_director_list_create.do

*/

global repo "C:\Users\17036\OneDrive\Documents\GitHub\gilded_age_boards"
cap cd "C:\Users\17036\Dropbox\Personal Document Backup\Gilded Age Boards\"

use year_std fullname_m cname using "Data/UW_1880-1920_allnyse.dta", clear
drop if fullname_m == ""
rename cname bank
bys fullname_m year_std: gen n = _n
reshape wide bank, i(fullname_m year_std) j(n)
tempfile tempNYSE
save `tempNYSE', replace

use year_std fullname_m cname using "Data/RR_boards_wtitles.dta", clear
assert fullname_m != ""
merge m:1 fullname_m year_std using `tempNYSE', nogen keep(1 3)

keep if year_std > 1900
sort year_std cname fullname_m

save "Notes/rr_bank_director_list.dta", replace