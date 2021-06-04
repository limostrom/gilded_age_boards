/*
uw_groups.do

*/

cap cd "C:/Users/lmostrom/Documents/Gilded Age Boards/Data/"
cap cd "C:/Users/17036/OneDrive/Documents/Gilded Age Boards/Data/"


#delimit ;
use UW_1880-1920_allnyse, clear;
keep if inlist(year, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920);
keep if inlist(cname, "Blair & Co", "Blair & Co Inc",
					"First National",
					"Hallgarten & Co",
					"Kidder Peabody & Co",
					"Kuhn Loeb & Co",
					"Lee Higginson & Co") |
		inlist(cname, "Morgan J P & Co",
					"National City", "National City Co",
					"Read Wm A & Co", "Dillon Read & Co",
					"Speyer & Co");

save "UW_1880-1920_top10.dta", replace;