/*
ind_banker_pair_regs.do

*/
est clear

foreach full in "" "_fullset" {
forval ystart = 1895(5)1915 {
	local y5 = `ystart' + 5
	
	*%%Prep Underwriter Dataset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std fullname_m cname using "Data/UW_1880-1920_Indtop10.dta", clear
	*include clean_banknames.do
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank10_
	bys fullname_m year_std: gen n = _n
	reshape wide bank10_, i(fullname_m year_std) j(n)
	tempfile temp10
	save `temp10', replace

	use year_std fullname_m cname using "Data/UW_1880-1920_top25.dta", clear
	*include clean_banknames.do
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank25_
	bys fullname_m year_std: gen n = _n
	reshape wide bank25_, i(fullname_m year_std) j(n)
	tempfile temp25
	save `temp25', replace

	use year_std fullname_m cname using "Data/UW_1880-1920_allnyse.dta", clear
	*include clean_banknames.do
	keep if year_std == `ystart'
	duplicates drop
	rename cname bankAll_
	bys fullname_m year_std: gen n = _n
	reshape wide bankAll_, i(fullname_m year_std) j(n)
	tempfile tempNYSE
	save `tempNYSE', replace
	
	
	*%% Inds & Utils %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std cname fullname_m director using "Thesis/Merges/Ind_boards_wtitles.dta", clear
	append using "Thesis/Merges/Util_boards_final.dta", keep(year_std cname fullname_m director)
	keep if director == 1
	tempfile indutil
	save `indutil', replace
	
	*%% Board Size %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use year_std cname fullname_m director using "Thesis/Merges/Ind_boards_wtitles.dta", clear
	append using "Thesis/Merges/Util_boards_final.dta", keep(year_std cname fullname_m director)
	assert fullname_m != ""
	gen boardsize = 1
	collapse (sum) boardsize, by(cname year_std)
	tempfile boardsizes
	save `boardsizes', replace	
	
	*%% Prep Industry Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	import excel cname cid Entrant Industry using "Data/industrials_interlocks_coded.xlsx", ///
		clear sheet("`ystart'") cellrange(A2)
	replace cname = "Natinoal Linseed Oil" if cname == "National Linseed Oil" ///
				& `ystart' == 1895
	drop if cname == ""

	tempfile industries
	save `industries', replace

	*%%Bankers on Boards%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	//bankers by vertical industry groups
	use year_std fullname_m cname using "Data/UW_1880-1920_allnyse.dta", clear
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank_

	joinby fullname_m year_std using `indutil', _merge(_m)
	keep bank_ fullname_m year_std cname
	duplicates drop
	
	merge m:1 cname using `industries', nogen keep(1 3)
	ren Industry ind
		replace ind = "Utilities" if ind == ""
		replace ind = "Mining / Smelting & Refining" if inlist(ind, "Mining/Metals", ///
					"Metals/Steel", "Mining/Metals / Steel / Chemicals", "Metals", ///
					"Mining / Shipping", "Mining / Steel", "Mining / Oil", ///
					"Metals / Smelting & Refining", "melting/Refining") ///
					| inlist(ind, "Mining", "Smelting/Refining")
		replace ind = "Automobiles" if inlist(ind, "Automobiles / Farming Machinery", ///
						"Automobiles / Firearms & Explosives", "Automobiles / Rubber")
		replace ind = "Chemicals" if ind == "Chemicals / Mining"
		replace ind = "General Manufacturing" if ind == "General Manufacturing / Chemicals"
		replace ind = "Food & Beverages" if ind == "Food & Beverages / Consumer Goods"
		replace ind = "Oil" if ind == "Oil / Shipping"
		replace ind = "Pharmaceuticals" if ind == "Pharmaceuticals / Consumer Goods"
		replace ind = "Land/Real Estate" if ind == "Real Estate / Shipping"
		replace ind = "Shipping" if ind == "Shipping / General Manufacturing"
		
	bys fullname_m cname (bank_): gen repeat = _n - 1
	bys fullname_m repeat: gen boardseats_num = _N
	
	bys fullname_m ind repeat: gen boardseats_sameind_num = _N
		include "$repo/boardseats_vertind_tally.do"
		gen boardseats_nrind_num = boardseats_num - boardseats_sameind_num - boardseats_vertind_num
		gen boardseats_sameind_ind = boardseats_sameind_num > 0
		gen boardseats_vertind_ind = boardseats_vertind_num > 0
		gen boardseats_nrind_ind = boardseats_nrind_num > 0
	keep fullname_m ind boardseats_*
	duplicates drop
	isid fullname_m ind
	tempfile banker_ind
	save `banker_ind', replace
	*---------------------------------------------------------------------------
	use year_std fullname_m cname using "Data/UW_1880-1920_allnyse.dta", clear
	keep if year_std == `ystart'
	duplicates drop
	rename cname bank_

	//bank-firm dataset
	joinby fullname_m year_std using "Data/IndUtil_boards_final.dta", _merge(_m)
	keep bank_ fullname_m year_std cname
	duplicates drop

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
	tempfile bank_ind
	save `bank_ind', replace
	
	*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	use "Data/ind_banker_pairs`full'_`ystart'-`y5'.dta", clear

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

	foreach b of varlist bank10* bank25* bankAll* {
		ren `b' bank_
		merge m:1 bank_ cname using `bank_ind', nogen keep(1 3)
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
	gen othbankers_ind = othbankers_num > 0
	drop ???bankers_???_*
	
	merge m:1 cname using `industries', nogen keep(1 3)
	ren Industry ind
		replace ind = "Utilities" if ind == ""
		replace ind = "Mining / Smelting & Refining" if inlist(ind, "Mining/Metals", ///
					"Metals/Steel", "Mining/Metals / Steel / Chemicals", "Metals", ///
					"Mining / Shipping", "Mining / Steel", "Mining / Oil", ///
					"Metals / Smelting & Refining", "melting/Refining") ///
					| inlist(ind, "Mining", "Smelting/Refining")
		replace ind = "Automobiles" if inlist(ind, "Automobiles / Farming Machinery", ///
						"Automobiles / Firearms & Explosives", "Automobiles / Rubber")
		replace ind = "Chemicals" if ind == "Chemicals / Mining"
		replace ind = "General Manufacturing" if ind == "General Manufacturing / Chemicals"
		replace ind = "Food & Beverages" if ind == "Food & Beverages / Consumer Goods"
		replace ind = "Oil" if ind == "Oil / Shipping"
		replace ind = "Pharmaceuticals" if ind == "Pharmaceuticals / Consumer Goods"
		replace ind = "Land/Real Estate" if ind == "Real Estate / Shipping"
		replace ind = "Shipping" if ind == "Shipping / General Manufacturing"
	
	merge m:1 fullname_m ind using `banker_ind', nogen keep(1 3)
		foreach var of varlist boardseats* {
			replace `var' = 0 if `var' == .
		}
		
	merge m:1 cname year_std using `boardsizes', keep(3)
		gen ownbankers_sh = ownbankers_num/boardsize
		gen othbankers_sh = othbankers_num/boardsize
		gen totbankers_sh = totbankers_num/boardsize
		
	merge m:1 cname year_std using "Data/assets_ind.dta", keep(3) nogen
		gen ln_assets = ln(assets)
		gen assets_mn = assets/1000000
		
	gen boardseats_sameind_num2 = boardseats_sameind_num^2
	gen boardseats_vertind_num2 = boardseats_vertind_num^2
	
	encode ind, gen(ind_cat)
	
	keep if banker`ystart'

	if `ystart' == 1895 local abc "a"
	if `ystart' == 1900 local abc "b"
	if `ystart' == 1905 local abc "c"
	if `ystart' == 1910 local abc "d"
	if `ystart' == 1915 local abc "e"
	
	tempfile temp`ystart'`full'
	save `temp`ystart'`full'', replace
	
	
	egen firmid = group(cname)
	
	#delimit ;
	eststo summ_`ystart'`full': estpost summ joinedboard rank_1_10 rank_11_25
			boardseats_sameind_ind boardseats_vertind_ind boardseats_nrind_ind
			ownbankers_ind othbankers_ind;
	eststo summ_cont_`ystart'`full': estpost summ assets_mn
			boardseats_sameind_num boardseats_vertind_num boardseats_nrind_num
			ownbankers_num othbankers_num, d;
	
	eststo r1`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 ib(first).ind_cat ln_assets
						boardseats_sameind_num boardseats_vertind_num
						totbankers_sh boardsize, vce(cluster firmid);
		estadd ysumm, mean;
	eststo r2`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 ib(first).ind_cat ln_assets
						boardseats_sameind_num boardseats_vertind_num
						ownbankers_sh othbankers_sh boardsize, vce(cluster firmid);
		estadd ysumm, mean;
	eststo r3`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 ib(first).ind_cat ln_assets
						boardseats_sameind_num boardseats_sameind_num2
						boardseats_vertind_num boardseats_vertind_num2
						totbankers_sh boardsize, vce(cluster firmid);
		estadd ysumm, mean;
	eststo r4`abc'`full', title("`ystart'-`y5'"):
		reg joinedboard rank_1_10 ib(first).ind_cat ln_assets
						boardseats_sameind_num boardseats_sameind_num2
						boardseats_vertind_num boardseats_vertind_num2
						ownbankers_sh othbankers_sh boardsize, vce(cluster firmid);
		estadd ysumm, mean;
	#delimit cr
}
}
#delimit ;
esttab r1? r2? r3? r4? r1?_fullset r2?_fullset r3?_fullset r4?_fullset
	using "Ind-banker_pair_regs.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles label
	scalars("ymean Mean(Dep. Var.)") addnotes("SEs clustered on firmid")
	order(rank_1_10 boardseats_sameind_num boardseats_vertind_num
			boardseats_sameind_num2 boardseats_vertind_num2 totbankers_sh
			ownbankers_sh othbankers_sh boardsize ln_assets);

esttab summ_1895 summ_1900 summ_1905 summ_1910 summ_1915
	using "Ind-banker_pair_summ.csv", replace
	cells("count mean(fmt(4))") mtitles("1895" "1900" "1905" "1910" "1915")
	title("Ind-Banker Pair Vars (Bankers on Ind Boards Only): Indicators") note(" ");
	
esttab summ_1895_fullset summ_1900_fullset summ_1905_fullset
		summ_1910_fullset summ_1915_fullset
	using "Ind-banker_pair_summ.csv", append
	cells("count mean(fmt(4))") mtitles("1895" "1900" "1905" "1910" "1915")
	title("Ind-Banker Pair Vars (All Bankers): Indicators") note(" ");

esttab summ_cont_1895 summ_cont_1900 summ_cont_1905 summ_cont_1910 summ_cont_1915
	using "Ind-banker_pair_summ.csv", append 
	mtitles("1895" "1900" "1905" "1910" "1915")
	cells("count mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	title("Ind-Banker Pair Vars (Bankers on Ind Boards Only): Other");
	
esttab summ_cont_1895_fullset summ_cont_1900_fullset summ_cont_1905_fullset
		summ_cont_1910_fullset summ_cont_1915_fullset
	using "Ind-banker_pair_summ.csv", append 
	mtitles("1895" "1900" "1905" "1910" "1915")
	cells("count mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))
				p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2))")
	title("Ind-Banker Pair Vars (All Bankers): Other");
#delimit cr

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
foreach full in "" "_fullset" {
	use `temp1895`full'', clear
	forval ystart = 1900(5)1915 {
		append using `temp`ystart'`full''
	}
	forval ystart = 1900(5)1915 {
		gen yr`ystart' = year_std == `ystart'
		foreach var of varlist rank_1_10 boardseats_sameind_num boardseats_sameind_num2 ///
						boardseats_vertind_num boardseats_vertind_num2 totbankers_sh ///
						ownbankers_sh othbankers_sh boardsize ln_assets {
			gen `var'_X`ystart' = `var' * (yr`ystart' == 1)
		}	
	}
	keep cname fullname_m year_std yr* joinedboard rank_1_10* ///
			boardseats_sameind_num* boardseats_vertind_num* totbankers_sh* ///
			ownbankers_sh* othbankers_sh* boardsize* ln_assets*
	order cname fullname_m year_std yr* joinedboard rank_1_10* ///
			boardseats_sameind_num* boardseats_vertind_num* totbankers_sh* ///
			ownbankers_sh* othbankers_sh* boardsize* ln_assets*
	
	egen firmid = group(cname)
	
	#delimit ;
	eststo r1`full', title("Firm Dummies"):
		reg joinedboard yr19* rank_1_10*
			boardseats_sameind_num* boardseats_vertind_num*
			totbankers_sh*
			boardsize* ln_assets* i.firmid, vce(cluster firmid);
		estadd ysumm, mean;
	eststo r2`full', title("Firm Dummies"):
		reg joinedboard yr19* rank_1_10*
			boardseats_sameind_num* boardseats_vertind_num*
			ownbankers_sh* othbankers_sh*
			boardsize* ln_assets* i.firmid, vce(cluster firmid);
		estadd ysumm, mean;
	egen pairid = group(cname fullname_m);
	xtset pairid year_std;
	eststo r1`full'_fe, title("Firm-Banker Pair FEs"):
		xtreg joinedboard yr19* rank_1_10*
			boardseats_sameind_num* boardseats_vertind_num*
			totbankers_sh* boardsize* ln_assets*, fe vce(cluster firmid);
		estadd ysumm, mean;
	eststo r2`full'_fe, title("Firm-Banker Pair FEs"):
		xtreg joinedboard yr19* rank_1_10*
			boardseats_sameind_num* boardseats_vertind_num*
			ownbankers_sh* othbankers_sh* boardsize* ln_assets*, fe vce(cluster firmid);
		estadd ysumm, mean;
	#delimit cr
}

#delimit ;
esttab r1 r2 r1_fe r2_fe r1_fullset r2_fullset r1_fullset_fe r2_fullset_fe
	using "Ind-banker_pair_regs_timeints.csv", replace
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se mtitles drop(*firmid)
	scalars("ymean Mean(Dep. Var.)") addnotes("SEs clustered on firmid")
	order(yr19* rank_1_10*
			boardseats_sameind_num boardseats_sameind_num_*
			boardseats_sameind_num2* boardseats_vertind_num
			boardseats_vertind_num_* boardseats_vertind_num2*
			totbankers_sh totbankers_sh_* ownbankers_sh* othbankers_sh*
			boardsize* ln_assets*);
#delimit cr