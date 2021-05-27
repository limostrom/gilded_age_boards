/*
rr_financials_1900_regs.do

*/
cap cd "C:\Users\lmostrom\Documents\PersonalResearch\Gilded Age Boards\"

import excel "1900 RR Financial Data.xlsx", first clear
replace bills = 0 if bills == .
tempfile rrfin
save `rrfin', replace


use year_std cname fullname_m director using "Railroad_boards_final.dta", clear
keep if director == 1
keep if inrange(year_std, 1900, 1905)
joinby fullname_m year_std using "UW_1880-1920_top10.dta", unm(master)
gen bankerdir = _merge == 3
duplicates drop fullname_m cname year_std, force
collapse (sum) bankerdir, by(cname year_std)
reshape wide bankerdir, i(cname) j(year_std)
drop if bankerdir1900 == . | bankerdir1905 == .

gen addedbanker = bankerdir1900 == 0 & bankerdir1905 > 0
merge 1:1 cname using `rrfin', keep(1 3)
assert _merge == 3
drop _merge

gen ltdebt_assets = debt/assets
gen stdebt_assets = bills/assets
gen totdebt_assets = (debt+etrust+bills)/assets
gen margin_safety = (netincome - fixed_charges)/netincome
gen mat_debt_vol = (debtdue1 + debtdue2 + debtdue3 + debtdue4 + debtdue5)
gen mat_debt_rat = mat_debt_vol/assets

eststo r1: reg addedbanker totdebt_assets assets
eststo r2: reg addedbanker ltdebt_assets stdebt_assets
eststo r3: reg addedbanker mat_debt_vol assets
eststo r4: reg addedbanker totdebt_assets assets margin_safety
eststo r5: reg addedbanker mat_debt_rat
eststo r6: reg addedbanker assets ltdebt_assets stdebt_assets margin_safety
eststo r7: reg addedbanker assets mat_debt_rat margin_safety
eststo r8: reg addedbanker assets stdebt_assets margin_safety mat_debt_rat

esttab r* using "RR_financials_regs_1900.csv", replace ///
	star(+ 0.10 * 0.05 ** 0.01 *** 0.001) se ///
	order(assets stdebt_assets ltdebt_assets totdebt_assets ///
			margin_safety mat_debt_rat mat_debt_vol)




