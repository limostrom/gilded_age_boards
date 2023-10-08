/*
RR_banker_join_regs.do

*/


clear all
cap log close
pause on


cap cd "C:\Users\lmostrom\Documents\Gilded Age Boards - Scratch\"
cap cd "C:\Users\17036\Dropbox\Personal Document Backup\Gilded Age Boards - Scratch\"
cap cd "/Users/laurenmostrom/Dropbox/Personal Document Backup/Gilded Age Boards - Scratch/"
global repo "/Users/laurenmostrom/Documents/GitHub/gilded_age_boards"



*%%Prep Underwriter/CB Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use "Thesis/Merges/UW_1880-1920_top10.dta", clear
egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname bankname
tempfile top10uw
save `top10uw', replace

*%%Prep Standardized RR Names to Merge In %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import delimited "Data/RR_names_years_corrected.csv", clear varn(1)

tempfile stn_cnames
save `stn_cnames', replace


*%%Prep RR 1890 Accounting Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
include $repo/RR_acct_1890_data_prep.do

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

use year_std cname fullname_m director using "Thesis/Merges/RR_boards_wtitles.dta", clear
	drop if cname == "KEOKUK AND DES MOINES RAILROAD" & year_std == 1890 // duplicate
	keep if director == 1
merge m:1 cname year_std using `stn_cnames', keep(3) nogen
	egen id = group(cname_stn)
	

merge m:1 fullname_m year_std using `top10uw', keep(1 3) keepus(bankname)
gen top10uw = _merge == 3

collapse (count) boardsize = _merge ///
		 (max) has_top10uw = top10uw (sum) n_top10uw = top10uw, by(id cname_stn year_std) 

reshape wide has_top10uw n_top10uw boardsize, i(cname_stn id) j(year_std)
keep if has_top10uw1890 != . & has_top10uw1910 != .
keep cname_stn id *1890 *1910
gen added_banker = has_top10uw1910 if has_top10uw1890 == 0
gen n_added_bankers = n_top10uw1910 - n_top10uw1890

merge 1:1 cname_stn using `acct1890', keep(1 3) nogen

lab var added_banker "1 if has a top10 UW in 1910 among those without one in 1890"
lab var n_added_bankers "= n_top10uw1910 - n_top10uw1890"

save "Data/RR_bankers_1890-1910.dta", replace
