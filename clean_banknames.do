/*
clean_banknames.do

*/

gen bankname_stn = upper(bank_)
replace bankname_stn = subinstr(bankname_stn, ".", "", .)
replace bankname_stn = subinstr(bankname_stn, ",", "", .)
replace bankname_stn = "BLAIR & CO" if bankname_stn == "BLAIR & CO INC"
replace bankname_stn = "DE HAVEN & TOWNSEND" if bankname_stn == "DE HAVEN & TOWNSEND_BRANCH"
replace bankname_stn = "FIRST NATIONAL" if bankname_stn == "FIRST NATIONAL BANK"
replace bankname_stn = "GUARANTY" if inlist(bankname_stn,"GUARANTY TRUST CO", "GUARANTY CO")
replace bankname_stn = "HARRIS & FULLER" if bankname_stn == "HARRIS FULLER & HURLEY"
replace bankname_stn = "NATIONAL CITY" if inlist(bankname_stn, "NATIONAL CITY BANK", "NATIONAL CITY CO")
replace bankname_stn = "MORGAN J P & CO" if bankname_stn == "DREXEL MORGAN & CO"
