/*
10 most connected directors at 10-year intervals
10 most horizontal interlocks at 10-year intervals
*/


*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use "UW_1880-1920_top10.dta", clear

egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname bankname

tempfile temp_uw
save `temp_uw', replace

*%%Load Railroad or Industrials Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use year_std cname first fullname_m director sector cid ///
	using "Railroad_boards_final.dta", clear
append using "IndUtil_boards_final.dta", ///
	keep(year_std cname first fullname_m director sector cid)

keep if director == 1

gen id = _n

collapse (count) num_boards = id (first) first, by(fullname_m year_std sector)
replace sector = "IndUt" if sector == "Ind/Util"
reshape wide num_boards, i(first fullname_m year_std) j(sector) string
replace num_boardsIndUt = 0 if num_boardsIndUt == .
replace num_boardsRR = 0 if num_boardsRR == .
gen tot_boards = num_boardsRR + num_boardsIndUt

gsort year_std -tot_boards
drop if inlist(year_std, 1880, 1885, 1890, 1895) & tot_boards < 5
drop if inlist(year_std, 1900) & tot_boards < 6
drop if inlist(year_std, 1905) & tot_boards < 8
drop if inlist(year_std, 1910, 1915) & tot_boards < 9
drop if inlist(year_std, 1920) & tot_boards < 10

gsort year_std -tot_boards fullname_m
export delimited "most_connected_directors.csv", replace