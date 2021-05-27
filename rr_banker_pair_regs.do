/*
rr_banker_regs.do

*/
pause on

est clear


import excel "1900 RR Financial Data.xlsx", first clear
replace bills = 0 if bills == .
tempfile rrfin
save `rrfin', replace

foreach full in "" "_fullset" {
forval ystart = 1895(5)1915 {
	local y5 = `ystart' + 5
	
	*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std fullname_m cname using "UW_1880-1920_top10.dta", clear
	include clean_banknames.do
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank10_
	bys fullname_m year_std: gen n = _n
	reshape wide bank10_, i(fullname_m year_std) j(n)
	tempfile temp10
	save `temp10', replace

	use year_std fullname_m cname using "UW_1880-1920_top25.dta", clear
	include clean_banknames.do
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank25_
	bys fullname_m year_std: gen n = _n
	reshape wide bank25_, i(fullname_m year_std) j(n)
	tempfile temp25
	save `temp25', replace

	use year_std fullname_m cname using "UW_1880-1920_allnyse.dta", clear
	include clean_banknames.do
	keep if year_std == `ystart'
	duplicates drop
	rename cname bankAll_
	bys fullname_m year_std: gen n = _n
	reshape wide bankAll_, i(fullname_m year_std) j(n)
	tempfile tempNYSE
	save `tempNYSE', replace

	*%%Board Size%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std fullname_m cname using "Railroad_boards_final.dta", clear
	assert fullname_m != ""
	gen boardsize = 1
	collapse (sum) boardsize, by(cname year_std)
	tempfile boardsizes
	save `boardsizes', replace
	
	*%%Receivership%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	import excel "Receivership variable.xlsx", clear first
	drop if cname == "" & year_std == .
	isid cname year_std
	include harmonize_rr_names.do
	drop if year_std == 1890 & cname == "KEOKUK AND DES MOINES RAILROAD"
	replace receivership = 0 if receivership == .
	replace sub_receivership = 0 if sub_receivership == .
	tempfile receivership
	save `receivership', replace
	
	*%%Bankers on Boards%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std fullname_m cname using "UW_1880-1920_allnyse.dta", clear
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank_

	joinby fullname_m year_std using "Railroad_boards_final.dta", _merge(_m)
	keep bank_ fullname_m year_std cname
	duplicates drop

	include assign_regions.do

	bys fullname_m cname (bank_): gen repeat = _n - 1
	bys fullname_m repeat: gen boardseats_num = _N

	bys fullname_m region repeat: gen boardseats_samereg_num = _N
		gen boardseats_othreg_num = boardseats_num - boardseats_samereg_num
		gen boardseats_samereg_ind = boardseats_samereg_num > 0
		gen boardseats_othreg_ind = boardseats_othreg_num > 0
	keep fullname_m region boardseats_*
	duplicates drop
	isid fullname_m region
	tempfile banker_reg
	save `banker_reg', replace
	*---------------------------------------------------------------------------
	use year_std fullname_m cname using "UW_1880-1920_allnyse.dta", clear
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank_

	joinby fullname_m year_std using "Railroad_boards_final.dta", _merge(_m)
	keep bank_ fullname_m year_std cname
	duplicates drop

	include assign_regions.do
	
	bys bank_ cname: gen ownbankers_num = _N
		gen ownbankers_ind = ownbankers_num > 0
	egen tag_banker = tag(cname fullname_m)
	bys cname: egen totbankers_num = total(tag_banker)
		gen othbankers_num = totbankers_num - ownbankers_num
		gen othbankers_ind = othbankers_num > 0
	sort bank cname
	keep bank cname ???bankers_*
	duplicates drop
	isid bank cname
	tempfile bank_rr
	save `bank_rr', replace

	*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use "rr_banker_pairs`full'_`ystart'-`y5'.dta", clear

	gen year_std = `ystart'

	merge m:1 fullname_m year_std using `temp10', gen(_m10) keep(1 3) keepus(bank10_*)
		gen top10uw = _m10 == 3
	merge m:1 fullname_m year_std using `temp25', gen(_m25) keep(1 3) keepus(bank25_*)
		gen top25uw = _m25 == 3
	merge m:1 fullname_m year_std using `tempNYSE', gen(_mAll) keep(1 3) keepus(bankAll_*)
		assert _mAll == 3 if inlist(3, _m10, _m25)
		
	gen rank_1_10 = top10uw == 1
	gen rank_11_25 = top10uw == 0 & top25uw == 1
	gen banker`ystart' = _mAll == 3

	foreach bankname of varlist bank25_* {
		if inlist(`ystart', 1895, 1915) replace `bankname' = "" if `bankname' == bank10_1
		else replace `bankname' = "" if inlist(`bankname', bank10_1, bank10_2)
	}
	foreach bankname of varlist bankAll_* {
	    if `ystart' == 1895 ///
			replace `bankname' = "" if inlist(`bankname', bank10_1, bank25_1)
		if inrange(`ystart', 1900, 1910) ///
			replace `bankname' = "" if inlist(`bankname', bank10_1, bank10_2, ///
											bank25_1, bank25_2)
	    if `ystart' == 1915 ///
			replace `bankname' = "" if inlist(`bankname', bank10_1, bank25_1, bank25_2)
	}

	include assign_regions.do
	gen regN = region == "N"
	gen regS = region == "S"
	gen regW = region == "W"

	foreach b of varlist bank10* bank25* bankAll* {
		ren `b' bank_
		merge m:1 bank_ cname using `bank_rr', nogen keep(1 3)
		local suffix = substr("`b'", 5, .)
		ren ???bankers_??? ???bankers_???_`suffix'
		ren bank_ `b'
	}
	foreach var of varlist ???bankers_* {
		replace `var' = 0 if `var' == .
	}
	egen ownbankers_num = rowtotal(ownbankers_num_*)
	egen ownbankers_ind = rowmax(ownbankers_ind_*)
	egen totbankers_num = rowmax(totbankers_num_*)
		bys cname: ereplace totbankers_num = max(totbankers_num)
	gen othbankers_num = totbankers_num - ownbankers_num
		replace ownbankers_num = ownbankers_num - 1 if othbankers_num == -1
		replace othbankers_num = othbankers_num + 1 if othbankers_num == -1
	gen othbankers_ind = othbankers_num > 0
	drop ???bankers_???_*


	merge m:1 fullname_m region using `banker_reg', nogen keep(1 3)
		foreach var of varlist boardseats* {
			replace `var' = 0 if `var' == .
		}
	merge m:1 cname year_std using "assets.dta", nogen keep(1 3)
		gen assets_mn = assets/1000000
		gen ln_assets = ln(assets)
		
	merge m:1 cname using "RR_Financials1890.dta", nogen keep(1 3)
		/*ren receivership receivership_yr
		gen receivership = receivership_yr < `ystart' & receivership != .*/
		drop receivership
		
	// receivership and L5.receivership
	include harmonize_rr_names.do
	replace year_std = year_std - 5
	merge m:1 cname_stn year_std using `receivership', nogen keep(1 3)
	ren receivership L5_receivership
	replace year_std = year_std + 5
	merge m:1 cname_stn year_std using `receivership', nogen keep(1 3)
	
	*egen rrid = group(cname_stn)
	*egen pairid = group(cname_stn fullname_m)
	*xtset pairid year_std

	#delimit ;
	gen jta = inlist(cname, "BALTIMORE & OHIO", /*6*/
							"BALTIMORE & OHIO RAILROAD CO.",
							"Baltimore & Ohio",
							"Baltimore and Ohio Railroad",
							"CENTRAL RAILROAD COMPANY OF NEW JERSEY", /*44*/
							"Central Railroad Of New Jersey",
							"Central of New Jersey",
							"CHESAPEAKE & OHIO RAILWAY CO.", /*12*/
							"CHESAPEAKE, OHIO & SOUTHWESTERN")
			| inlist(cname, "Chesapeake & Ohio",
							"Chesapeake and Ohio Railway",
							"CLEVELAND, CINCINNATI, CHICAGO & ST. LOUIS RAILWAY CO.",
							"CLEVELAND, CINCINNATI, ST. LOUIS & CHICAGO", /*63*/
							"DELAWARE, LACKAWANNA & WESTERN", /*60*/
							"DELAWARE, LACKAWANNA & WESTERN RAILROAD CO.",
							"Delaware, Lackawanna and Western Railroad",
							"Delaware Lackaw & Western",
							"Erie" /*24*/)
			| inlist(cname, "LAKE SHORE & MICHIGAN SOUTHERN", /*66*/
							"LAKE SHORE & MICHIGAN SOUTHERN RAILWAY CO.",
							"Lake Shore & Mich Southern",
							"Lake Shore and Michigan Southern Railway",
							"Lakeshore and Michigan Southern Railway",
							"Lehigh Valley" /*30*/)
			| inlist(cname, "MICHIGAN CENTRAL", /*67*/
							"MICHIGAN CENTRAL RAILROAD CO.",
							"Michigan Central",
							"Michigan Central Railroad",
							"NEW YORK CENTRAL & HUDSON RIVER" /*62*/,
							"NEW YORK CENTRAL & HUDSON RIVER RAILROAD CO.",
							"New York Central & Hudson River Railroad",
							"New York Central, Hudson River and Fort Orange Rail Road")
			| inlist(cname, "NEW YORK, ONTARIO AND WESTERN RAILWAY COMPANY",
							"New York, Ontario and Western Railway", /*38*/
							"PENNSYLVANIA RAILROAD CO.", /*70*/
							"Pennsylvania RR",
							"PHILADELPHIA & READING", /*43*/
							"PHILADELPHIA & READING RAILROAD CO.",
							"Philadelphia and Reading Railroad")
			| inlist(cname, "PITTSBURGH & WESTERN", /*171*/
							"PITTSBURGH & WESTERN RAILROAD CO.",
							"PITTSBURGH, CINCINNATI, CHICAGO & ST. LOUIS", /*72*/
							"Pitts Cin Chic & St Louis",
							"TOLEDO, PEORIA & WESTERN",  /*189*/
							"Vandalia", /*73*/
							"WABASH RAILROAD",
							"WABASH RAILROAD CO.", /*56*/
							"Wabash");
	#delimit cr

	drop code_pnum
	merge m:1 cname year_std using `boardsizes', keep(1 3) nogen
		gen ownbankers_sh = ownbankers_num/boardsize
		gen othbankers_sh = othbankers_num/boardsize
		gen totbankers_sh = totbankers_num/boardsize
		gen totbankers_sh2 = totbankers_sh^2
	
	gen boardseats_samereg_num2 = boardseats_samereg_num^2
		
	merge m:1 cname using `rrfin', keep(1 3) nogen
		gen ltdebt_assets = debt/assets
		gen stdebt_assets = bills/assets
		gen totdebt_assets = (debt+etrust+bills)/assets
		gen margin_safety = (netincome - fixed_charges)/netincome
		gen mat_debt_vol = (debtdue1 + debtdue2 + debtdue3 + debtdue4 + debtdue5)
		gen mat_debt_rat = mat_debt_vol/assets
	
	gen jta_X_rank10 = jta & rank_1_10
	gen jta_X_rank25 = jta & rank_11_25
	gen jta_X_seats_same = jta & boardseats_samereg_ind
	gen rank10_X_seats_same = rank_1_10 & boardseats_samereg_ind
	gen jta_X_rank10_X_seats_same = jta & rank_1_10 & boardseats_samereg_ind

	keep if banker`ystart'

	if `ystart' == 1895 local abc "a"
	if `ystart' == 1900 local abc "b"
	if `ystart' == 1905 local abc "c"
	if `ystart' == 1910 local abc "d"
	if `ystart' == 1915 local abc "e"
	
	tempfile temp`ystart'`full'
	save `temp`ystart'`full'', replace
	
	egen rrid = group(cname_stn)
	
	#delimit ;
	eststo summ_`ystart'`full': estpost summ joinedboard /*jta rank_1_10 rank_11_25 
						jta_X_rank10 jta_X_rank25*/ regN regS regW
						boardseats_samereg_ind boardseats_othreg_ind
						/*jta_X_seats_same*/ ownbankers_ind othbankers_ind
						receivership sub_receivership;
	eststo summ_cont_`ystart'`full': estpost summ assets_mn /*ltdebt_assets stdebt_assets
						totdebt_assets margin_safety mat_debt_vol mat_debt_rat*/
						boardseats_samereg_num boardseats_othreg_num
						ownbankers_num ownbankers_sh othbankers_num othbankers_sh, d;
	
	eststo r1`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 receivership L5_receivership boardseats_samereg_num 
							totbankers_sh boardsize ln_assets, vce(cluster rrid);
	eststo r2`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 receivership L5_receivership boardseats_samereg_num 
							ownbankers_sh othbankers_sh
							boardsize ln_assets, vce(cluster rrid);
	eststo r3`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 receivership L5_receivership boardseats_samereg_num 
							boardseats_samereg_num2 totbankers_sh
							boardsize ln_assets, vce(cluster rrid);
	eststo r4`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 receivership L5_receivership boardseats_samereg_num 
							boardseats_samereg_num2 ownbankers_sh othbankers_sh
							boardsize ln_assets, vce(cluster rrid);
	/*eststo r4`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard jta rank_1_10 boardseats_samereg_ind ln_assets
							boardseats_samereg_num ownbankers_sh
							jta_X_rank10 jta_X_seats_same rank10_X_seats_same
							jta_X_rank10_X_seats_same;*/

	#delimit cr
}
}

#delimit ;
esttab r1? r2? r3? r4? r1?_fullset r2?_fullset r3?_fullset r4?_fullset
	using "RR-banker_pair_regs.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles
	order(rank_1_10 receivership L5_receivership boardseats_samereg_num
		boardseats_samereg_num2 totbankers_sh ownbankers_sh othbankers_sh boardsize ln_assets);

esttab summ_1895 summ_1900 summ_1905 summ_1910 summ_1915
	using "RR-banker_pair_summ.csv", replace
	cells("count mean(fmt(4))") mtitles("1895" "1900" "1905" "1910" "1915") note(" ")
	title("RR-Banker Pair Vars (Bankers on RR Boards Only): Indicators");
	
esttab summ_1895_fullset summ_1900_fullset summ_1905_fullset
		summ_1910_fullset summ_1915_fullset
	using "RR-banker_pair_summ.csv", append
	cells("count mean(fmt(4))") mtitles("1895" "1900" "1905" "1910" "1915") note(" ")
	title("RR-Banker Pair Vars (All Bankers): Indicators");

esttab summ_cont_1895 summ_cont_1900 summ_cont_1905 summ_cont_1910 summ_cont_1915
	using "RR-banker_pair_summ.csv", append
	mtitles("1895" "1900" "1905" "1910" "1915")
	cells("count mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	title("RR-Banker Pair Vars (Bankers on RR Boards Only): Other");
	
esttab summ_cont_1895_fullset summ_cont_1900_fullset
		summ_cont_1905_fullset summ_cont_1910_fullset summ_cont_1915_fullset
	using "RR-banker_pair_summ.csv", append
	mtitles("1895" "1900" "1905" "1910" "1915")
	cells("count mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	title("RR-Banker Pair Vars (All Bankers): Other");

#delimit cr

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
foreach full in "" "_fullset" {
	use `temp1895`full'', clear
	forval ystart = 1900(5)1915 {
		append using `temp`ystart'`full''
	}
	forval ystart = 1900(5)1915 {
		gen yr`ystart' = year_std == `ystart'
		foreach var of varlist rank_1_10 receivership boardseats_samereg_num ///
								boardseats_samereg_num2 totbankers_sh ///
								ownbankers_sh othbankers_sh boardsize ln_assets {
			gen `var'_X`ystart' = `var' * (yr`ystart' == 1)
		}	
	}
	keep cname_stn fullname_m year_std yr* joinedboard rank_1_10* receivership* ///
			boardseats_samereg_num* boardseats_samereg_num2* totbankers_sh* ///
			ownbankers_sh* othbankers_sh* boardsize* ln_assets*
	order cname_stn fullname_m year_std yr* joinedboard rank_1_10* receivership* ///
			boardseats_samereg_num* boardseats_samereg_num2* totbankers_sh* ///
			ownbankers_sh* othbankers_sh* boardsize* ln_assets*
	
	egen rrid = group(cname_stn)
	
	#delimit ;
	eststo r1`full', title("RR Dummies"):
		reg joinedboard yr19* rank_1_10* receivership*
			boardseats_samereg_num boardseats_samereg_num_X????
			boardseats_samereg_num2 boardseats_samereg_num2_X????
			totbankers_sh totbankers_sh_X????
			boardsize* ln_assets* i.rrid, vce(cluster rrid);
	eststo r2`full', title("RR Dummies"):
		reg joinedboard yr19* rank_1_10* receivership*
			boardseats_samereg_num boardseats_samereg_num_X????
			boardseats_samereg_num2 boardseats_samereg_num2_X????
			ownbankers_sh* othbankers_sh*
			boardsize* ln_assets* i.rrid, vce(cluster rrid);
	egen pairid = group(cname_stn fullname_m);
	xtset pairid year_std;
	eststo r1`full'_fe, title("RR-Banker Pair FEs"):
		xtreg joinedboard yr19* rank_1_10* receivership*
			boardseats_samereg_num boardseats_samereg_num_X????
			boardseats_samereg_num2 boardseats_samereg_num2_X????
			totbankers_sh totbankers_sh_X????
			boardsize* ln_assets*, fe vce(robust);
	eststo r2`full'_fe, title("RR-Banker Pair FEs"):
		xtreg joinedboard yr19* rank_1_10* receivership*
			boardseats_samereg_num boardseats_samereg_num_X????
			boardseats_samereg_num2 boardseats_samereg_num2_X????
			ownbankers_sh* othbankers_sh*
			boardsize* ln_assets*, fe vce(robust);
	#delimit cr
}

#delimit ;
esttab r1 r2 r1_fe r2_fe r1_fullset r2_fullset r1_fullset_fe r2_fullset_fe
	using "RR-banker_pair_regs_timeints.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles drop(*rrid)
	order(yr19* rank_1_10* receivership* boardseats_samereg_num
			boardseats_samereg_num_* boardseats_samereg_num2*
			totbankers_sh totbankers_sh_*
			ownbankers_sh* othbankers_sh* boardsize* ln_assets*);
#delimit cr
