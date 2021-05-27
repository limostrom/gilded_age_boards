

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

keep if director == 1

bys year_std fullname_m: gen tot_boards = _N

collapse (max) max_n_boards = tot_boards, by(cname year_std sector)
assert max_n_boards != .

gen over5 = max_n_boards >= 5
gen over10 = max_n_boards >= 10
gen id = _n

collapse (sum) over5 over10 (count) n_firms = id, by(year_std sector)


forval n = 5(5)10 {
	
	gen sh_over`n' = over`n'/n_firms
	assert sh_over`n' < 1

	#delimit ;
	tw (line sh_over`n' year_std if sector == "RR", lc(black) lp(l))
	   (line sh_over`n' year_std if sector == "Ind/Util", lc(black) lp(_))
	   (scatter sh_over`n' year_std if sector == "RR", mc(white) msym(O))
	   (scatter sh_over`n' year_std if sector == "Ind/Util", mc(white) msym(O))
	   (scatter sh_over`n' year_std if sector == "RR", mc(black) msym(Oh))
	   (scatter sh_over`n' year_std if sector == "Ind/Util", mc(black) msym(Oh)),
	 title("Proportion of Firms with a" "Director on `n'+ Boards")
	 xti("") yti("") ylab(0(0.2)1)
	 legend(order(1 "Railroads" 2 "Industrials & Utilities"));
	 
	 graph export "prop_w_an_over`n'_director.png",
				replace as(png) wid(600) hei(350);
	 #delimit cr
}
 
 
 