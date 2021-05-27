/*
banker_summ_stats.do

*/
* --- Prep Boards Datasets
use cname year_std fullname_m using "IndUtil_boards_final.dta", clear
	assert fullname_m != ""
	gen sector = "Ind"
append using "Railroad_boards_final.dta", keep(year_std fullname_m cname)
	replace sector = "RR" if sector == ""
duplicates drop
tempfile boards
save `boards', replace

use year_std fullname_m using "UW_1880-1920_allnyse.dta", clear
duplicates drop

merge 1:m year_std fullname_m using "UW_1880-1920_top10.dta", keepus(first)
	gen top10 = 0 if _merge == 1
	replace top10 = 1 if inlist(_merge, 2, 3)
	drop first _merge
duplicates drop

merge 1:m year_std fullname_m using "UW_1880-1920_top25.dta", keepus(first)
	gen top25 = 0 if _merge == 1
	replace top25 = 1 if inlist(_merge, 2, 3)
	drop first _merge
duplicates drop

joinby year_std fullname_m using `boards', unm(master)
keep if inlist(year_std, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920)
gen rank1_10 = top10 == 1
gen rank11_25 = top10 == 0 & top25 == 1

gen onboard = _merge == 3
gen onboard_rank1_10 = onboard if rank1_10
gen onboard_rank11_25 = onboard if rank11_25
gen onboard_other = onboard if !rank1_10 & !rank11_25

bys fullname_m year_std: gen numboards = _N
	replace numboards = . if numboards == 1 & !onboard
gen numboards_rank1_10 = numboards if top10 == 1
gen numboards_rank11_25 = numboards if top10 == 0 & top25 == 1
gen numboards_other = numboards if top10 == 0 & top25 == 0
	
foreach sec in "RR" "Ind" {
	gen onboard`sec' = onboard if sector == "`sec'"
	gen onboard`sec'_rank1_10 = onboard_rank1_10 if sector == "`sec'"
	gen onboard`sec'_rank11_25 = onboard_rank11_25 if sector == "`sec'"
	gen onboard`sec'_other = onboard_other if sector == "`sec'"
	
	gen numboards`sec' = numboards if sector == "`sec'"
	gen numboards`sec'_rank1_10 = numboards_rank1_10 if sector == "`sec'"
	gen numboards`sec'_rank11_25 = numboards_rank11_25 if sector == "`sec'"
	gen numboards`sec'_other = numboards_other if sector == "`sec'"
}


forval ystart = 1880(5)1920 {
	#delimit ;
	eststo summ_`ystart': estpost summ onboard onboard_rank1_10
						onboard_rank11_25 onboard_other
						onboardRR onboardRR_rank1_10
						onboardRR_rank11_25 onboardRR_other
						onboardInd onboardInd_rank1_10
						onboardInd_rank11_25 onboardInd_other if year_std == `ystart';
	eststo summ_cont_`ystart'`full': estpost summ  numboards numboards_rank1_10
						numboards_rank11_25 numboards_other
						numboardsRR numboardsRR_rank1_10
						numboardsRR_rank11_25 numboardsRR_other
						numboardsInd numboardsInd_rank1_10
						numboardsInd_rank11_25 numboardsInd_other if year_std == `ystart', d;
	#delimit cr
}

#delimit ;
esttab summ_???? using "banker_summs.csv", replace
	cells("count mean(fmt(4))") mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915")
	title("Banker-Level Summary Stats") note(" ");
	
esttab summ_cont_???? using "banker_summs.csv", append 
	mtitles("1880" "1885" "1890" "1895" "1900" "1905" "1910" "1915")
	cells("count mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))");
#delimit cr

