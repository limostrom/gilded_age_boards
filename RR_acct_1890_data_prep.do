/*
RR_acct_1890_data_prep.do


*/

import delimited "Data/RR_names_years_corrected.csv", clear varn(1)
drop year_std
duplicates drop
tempfile just_cnames
save `just_cnames', replace

import excel "Data/RR_Accounting_1890.xlsx", clear first
drop RRid
merge 1:1 cname using `just_cnames', keep(1 3) nogen
	replace cname_stn = "Buffalo Rochester & Pittsb" ///
		if cname == "Buffalo Rochester & Pittsburgh"
	replace cname_stn = "Chicago & North Western" ///
		if cname == "Chicago & Northwestern"
	replace cname_stn = "Chicago Milwaukee & St Paul" ///
		if cname == "Chicago Milwaukee & St. Paul"
	replace cname_stn = "Chicago St P Minn & Omaha" ///
		if cname == "Chicago St Paul Minneapolis & Omaha"
	replace cname_stn = "Cleve Cincin Chic & St Louis" ///
		if cname == "Cleveland Cincinnati Chicago & St Louis"
	replace cname_stn = "Delaware Lackaw & Western" ///
		if cname == "Delaware Lackawanna & Western"
	replace cname_stn = "Green Bay, Winona and St. Paul Railroad" ///
		if cname == "Green Bay Winona & St. Paul"
	replace cname_stn = "Lake Shore & Mich Southern" ///
		if cname == "Lake Shore & Michigan Southern"
	replace cname_stn = "New York, Lake Erie and Western Railroad" ///
		if cname == "NY Lake Erie & Western"
	replace cname_stn = "Nashville Chatt & St Louis" ///
		if cname == "Nashville Chattanooga & St Louis"
	replace cname_stn = "Reading" ///
		if cname == "Philadelphia & Reading"
	replace cname_stn = "St Louis Southwestern" ///
		if cname == "St. Louis Southwestern"
	replace cname_stn = "TOLEDO, ANN ARBOR & NORTH MICHIGAN" ///
		if cname == "Toledo Ann Arbor & North Michigan"
drop cname

tempfile acct1890
save `acct1890', replace