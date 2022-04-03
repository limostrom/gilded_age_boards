/*
ind_banker_pairs.do

*/
cd "C:/Users/lmostrom/Documents/PersonalResearch/Gilded Age Boards"

local fullset 1 // 0=bankers that ever joined a board, 1=all bankers

*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use year_std fullname_m cname using "UW_1880-1920_allnyse.dta", clear
rename cname bankname

if `fullset' == 1 levelsof fullname_m, local(bankers)

tempfile temp_uw
save `temp_uw', replace

if `fullset' == 0 {
	*%%Load Railroad Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std cname fullname_m director using "Ind_boards_wtitles.dta", clear
	append using "Util_boards_final.dta", keepus(year_std cname fullname_m director)
	keep if director == 1
	drop director

	*Identify bankers ever on an indstrial board 1890-1910
	joinby year_std fullname_m using `temp_uw', unm(none) _merge(m_uws)
	keep fullname_m
	duplicates drop

	levelsof fullname_m, local(bankers)
}
*===============================================================================
forval ystart = 1895(5)1915 {
	local y5 = `ystart' + 5
	
	*Keep firms that were there in 1900
	use year_std cname fullname_m director using "Ind_boards_wtitles.dta", clear
	append using "Util_boards_final.dta", keepus(year_std cname fullname_m director)
	keep if director == 1
	drop director
	keep if year_std == `ystart'
	levelsof cname, local(RRs)

	drop *
	gen cname = ""
	gen fullname_m = ""
	foreach i of local RRs {
		foreach j of local bankers {
			local n = _N
			local ++n
			set obs `n'
			
			replace cname = "`i'" if _n == _N
			replace fullname_m = "`j'" if _n == _N
		}
	}

	tempfile all_pairs
	save `all_pairs', replace

	*%%Generate Actual Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std cname fullname_m director using "Ind_boards_wtitles.dta", clear
	append using "Util_boards_final.dta", keepus(year_std cname fullname_m director)
	keep if director == 1
	drop director
	keep if inlist(year_std, `ystart', `y5')

	bys cname (year_std): egen minyr = min(year_std)
	drop if minyr == `y5'
	drop minyr
	bys cname (year_std): egen maxyr = max(year_std)
	drop if maxyr == `ystart'
	drop maxyr

	preserve
		keep if year_std == `ystart'
		drop year_std
		duplicates drop
		tempfile dirs`ystart'
		save `dirs`ystart'', replace
	restore

	keep if year_std == `y5'
	drop year_std
		duplicates drop
		tempfile dirs`y5'
		save `dirs`y5'', replace

	use `all_pairs', clear
	merge 1:1 cname fullname_m using `dirs`ystart'', keep(1 3) gen(_m`ystart')
	merge 1:1 cname fullname_m using `dirs`y5'', keep(1 3) gen(_m`y5')

	drop if _m`ystart' == 3
	gen joinedboard = (_m`y5' == 3 & _m`ystart' == 1)
		lab var joinedboard "This banker joined this board between `ystart' and `y5'"
	order cname fullname_m joinedboard

	if `fullset' == 1 save "ind_banker_pairs_fullset_`ystart'-`y5'.dta", replace
	else save "ind_banker_pairs_`ystart'-`y5'.dta", replace
}