/*
ind_table_create.do



*/
clear all
cap log close
pause on

cap cd "C:/Users/lmostrom/Documents/PersonalResearch/"


forval y = 1895(5)1920 {
    import excel cname cid Entrant Industry using "industrials_interlocks_coded.xlsx", ///
		clear sheet("`y'") cellrange(A2)
	drop cid
	gen year = `y'
	tempfile ind`y'
	save `ind`y'', replace
}


use `ind1895', clear
forval y = 1900(5)1920 {
	append using `ind`y''
}


replace Industry = "Mining / Smelting & Refining" if inlist(Industry, "Mining/Metals", ///
					"Metals/Steel", "Mining/Metals / Steel / Chemicals", "Metals", ///
					"Mining / Shipping", "Mining / Steel", "Mining / Oil", ///
					"Metals / Smelting & Refining", "melting/Refining") ///
					| inlist(Industry, "Mining", "Smelting/Refining")
replace Industry = "Automobiles" if inlist(Industry, "Automobiles / Farming Machinery", ///
				"Automobiles / Firearms & Explosives", "Automobiles / Rubber")
replace Industry = "Chemicals" if Industry == "Chemicals / Mining"
replace Industry = "General Manufacturing" if Industry == "General Manufacturing / Chemicals"
replace Industry = "Food & Beverages" if Industry == "Food & Beverages / Consumer Goods"
replace Industry = "Oil" if Industry == "Oil / Shipping"
replace Industry = "Pharmaceuticals" if Industry == "Pharmaceuticals / Consumer Goods"
replace Industry = "Land/Real Estate" if Industry == "Real Estate / Shipping"
replace Industry = "Shipping" if Industry == "Shipping / General Manufacturing"

gen id = _n
preserve // --- Firm in Each Industry Over Time --------------------------------
	collapse (count) Firms = id, by(year Industry)
	reshape wide Firms, i(Industry) j(year)

	* put Miscellaneous last
	replace Industry = "zMiscellaneous" if Industry == "Miscellaneous"
	sort Industry
	replace Industry = "Miscellaneous" if Industry == "zMiscellaneous"

	drop if Industry == ""
	lab var Industry "Industry"


	export excel using "industrials_interlocks_coded.xlsx", ///
		sheet("Ind Tab-raw", replace) first(varl)
restore // ---------------------------------------------------------------------
preserve // --- Incumbents/Entrants in Each Industry Over Time -----------------
	collapse (count) Firms = id, by(year Industry Entrant)
	reshape wide Firms, i(Industry Entrant) j(year)

	* put Miscellaneous last
	replace Industry = "zMiscellaneous" if Industry == "Miscellaneous"
	sort Industry Entrant
	replace Industry = "Miscellaneous" if Industry == "zMiscellaneous"

	drop if Industry == ""
	lab var Industry "Industry"

	lab def entlab 0 "Incumbent" 1 "Entrant"
	lab val Entrant entlab

	order Industry Entrant
	
	export excel using "industrials_interlocks_coded.xlsx", ///
		sheet("Ind Tab Inc vs Ent-raw", replace) first(varl)
restore // ---------------------------------------------------------------------


