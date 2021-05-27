/*
harmonize_rr_names.do
*/
/*
use cname year_std using "Railroad_boards_final.dta", clear
duplicates drop
*/
gen cname_stn = upper(cname)
replace cname_stn = subinstr(cname_stn, "&", "", .)
replace cname_stn = subinstr(cname_stn, ",", "", .)
replace cname_stn = subinstr(cname_stn, ".", "", .)
replace cname_stn = subinstr(cname_stn, "-", "", .)
replace cname_stn = subinstr(cname_stn, "NORTH WESTERN", "NORTHWESTERN", .)
replace cname_stn = subinstr(cname_stn, "PORT CHESTER", "PORTCHESTER", .)
replace cname_stn = subinstr(cname_stn, "FORT ", "FT ", .)
replace cname_stn = subinstr(cname_stn, " RR", "", .)
replace cname_stn = subinstr(cname_stn, " RAILWAY", "", .)
replace cname_stn = subinstr(cname_stn, " RAILROAD", "", .)
replace cname_stn = subinstr(cname_stn, " COMPANY", "", .)
replace cname_stn = subinstr(cname_stn, " AND ", " ", .)
replace cname_stn = subinstr(cname_stn, "   ", " ", .)
replace cname_stn = subinstr(cname_stn, "  ", " ", .)
gen cname_len = strlen(cname_stn)
	replace cname_len = cname_len-3 if substr(cname_stn, -3, .) == " CO"
replace cname_stn = substr(cname_stn, 1, cname_len)

replace cname_stn = "BUFFALO ROCHESTER PITTSBURGH" ///
		if cname_stn == "BUFFALO ROCHESTER PITTSB"
replace cname_stn ="BUFFALO SUSQUEHANNA" ///
		if cname_stn == "BUFFALO SUSQ"
replace cname_stn = "CANADIAN PACIFIC" ///
		if cname_stn == "CANADIAN PACIFIC "
replace cname_stn = "CHICAGO EASTERN ILLINOIS" ///
		if inlist(cname_stn, "CHICAGO EASTERN ILL", "CHICAGO EASTERN ILLINOIS")
replace cname_stn = "CHICAGO ROCK ISLAND PACIFIC" ///
		if inlist(cname_stn, "CHIC ROCK ISLAND PACIFIC")
replace cname_stn = "CHICAGO ST PAUL MINNEAPOLIS OMAHA" ///
		if inlist(cname_stn, "CHICAGO ST P MINN OMAHA", "CHICAGO ST PAUL MINNEAPOLIS")
replace cname_stn = "CLEVELAND CINCINNATI CHICAGO ST LOUIS" ///
		if inlist(cname_stn, "CLEVELAND CINCINNATI ST LOUIS CHICAGO", "CLEVE CINCIN CHIC ST LOUIS")
replace cname_stn = "CLEVELAND PITTSBURGH" ///
		if inlist(cname_stn, "CLEVELAND PITTS")
replace cname_stn = "DELAWARE HUDSON" ///
		if inlist(cname_stn, "DELAWARE HUDSON CANAL")
replace cname_stn = "DELAWARE LACKAWANNA WESTERN" ///
		if inlist(cname_stn, "DELAWARE LACKAW WESTERN")
replace cname_stn = "DES MOINES FORT DODGE" ///
		if inlist(cname_stn, "DES MOINES FT DODGE")
replace cname_stn = "DULUTH SOUTH SHORE ATLANTIC" ///
		if inlist(cname_stn, "DULUTH SOUTH SHORE ATLAN")
replace cname_stn = "EVANSVILLE TERRE HAUTE" ///
		if inlist(cname_stn, "EVANSVILLE TERRA HAUTE")
replace cname_stn = "FORT WORTH DENVER CITY" ///
		if inlist(cname_stn, "FT WORTH DEN CITY")
replace cname_stn = "LAKE SHORE MICHIGAN SOUTHERN" ///
		if inlist(cname_stn, "LAKE SHORE MICH SOUTHERN", "LAKESHORE MICHIGAN SOUTHERN")
replace cname_stn = "MEXICAN CENTRAL" ///
		if inlist(cname_stn, "MEXICAN CENTRAL CO LIMITED")
replace cname_stn = "NASHVILLE CHATTANOOGA ST LOUIS" ///
		if inlist(cname_stn, "NASHVILLE CHATT ST LOUIS")
replace cname_stn = "NORFOLK SOUTHERN" ///
		if cname_stn == "NORFOK SOUTHERN"
replace cname_stn = "OREGON SHORT LINE" ///
		if cname_stn == "OREGON SHORT LINE UTAH NORTHERN"
replace cname_stn = "PITTSBURGH CINCINNATI CHICAGO ST LOUIS" ///
		if cname_stn == "PITTS CIN CHIC ST LOUIS"
replace cname_stn = "ROME WATERTOWN OGDENSBURG" ///
		if cname_stn == "ROME WATERTOWN OGDENSBURGH"
