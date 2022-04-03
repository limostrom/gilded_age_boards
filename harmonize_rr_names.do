/*
harmonize_rr_names.do
*/
preserve

import delimited "Data/RR_names_years_corrected.csv", clear
tempfile stnnames
save `stnnames', replace
restore

merge m:1 cname year_std using `stnnames', nogen