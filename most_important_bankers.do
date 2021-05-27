/*
most_important_bankers.do

*/
clear all
cap log close
pause on

use "CB_1880-1920_NY.dta", clear

preserve
	collapse (count) n_boards = year, by(fullname_m year_std)
	pause
restore