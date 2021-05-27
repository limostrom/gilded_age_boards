/*
director_comp_stats.do

- A 1/0 variable for whether they had a top underwriter on their board in 1900, and in 1910
- A count of the top underwriters on their board in 1900 and 1910
- The number of additional directorships held by the board members (total, and average), for 1900 and 1910
- The share of the board that holds at least one additional directorship, for 1900 and 1910
- Maybe some kind of measure of super prestigious / prominent directors - 
	people who hold like 5 directorships - maybe the count of those on the board in 1900 and 1910

*/

*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use "UW_1880-1920_top10.dta", clear

egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname bankname

tempfile temp_uw
save `temp_uw', replace

*%%Load Railroad or Industrials Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use year_std cname fullname_m director sector cid ///
	using "Railroad_boards_final.dta", clear
append using "IndUtil_boards_final.dta", ///
	keep(year_std cname fullname_m director sector cid)

	
assert fullname_m != ""
keep if director == 1

*===============================================================================
* Calculating stats of prominent directors on boards
*===============================================================================

merge m:1 fullname_m year_std using `temp_uw', keep(1 3) keepusing(bankname)
gen banker = _merge == 3


keep if inlist(year_std, 1900, 1910)
	bys cname sector: egen minyr = min(year_std)
	drop if minyr == 1910
	drop minyr
bys year_std fullname_m: gen oth_directorships = _N - 1
gen has_oth_dir = oth_directorships > 0
gen has_10_oth_dirs = oth_directorships >= 10
gen has_5_oth_dirs = oth_directorships >= 5

#delimit ;
collapse (sum) n_top10uws = banker (max) has_top10uw = banker
		 (sum) n_oth_dirs = oth_directorships
		 (mean) avg_oth_dirs = oth_directorships pct_w_oth_dirs = has_oth_dir
		 (sum) n_dirs_w10_oth = has_10_oth_dirs n_dirs_w5_oth = has_5_oth_dirs
		 (count) n_directors = _merge, by(sector cid cname year_std);
#delimit cr


lab var n_top10uws "No. of Top 10 UWs on the board"
lab var has_top10uw "Indicator for whether there's a top 10 UW on the board"
lab var n_oth_dirs "Total number of other directorships held by directors"
lab var avg_oth_dirs "Avg. number of other directorships held by directors"
lab var pct_w_oth_dirs "Proportion of directors with other directorships"
lab var n_dirs_w10_oth "Number of directors with at least 10 other directorships"
lab var n_dirs_w5_oth "Number of directors with at least 5 other directorships"
lab var n_directors "Number of directors"

save "board_composition_vars.dta", replace


