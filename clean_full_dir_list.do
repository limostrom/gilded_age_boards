/*
Clean "All_1880-1920_clean.dta" for firm IDs

*/

replace cname = upper(cname)
bys cname: ereplace cid = max(cid)
gen firmid = RRid if RRid != .
summ RRid
	local topid = `r(max)'
	dis "`topid'"
replace firmid = cid + `topid' if firmid == .
replace firmid = 800 if cname == "AMER TELEGRAPH & CABLE" & firmid == .
replace firmid = 801 if cname == "AMER TELEPH & TELEG" & firmid == .
replace firmid = 802 if cname == "AMERICAN BICYCLE" & firmid == .
replace firmid = 803 if firmid == . & ///
	inlist(cname, "AMERICAN DISTRICT TELEGRAPH", "AMERICAN DISTRICT TELEGRAPH CO.")
replace firmid = 804 if cname == "AMERICAN PNEUMATIC SERVICE" & firmid == .
replace firmid = 805 if firmid == . & ///
	inlist(cname, "AMERICAN SPIRITS MANUFACTURING","DISTILLING AND CATTLE FEEDING COMPANY")
	// https://www.fool.com/investing/general/2013/04/09/what-happened-to-the-first-12-stocks-on-the-dow.aspx
replace firmid = 220 if cname == "AMERICAN SUGAR REFINING COMPANY" & firmid == .
replace firmid = 223 if cname == "AMERICAN TOBACCO CO." & firmid == .
replace firmid = 806 if cname == "BROOKLYN RAPID TRANSIT" & firmid == .
replace firmid = 807 if cname == "CAMERON IRON AND COAL" & firmid == .
replace firmid = 808 if cname == "CANTON" & firmid == .
replace firmid = 809 if cname == "CAPITAL TRACTION" & firmid == .
replace firmid = 810 if cname == "CENT & SOUTH AMER TELEG" & firmid == .
replace firmid = 811 if cname == "CHICAGO CONSOLIDATED TRACTION" & firmid == .
replace firmid = 812 if cname == "CHICAGO GAS TRUST" & firmid == .
replace firmid = 813 if cname == "COLORADO COAL & IRON DEVELOPMEMT CO." & firmid == .
replace firmid = 814 if firmid == . & ///
	inlist(cname, "COLUMBUS & HOCK COAL & IRON", "COLUMBUS & HOCKING COAL AND IRON CO.")
replace firmid = 815 if cname == "COMMERCIAL CABLE" & firmid == .
replace firmid = 816 if cname == "CONNECTICUT RAILWAY & LIGHTING" & firmid == .
replace firmid = 817 if firmid == . & ///
	inlist(cname, "CONSOLIDATED GAS CO. OF NEW YORK", "CONSOLIDATED GAS NY")
replace firmid = 251 if cname == "CONSOLIDATION COAL CO." & firmid == .
replace firmid = 818 if cname == "CONTINENTAL TOBACCO CO" & firmid == .
replace firmid = 819 if cname == "DETROIT GAS" & firmid == .
replace firmid = 820 if cname == "DISTILLING CO OF AMERICA" & firmid == .
replace firmid = 821 if cname == "EDISON ELECTRIC ILLUMINATING CO. OF NEW YORK" & firmid == .
replace firmid = 822 if cname == "EQUITABLE GAS LIGHT CO. OF NEW YORK" & firmid == .
replace firmid = 823 if cname == "GAS & ELECTRIC OF BERGEN COUNTY" & firmid == .
replace firmid = 824 if cname == "GLUCOSE SUGAR REF" & firmid == .
replace firmid = 825 if cname == "HORN SILVER MINING" & firmid == .
replace firmid = 826 if cname == "INTERNATIONAL POWER" & firmid == .
replace firmid = 827 if cname == "INTERNATIONAL SILVER" & firmid == .
replace firmid = 828 if cname == "KINGS COUNTY ELEC LT & P" & firmid == .
replace firmid = 829 if firmid == . & ///
	inlist(cname, "LACLEDE GAS (ST LOUIS)", "LACLEDE GASLIGHT CO.")
replace firmid = 142 if cname == "MANHATTAN RAILWAY" & firmid == .
replace firmid = 830 if cname == "METROPOLITAN STREET RY" & firmid == .
replace firmid = 831 if cname == "METROPOLITAN WEST SIDE EL, CHICAGO" & firmid == .
replace firmid = 832 if cname == "MICHIGAN PENINSULAR CAR CO." & firmid == .
replace firmid = 303 if cname == "NATIONAL LEAD CO." & firmid == .
replace firmid = 833 if cname == "NATIONAL SALT CO" & firmid == .
replace firmid = 834 if firmid == . & ///
	inlist(cname, "NATIONAL STARCH", "NATIONAL STRACH MANUFACTURING CO.")
replace firmid = 835 if firmid == . & ///
	inlist(cname, "NORTH AMERICAN CO", "NORTH AMERICAN CO.")
replace firmid = 836 if cname == "PEOPLE'S GAS LT & COKE" & firmid == .
replace firmid = 837 if firmid == . & ///
	inlist(cname, "PHILADELPHIA CO", "PHILADELPHIA COMPANY")
replace firmid = 838 if cname == "PULLMAN'S PALACE CAR CO." & firmid == .
replace firmid = 839 if cname == "STANDARD ROPE & TWINE" & firmid == .
replace firmid = 840 if firmid == . & ///
	inlist(cname, "TENNESSEE COAL & IRON", "TENNESSEE COAL, IRON AND RAILROAD CO.")
replace firmid = 841 if cname == "THIRD AVENUE" & firmid == .
replace firmid = 842 if cname == "TINGUARO SUGAR CO." & firmid == .
replace firmid = 843 if cname == "TWIN CITY RAPID TRANSIT" & firmid == .
replace firmid = 844 if cname == "US LEATHER" & firmid == .
replace firmid = 750 if cname == "WELLS. FARGO & CO. EXPRESS" & firmid == .
replace firmid = 845 if cname == "WESTERN UNION TELEGRAPH" & firmid == .

drop cohort
bys firmid: egen min_yr = min(year_std)
gen cohort = 1880 if min_yr == 1880
forval y = 1890(10)1910 {
	local y_5 = `y' - 5
	replace cohort = `y' if inlist(min_yr, `y_5', `y')
}