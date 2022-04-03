/*
Ind_interlock_decomposition.do

*/

clear all
cap log close
pause on


cap cd "C:\Users\lmostrom\Documents\Gilded Age Boards - Scratch\"
cap cd "C:\Users\17036\Dropbox\Personal Document Backup\Gilded Age Boards - Scratch\"
global repo "C:/Users/17036/OneDrive/Documents/GitHub/gilded_age_boards"


*%%Prep Underwriter/CB Datasets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use "Thesis/Merges/UW_1880-1920_top10.dta", clear
egen tagged = tag(fullname_m year_std)
keep if tagged
rename cname banknameTop10
tempfile top10uw
save `top10uw', replace

use "Data/UW_1880-1920_allnyse.dta", clear
keep fullname_m year_std cname
egen tagged = tag(fullname_m year_std)
keep if tagged
drop tagged
rename cname banknameNYSE
tempfile nyse
save `nyse', replace

use "Data/CB_1880-1920_NY.dta", clear
keep fullname_m year_std cname
egen tagged = tag(fullname_m year_std)
keep if tagged
drop tagged
ren cname banknameNYCB
tempfile nycb
save `nycb', replace

*%%Import Primary Affiliations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import excel "Data/biggest_CB_NY_interlock_names.xlsx", clear first
keep year_std fullname_m prim_ind
duplicates drop
isid fullname_m year_std
tempfile prim_inds
save `prim_inds', replace

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use first fullname_m cname year_std director id_add using "Thesis/Merges/Ind_boards_wtitles.dta", clear
keep if director == 1
ren id_add id
	
keep year_std cname id first fullname_m 
ren cname cnameB
ren id idB
tempfile self
save `self', replace

ren cnameB cnameA
ren idB idA

joinby fullname_m year_std using `self', unm(master)
drop if cnameA == cnameB
drop if idA > idB
drop _merge

merge m:1 fullname_m year_std using `top10uw', keep(1 3) gen(_mT10) keepus(banknameTop10)
merge m:1 fullname_m year_std using `prim_inds', keep(1 3) gen(_mBig)
	ren prim_ind affC
replace affC = "Top 10 UW" if _mT10 == 3
replace affC = "Unclassified" if _mBig == 3 & affC == ""

tab affC year_std
merge m:1 fullname_m year_std using `nyse', keep(1 3) gen(_mNYSE)
replace affC = "Other NYSE UW" if _mNYSE==3 & inlist(affC, "")
tab affC year_std

merge m:1 fullname_m year_std using `nycb', keep(1 3 4) gen(_mNYCB)
replace affC = "Other NY CB" if _mNYCB==3 & inlist(affC, "")

replace affC = "Other Non-Financial" if affC == ""

gen affA = "Commercial Bank Director" if _mNYCB == 3
	replace affA = "Non-Banker Interlock" if affA == ""
gen affB = "Top 10 Underwriter" if _mT10 == 3
	replace affB = "Non-UW Commercial Banker" if _mNYCB == 3 & affB == ""
	replace affB = "Non-Financial Interlock" if affB == ""

dis "Table 1A"
tab affA year_std

dis "Table 1B"
tab affB year_std

dis "Table 1C"
tab affC year_std

*sdf // ------------------------

foreach abc in "A" "B" "C" {
	preserve
		replace aff`abc' = subinstr(aff`abc', "/", "", .)
		replace aff`abc' = subinstr(aff`abc', "-", "", .)
		replace aff`abc' = subinstr(aff`abc', " ", "", .)
		keep cnameA cnameB year_std aff`abc'
		gen interlock = 1
		duplicates drop
		reshape wide interlock, i(cnameA cnameB year_std) j(aff`abc') string

		tab year_std, matcell(Nunique)
		matrix T = Nunique'
		local rownamelist "Unique"
		foreach var of varlist interlock* {
			replace `var' = 0 if `var' == .
			local rownamelist = substr("`var'", 10, .) + " " + "`rownamelist'"
			
			tab year_std `var', matcell(N)
			matrix T = N[1...,2]' \ T
		}
		matrix colnames T = 1895 1900 1905 1910 1915 1920
		matrix rownames T = `rownamelist'
		matlist T
		*pause
	restore
}

keep if inlist(affC, "Unclassified", "Other NY CB", "Other Non-Financial")
keep year_std cnameA first fullname_m banknameNYSE banknameNYCB affC
	gsort -affC
ren cnameA cname
ren affC group
duplicates drop
order year_std cname first fullname_m group banknameNYSE banknameNYCB
export delimited using "smallest_CB_NY_interlock_names_Ind.csv", replace

