/*
Ind_banker_join_regs.do

*/

clear all
cap log close
pause on


cap cd "C:\Users\lmostrom\Documents\Gilded Age Boards - Scratch\"
cap cd "C:\Users\17036\Dropbox\Personal Document Backup\Gilded Age Boards - Scratch\"
global repo "C:/Users/17036/OneDrive/Documents/GitHub/gilded_age_boards"


*%%Prep Underwriter/CB Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use "Thesis/Merges/UW_1880-1920_top10.dta", clear
egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname bankname
tempfile top10uw
save `top10uw', replace

*%%Prep Industrials Assets Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use "Data/assets_ind.dta", clear
keep if year_std == 1900
keep cname assets
tempfile assets
save `assets', replace

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

use fullname_m cname year_std director id_add using "Thesis/Merges/Ind_boards_wtitles.dta", clear
keep if director == 1
ren id_add id
	
merge m:1 fullname_m year_std using `top10uw', keep(1 3) keepus(bankname)
gen top10uw = _merge == 3

collapse (count) boardsize = _merge ///
		 (max) has_top10uw = top10uw (sum) n_top10uw = top10uw, by(id cname year_std) 

reshape wide has_top10uw n_top10uw boardsize, i(cname id) j(year_std)
keep if has_top10uw1900 != . & has_top10uw1910 != .
keep cname id *1900 *1910
gen added_banker = has_top10uw1910 if has_top10uw1900 == 0
gen n_added_bankers = n_top10uw1910 - n_top10uw1900

merge 1:1 cname using `assets', nogen keep(1 3)

lab var added_banker "1 if has a top10 UW in 1910 among those without one in 1890"
lab var n_added_bankers "= n_top10uw1910 - n_top10uw1890"

save "Data/Ind_bankers_1890-1910.dta", replace