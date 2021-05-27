/*
Lauren Mostrom
Merging the Railroads & Underwriters
*/

clear all
cap log close
pause on
set more off

cap cd  "/Users/laurenmostrom/Dropbox/Mostrom_Thesis_2018/Merges"
cap cd "C:/Users/lmostrom/Documents/PersonalResearch/Thesis/Merges"

#delimit ;

********************************************************************************;
************** CLEANING FULL NAMES AND SAVING WHOLE LISTS **********************;
********************************************************************************;

*Railroads;
/*
import excel "RR_Addenda_1905.xlsx", first;
gen str1 firsti = substr(first, 1, 1);
gen str1 middlei = substr(middle, 1, 1);
gen fullname_m = firsti + middlei + last + suffix;

assert fullname_m != "" ;
save "RR_Addenda_1905.dta", replace;

cd ../../ ;
use RR_clean, clear;
keep if inlist(year, 1911, 1915, 1920);
append using "RR_1880-1905_clean.dta";
append using "RR_Addenda_1905.dta";
gen year_std = year;
replace year_std = 1900 if year == 1901;
replace year_std = 1910 if year == 1911;

drop if cname == "Manhattan Beach Company";
*this is a utility company;



***********************************;
*Filling in the 1907 boards for companies missing in 1905
* (but listed in 1901 and 1907);
replace year_std = 1905 if year == 1907 &
							cname == "Chic Rock Island & Pacific";
replace year_std = 1905 if year == 1907 &
							cname == "Chicago & Alton";
replace year_std = 1905 if year == 1907 &
							cname == "Kanawha & Michigan";
replace year_std = 1905 if year == 1907 &
							cname == "Lake Erie & Western";
replace year_std = 1905 if year == 1907 &
							cname == "Minn St Paul & S S M";
replace year_std = 1905 if year == 1907 &
							cname == "NY Chicago & St Louis";
replace year_std = 1905 if year == 1907 &
							cname == "Pitts Cin Chic & St Louis";
replace year_std = 1905 if year == 1907 &
							cname == "St Joseph & Grand Island";
replace year_std = 1905 if year == 1907 &
							cname == "St Louis Southwestern";
drop if year_std == 1907;

***********************************;
*Saving the list and then cleaning more names;
gen sector = "RR";

replace fullname_m = subinstr(fullname_m, "_s", "", .) if substr(fullname_m, -2, .) == "_s";
save "RR_1880-1920.dta", replace;

sort last fullname_m year;

drop if fullname_m == fullname_m[_n-1] & year == year[_n-1] & cname == cname[_n-1];

***********************************;
* This block finds the people with Junior in their name whose name later appears
* without the suffix. We think these people probably dropped the junior when their
* father passed;
#delimit ;
drop flag fullname_nojr;

gen flag = suffix == "Jr" | suffix == "2d";
gen fullname_nojr = substr(fullname_m, 1, strlen(fullname_m)-2) if flag == 1;

levelsof fullname_nojr, local(juniors);
foreach name in `juniors' {;
	replace flag = 1 if inlist(fullname_m, "`name'");
};
replace fullname_nojr = fullname_m if flag == 1 & fullname_nojr == "";

replace suffix = "Jr" if fullname_m == "WEndicott" & year > 1895;
replace suffix = "Jr" if fullname_m == "JLGardner" & year > 1880;
replace suffix = "Jr" if fullname_m == "RIrvin" & year > 1885;
replace suffix = "Jr" if fullname_m == "JKing" & year > 1880;
replace suffix = "Jr" if fullname_m == "HWOliver" & year > 1890;
replace suffix = "Jr" if fullname_m == "CAPeabody" & year > 1901;
replace suffix = "Jr" if fullname_m == "WWhitewright" & year > 1880;

sort flag last fullname_nojr year;
***********************************;

*Fixing different people with identical fullname codes;
replace fullname_m = "AlCox" if first == "Allyn" & last == "Cox";
*To distinguish him from Attilla;
replace fullname_m = "ElHiggins" if first == "Elias" & fullname_m == "EHiggins";
replace fullname_m = "EuHiggins" if first == "Eugene" & fullname_m == "EHiggins";
replace fullname_m = "JeMilbank" if first == "Jeremiah" & last == "Milbank";
*To distinguish him from Joseph Milbank;
replace fullname_m = "JoSharp" if first == "John" & last == "Sharp";
replace fullname_m = "JaSharp" if first == "James" & last == "Sharp";
replace fullname_m = "ElSmith" if first == "Elijah" & last == "Smith";
replace fullname_m = "EdSmith" if first == "Edmund" & last == "Smith";
replace fullname_m = "MoHSmith" if first == "Morris" & last == "Smith";
*There might be other Morris Smiths - double check if they match (not CBs);
*Distinguishes him from Milton H Smith;
replace fullname_m = "JoRTaylor" if first == "John" & last == "Taylor";
replace fullname_m = "JaRTaylor" if substr(first, 1, 2) == "Ja" & last == "Taylor";
*There might be others - double check if they match (not CBs);
replace fullname_m = "ArBrown" if first == "Archer" & last == "Brown";
replace fullname_m = "AlBrown" if substr(first, 1, 4) == "Alex" & last == "Brown";
replace fullname_m = "JcCampbell" if first == "Jacob" & fullname_m == "JCampbell";
replace fullname_m = "JmCampbell" if first == "James" & fullname_m == "JCampbell";
replace fullname_m = "ChClark" if first == "Charles" & fullname_m == "CClark";
replace fullname_m = "CyClark" if first == "Cyrus" & fullname_m == "CClark";
replace fullname_m = "ClClark" if first == "Clarence" & fullname_m == "CClark";
replace fullname_m = "AlFink" if first == "Albert" & fullname_m == "AFink";
replace fullname_m = "OlAmes" if first == "Oliver" & last == "Ames";
	replace fullname_m = fullname_m + suffix if fullname_m = "OlAmes";
replace fullname_m = "OkAmes" if first == "Oakes" & last == "Ames";
replace fullname_m = "JoSharp" if first == "John" & last == "Sharp";
replace fullname_m = "JaSharp" if first == "James" & last == "Sharp";
replace fullname_m = "JaWilliams" if first == "James" & fullname_m == "JWilliams";
replace fullname_m = "JoWilliams" if substr(first, 1, 3) == "Jos" & fullname_m == "JWilliams";
replace fullname_m = "WaHTaylor" if inlist(first, "W.", "Walter") & fullname_m == "WHTaylor";
replace fullname_m = "WmHTaylor" if inlist(first, "Wm", "William") & fullname_m == "WHTaylor";
replace fullname_m = "JoRichardson" if first == "Joseph" & fullname_m == "JRichardson";
*No JHGilberts;
*No JGoldthwaits;
*No AHobarts;
*No JPLymans;
*No NPecks;
*No JRogerses;
*The GWSmiths are a problem because these lists don't say their full middle names;
*No SSmiths;
*No TSmiths;
*No LSterns;
replace fullname_m = "AmaStone" if first == "Amasa" & fullname_m == "AStone";
*No DTaylors;
*No JThompsons;
*No JThomsons;
*No ETownsends;
*No ATurners;
*No JTurners;

* No John T. Willets or John T. Willetts;
* No Louis C. Raegener or Louis C. Racgener;
* No August Fink or August Finck but there is an Albert Fink;

* Add in RRids;
merge m:1 cname using RRs;
drop _merge;

drop if first == "" & middle == "" & last == "";

replace RRid = 75 if RRid == . & cname == "Allegheny & Western";
replace RRid = 1 if RRid == . & inlist(cname, "Ann Arbor",
									"TOLEDO, ANN ARBOR & NORTH MICHIGAN",
									"TOLEDO, ANN ARBOR & NORTH MICHIGAN RAILWAY CO.");
replace RRid = 2 if RRid == . & inlist(cname, "Atchison Topeka & Santa Fe",
									"ATCHISON, TOPEKA & SANTA FE",
									"ATCHISON, TOPEKA & SANTA FE RAILWAY CO.");
replace RRid = 3 if RRid == . & cname == "Atlantic Coast Line RR";
replace RRid = 76 if RRid == . & cname == "Atlanta Birm & Atlan";
replace RRid = 101 if RRid == . & inlist(cname, "ALBANY & SUSQUEHANNA",
									"Albany and Susquehanna Railroad");
replace RRid = 102 if RRid == . & inlist(cname, "ATLANTIC & PACIFIC",
									"ATLANTIC & PACIFIC RAILROAD CO.");

replace RRid = 6 if RRid == . & inlist(cname, "Baltimore & Ohio",
									"BALTIMORE & OHIO",
									"BALTIMORE & OHIO RAILROAD CO.",
									"Baltimore and Ohio Railroad");
replace RRid = 7 if RRid == . & inlist(cname, "Buffalo Rochester & Pittsb",
									"BUFFALO, ROCHESTER & PITTSBURGH",
									"BUFFALO, ROCHESTER & PITTSBURGH RAILWAY CO.");
replace RRid = 77 if RRid == . & cname == "Buffalo & Susq";
replace RRid = 103 if RRid == . & cname == "BRUNSWICK & WESTERN";
replace RRid = 104 if RRid == . & inlist(cname, "BURLINGTON, CEDAR RAPIDS & NORTHERN",
									"Burlington Cedar Rapids & Northern",
									"Burlington, Cedar Rapids & Northern Railway",
									"Burlington, Cedar Rapids and Northern Railway");
replace RRid = 105 if RRid == . & inlist(cname, "Boston and New York Air-Line Railroad",
									"Boston and New York Air-line Railroad");

replace RRid = 106 if RRid == . & inlist(cname, "CANADA SOUTHERN RAILWAY",
									"Canada Southern",
									"Canada Southern Railway");
replace RRid = 8 if RRid == . & inlist(cname, "Canadian Pacific",
									"CANADIAN PACIFIC RAILWAY CO.",
									"CANADIAN PACIFIC RAILWAY COMPANY",
									"Canadian Pacific Railway");
replace RRid = 107 if RRid == . & inlist(cname, "CEDAR FALLS & MINNESOTA RAILROAD CO.",
									"CEDAR FALLS AND MINNESOTA RAILROAD COMPANY",
									"Cedar Falls and Minnesota Railroad");
replace RRid = 108 if RRid == . & inlist(cname, "CENTRAL PACIFIC RAILROAD COMPANY",
									"CENTRAL PACIFIC RR.",
									"Central Pacific Railroad");
replace RRid = 44 if RRid == . & inlist(cname, "Central of New Jersey",
									"CENTRAL RAILROAD COMPANY OF NEW JERSEY",
									"Central Railroad of New Jersey",
									"Central Railroad Of New Jersey");
replace RRid = 109 if RRid == . & cname == "CHARLOTTE, COLUMBIA AND AUGUSTA RAILROAD";
replace RRid = 12 if RRid == . & inlist(cname, "Chesapeake & Ohio",
									"CHESAPEAKE & OHIO RAILWAY CO.",
									"Chesapeake and Ohio Railway",
									"CHESAPEAKE, OHIO & SOUTHWESTERN");
replace RRid = 18 if RRid == . & cname == "Chic Great West";
replace RRid = 54 if RRid == . & inlist(cname, "Chicago & Alton",
									"CHICAGO & ALTON",
									"CHICAGO & ALTON RAILROAD CO.",
									"Chicago and Alton Railroad");
replace RRid = 111 if RRid == . & inlist(cname, "CHICAGO & EASTERN ILLINOIS",
									"CHICAGO & EASTERN ILLINOIS RAILROAD CO.",
									"Chicago & Eastern Ill");
replace RRid = 14 if RRid == . & inlist(cname, "Chicago & North Western",
									"CHICAGO & NORTHWESTERN",
									"CHICAGO & NORTHWESTERN RAILWAY CO.",
									"Chicago and North-western Railway",
									"Chicago and Northwestern Railway");
replace RRid = 16 if RRid == . & inlist(cname, "Chicago Burlington & Quincy",
									"CHICAGO, BURLINGTON & QUINCY",
									"CHICAGO, BURLINGTON & QUINCY RAILROAD CO.",
									"Chicago, Burlington and Quincy Railroad");
replace RRid = 19 if RRid == . & inlist(cname, "Chicago Milwaukee & St Paul",
									"CHICAGO, MILWAUKEE & ST. PAUL",
									"CHICAGO, MILWAUKEE & ST. PAUL.",
									"Chicago, Milwaukee and St. Paul Railway");
replace RRid = 15 if RRid == . & inlist(cname, "Chicago St P Minn & Omaha",
									"CHICAGO, ST. PAUL, MINNEAPOLIS & OMAHA RAILWAY CO.",
									"CHICAGO, ST. PAUL, MINNEAPOLIS AND OMAHA RAILWAY CO.",
									"Chicago, St. Paul, Minneapolis and Omaha Railway");
replace RRid = 20 if RRid == . & cname == "Chicago Terminal Transfer";
replace RRid = 46 if inlist(cname, "Chicago, Rock Island & Pacific Railway Co",
									"CHICAGO, ROCK ISLAND & PACIFIC",
									"CHICAGO, ROCK ISLAND & PACIFIC RAILWAY CO.",
									"Chic Rock Island & Pacific",
									"Chicago, Rock Island and Pacific Railroad",
									"Chicago, Rock Island and Pacific Railway");
replace RRid = 246 if inlist(cname, "Rock Island Co",
									"Rock Island Company");
replace RRid = 112 if RRid == . & inlist(cname, "CHICAGO, ST. LOUIS & PITTSBURGH",
									"Chicago, St. Louis and Pittsburgh Railroad");
replace RRid = 113 if RRid == . & cname == "CINCINNATI, WASHINGTON & BALTIMORE";
replace RRid = 63 if RRid == . & inlist(cname, "Cleve Cincin Chic & St Louis",
									"CLEVELAND, CINCINNATI, CHICAGO & ST. LOUIS RAILWAY CO.",
									"CLEVELAND, CINCINNATI, ST. LOUIS & CHICAGO");
replace RRid = 79 if RRid == . & inlist(cname, "Cleveland & Pitts",
										"CLEVELAND & PITTSBURGH",
										"CLEVELAND & PITTSBURGH RAILROAD CO.",
										"Cleveland and Pittsburgh Railroad");
replace RRid = 17 if RRid == . & cname == "Colorado & Southern";
replace RRid = 114 if RRid == . & cname == "COLUMBIA & GREENVILLE";
replace RRid = 115 if RRid == . & inlist(cname, "COLUMBUS, HOCKING VALLEY & TOLEDO",
										"COLUMBUS, HOCKING VALLEY & TOLEDO RAILWAY CO.");
replace RRid = 27 if RRid == . & inlist(cname, "Central Iowa Railway",
										"IOWA CENTRAL RAILWAY CO.",
										"Iowa Central");
replace RRid = 118 if RRid == . & inlist(cname, "Chicago, St Louis and New Orleans Railroad",
										"Chicago, St. Louis and New Orleans Railroad");
replace RRid = 119 if RRid == . & cname == "Chicago, St. Paul and Minneapolis Railway";
replace RRid = 120 if RRid == . & cname == "Cleve Lorain & Wheeling";
replace RRid = 121 if RRid == . & inlist(cname, "Cleveland, Columbus, Cincinnati, and Indianapolis Railway",
										"Cleveland, Columbus, Cincinnati and Indianapolis Railway");
replace RRid = 122 if RRid == . & cname == "Columbus, Chicago & Indiana Central Railway";
replace RRid = 21 if RRid == . & cname == "Cripple Creek Cent";
replace RRid = 123 if RRid == . & cname == "Cumberland and Pennsylvania Railroad";

replace RRid = 59 if RRid == . & inlist(cname, "Delaware & Hudson",
										"DELAWARE & HUDSON CANAL CO.",
										"Delaware and Hudson Canal Company");
replace RRid = 60 if RRid == . & inlist(cname, "Delaware Lackaw & Western",
										"DELAWARE, LACKAWANNA & WESTERN",
										"DELAWARE, LACKAWANNA & WESTERN RAILROAD CO.",
										"Delaware, Lackawanna and Western Railroad");
replace RRid = 22 if RRid == . & inlist(cname, "Denver & Rio Grande",
										"DENVER & RIO GRANDE",
										"DENVER & RIO GRANDE RAILROAD CO.",
										"Denver and Rio Grande Railway");
replace RRid = 222 if RRid == . & inlist(cname, "RIO GRANDE WESTERN",
										"RIO GRANDE WESTERN RAILWAY CO.",
										"Rio Grande Western");
replace RRid = 124 if RRid == . & cname == "DENVER, TEXAS & FORT WORTH";
replace RRid = 125 if RRid == . & cname == "Denver & Southwestern";
replace RRid = 32 if RRid == . & inlist(cname, "Des Moines & Ft Dodge",
										"DES MOINES AND FORT DODGE RAILROAD");
replace RRid = 23 if RRid == . & cname == "Detroit & Mackinac";
replace RRid = 126 if RRid == . & cname == "Dubuque and Sioux City Railroad";
replace RRid = 9 if RRid == . & cname == "Duluth South Shore & Atlan";

replace RRid = 127 if RRid == . & inlist(cname, "EAST TENNESSEE, VIRGINIA & GEORGIA",
										"East Tennessee, Virginia and Georgia Railroad");
replace RRid = 128 if RRid == . & cname == "ELIZABETHTOWN, LEXINGTON AND BIG SANDY RAILROAD CO.";
replace RRid = 129 if RRid == . & inlist(cname, "EVANSVILLE & TERRE HAUTE",
										"EVANSVILLE & TERRE HAUTE RAILROAD CO.",
										"Evansville & Terra Haute",
										"Evansville and Terre Haute Railroad");
replace RRid = 24 if RRid == . & inlist(cname, "Erie",
										"NEW YORK, LAKE ERIE & WESTERN",
										"NEW YORK, LAKE ERIE & WESTERN RAILROAD CO.",
										"New York, Lake Erie and Western Railroad");
replace RRid = 80 if RRid == . & cname == "Erie & Pittsburgh";

replace RRid = 25 if RRid == . & inlist(cname, "Great Northern",
										"GREAT NORTHERN RAILWAY CO.",
										"Great Northern");
replace RRid = 61 if RRid == . & inlist(cname, "Green Bay & Western",
										"GREEN BAY, WINONA & ST. PAUL RAILROAD CO.",
										"Green Bay, Winona and St. Paul Railroad",
										"GREEN BAY, WINONA & ST. PAUL");
replace RRid = 81 if RRid == . & cname == "Gulf Mob & Nor";

replace RRid = 194 if RRid == . & cname == "Hannibal and St. Joseph Railroad";
replace RRid = 131 if RRid == . & inlist(cname, "HARLEM RIVER AND PORT CHESTER RAILROAD",
										"Harlem River and Portchester Railroad");
drop if cname == "Harlem Extension Railroad, South";
* ^president only;
replace RRid = 132 if RRid == . & inlist(cname, "HOUSTON & TEXAS CENTRAL",
										"Houston and Texas Central Railroad",
										"Houston and Texas Central Railway");
replace RRid = 13 if RRid == . & cname == "Hocking Valley";

replace RRid = 26 if RRid == . & inlist(cname, "Illinois Central",
										"ILLINOIS CENTRAL",
										"ILLINOIS CENTRAL RAILROAD CO.",
										"Illinois Central Railroad");
replace RRid = 133 if RRid == . & cname == "Indiana, Bloomington and Western Railway";
replace RRid = 134 if RRid == . & cname == "Indianapolis, Cincinnati & Lafayette Railroad";
replace RRid = 135 if RRid == . & cname == "INTERNATIONAL & GREAT NORTHERN";

replace RRid = 136 if RRid == . & inlist(cname, "KEOKUK & DES MOINES",
										"KEOKUK & DES MOINES RAILROAD CO.",
										"KEOKUK AND DES MOINES RAILROAD",
										"Keokuk and Des Moines Railroad");
replace RRid = 137 if RRid == . & cname == "KINGSTON & PEMBROKE";
replace RRid = 28 if RRid == . & cname == "Kanawha & Michigan";
replace RRid = 29 if RRid == . & cname == "Kansas City Southern";

replace RRid = 65 if RRid == . & inlist(cname, "Lake Erie & Western",
										"LAKE ERIE & WESTERN",
										"LAKE ERIE & WESTERN RAILROAD CO.",
										"Lake Erie and Western Railway");
replace RRid = 66 if RRid == . & inlist(cname, "Lake Shore & Mich Southern",
										"LAKE SHORE & MICHIGAN SOUTHERN",
										"LAKE SHORE & MICHIGAN SOUTHERN RAILWAY CO.",
										"Lake Shore and Michigan Southern Railway",
										"Lakeshore and Michigan Southern Railway");
replace RRid = 30 if RRid == . & cname == "Lehigh Valley";
replace RRid = 71 if RRid == . & inlist(cname, "Long Island",
										"LONG ISLAND",
										"LONG ISLAND RAILROAD CO.",
										"Long Island Railroad");
replace RRid = 4 if RRid == . & inlist(cname, "Louisville & Nashville",
										"LOUISVILLE & NASHVILLE",
										"LOUISVILLE & NASHVILLE RAILROAD CO.",
										"Louisville and Nashville Railroad");
replace RRid = 138 if RRid == . & inlist(cname, "LOUISVILLE, NEW ALBANY & CHICAGO",
										"LOUISVILLE, NEW ALBANY & CHICAGO.",
										"Louisville, New Albany and Chicago Railway",
										"Chicago Indianapolis & Louisville");
replace RRid = 139 if RRid == . & cname == "Ligonier Valley Railroad";
replace RRid = 140 if RRid == . & cname == "Louisiana and Missouri River Railroad";					

replace RRid = 141 if RRid == . & cname == "MAHONING COAL RAILROAD";
replace RRid = 142 if RRid == . & inlist(cname, "MANHATTAN",
										"MANHATTAN RAILWAY CO.",
										"Manhattan Railway");
replace RRid = 143 if RRid == . & inlist(cname, "MARQUETTE, HOUGHTON & ONTONAGON RAILROAD COMPANY",
										"MARQUETTE, HOUGHTON AND ONTONAGON RAILROAD COMPANY");
replace RRid = 144 if RRid == . & inlist(cname, "MEXICAN CENTRAL",
										"MEXICAN CENTRAL RAILWAY CO., LIMITED",
										"Mexican Central");
replace RRid = 145 if RRid == . & inlist(cname, "MEXICAN NATIONAL",
										"MEXICAN NATIONAL RAILROAD CO.",
										"Mexican National");
replace RRid = 67 if RRid == . & inlist(cname, "Michigan Central",
										"MICHIGAN CENTRAL",
										"MICHIGAN CENTRAL RAILROAD CO.",
										"Michigan Central Railroad");
replace RRid = 146 if RRid == . & inlist(cname, "MILWAUKEE, LAKE SHORE & WESTERN",
										"Milwaukee, Lake Shore and Western Railway");
replace RRid = 10 if RRid == . & inlist(cname, "Minn St Paul & S S M",
										"Minn St. Paul & S S M");
replace RRid = 31 if RRid == . & inlist(cname, "Minneapolis & St Louis",
										"MINNEAPOLIS & ST. LOUIS",
										"Minneapolis and St. Louis Railway");
replace RRid = 33 if RRid == . & inlist(cname, "Missouri Kansas & Texas",
										"MISSOURI, KANSAS & TEXAS",
										"MISSOURI, KANSAS & TEXAS RAILWAY CO.",
										"Missouri, Kansas and Texas Railway");
replace RRid = 34 if RRid == . & inlist(cname, "Missouri Pacific",
										"MISSOURI PACIFIC",
										"MISSOURI PACIFIC RAILWAY CO.",
										"Missouri Pacific Railway");
replace RRid = 147 if RRid == . & inlist(cname, "MOBILE & OHIO",
										"MOBILE & OHIO RAILROAD CO.",
										"Mobile & Ohio",
										"Mobile and Ohio Railroad");
replace RRid = 148 if RRid == . & inlist(cname, "MORRIS AND ESSEX RAILROAD",
										"MORRIS AND ESSEX RR.",
										"Morris & Essex Railroad Co",
										"Morris and Essex Railroad");
replace RRid = 149 if RRid == . & cname == "Marietta and Cincinnati Railroad";
replace RRid = 150 if RRid == . & cname == "Memphis and Charleston Railroad";
replace RRid = 151 if RRid == . & cname == "Metropolitan Elevated Railway";

replace RRid = 36 if RRid == . & cname == "NO Mobile & Chicago";
replace RRid = 62 if RRid == . & inlist(cname, "NY Central & Hudson River",
										"NEW YORK CENTRAL & HUDSON RIVER",
										"NEW YORK CENTRAL & HUDSON RIVER RAILROAD CO.",
										"New York Central & Hudson River Railroad");
replace RRid = 68 if RRid == . & inlist(cname, "NY Chicago & St Louis",
										"NY Chicago & St. Louis",
										"NEW YORK, CHICAGO & ST. LOUIS",
										"NEW YORK, CHICAGO & ST. LOUIS RAILROAD CO.",
										"New York, Chicago and St. Louis Railway");
replace RRid = 37 if RRid == . & inlist(cname, "NY New Haven & Hartford",
										"NEW YORK, NEW HAVEN & HARTFORD",
										"NEW YORK, NEW HAVEN & HARTFORD RAILROAD CO.",
										"New York, New Haven and Hartford Railroad",
										"New York, New Haven, and Hartford Railroad");
replace RRid = 38 if RRid == . & inlist(cname, "NY Ontario & Western",
										"NEW YORK, ONTARIO AND WESTERN RAILWAY COMPANY",
										"New York, Ontario and Western Railway");
replace RRid = 5 if RRid == . & inlist(cname, "Nashville Chatt & St Louis",
										"NASHVILLE, CHATTANOOGA & ST. LOUIS",
										"NASHVILLE, CHATTANOOGA & ST. LOUIS RAILWAY",
										"Nashville, Chattanooga and St. Louis Railway");
replace RRid = 35 if RRid == . & cname == "National Rys of Mex";
replace RRid = 82 if RRid == . & cname == "New Orleans Tex & Mex";
replace RRid = 152 if RRid == . & inlist(cname, "NEW YORK & NEW ENGLAND",
										"NEW YORK AND NEW ENGLAND RAILROAD COMPANY",
										"New York and New England Railroad");
replace RRid = 153 if RRid == . & cname == "NEW YORK & NORTHERN";
replace RRid = 154 if RRid == . & inlist(cname, "NEW YORK, BROOKLYN & MANHATTAN BEACH RAILWAY CO.",
										"NEW YORK, BROOKLYN AND MANHATTAN BEACH RAILWAY");
replace RRid = 155 if RRid == . & inlist(cname, "NEW YORK, LACKAWANNA & WESTERN RAILROAD CO.",
										"New York, Lackawanna and Western Railroad",
										"NEW YORK, LACKAWANNA & WESTERN");
replace RRid = 157 if RRid == . & inlist(cname, "NEW YORK, SUSQUEHANNA & WESTERN",
										"NEW YORK, SUSQUEHANNA & WESTERN RAILROAD CO.",
										"New York, Susquehanna and Western Railroad");
replace RRid = 39 if RRid == . & inlist(cname, "Norfolk & Western",
										"NORFOLK & WESTERN",
										"NORFOLK & WESTERN RAILROAD CO.",
										"Norfolk and Western Railroad");
replace RRid = 40 if RRid == . & cname == "Norfolk Southern";
replace RRid = 41 if RRid == . & inlist(cname, "Northern Pacific",
										"NORTHERN PACIFIC",
										"NORTHERN PACIFIC RAILROAD CO.",
										"Northern Pacific Railroad");
replace RRid = 158 if RRid == . & cname == "NORTHERN PACIFIC TERMINAL CO. OF OREGON";
replace RRid = 159 if RRid == . & cname == "New York Central, Hudson River and Fort Orange Rail Road";
replace RRid = 160 if RRid == . & inlist(cname, "New York Elevated Railroad",
										"New York and Elevated Railroad");

replace RRid = 161 if RRid == . & inlist(cname, "OHIO & MISSISSIPPI",
										"Ohio and Mississippi Railway");
replace RRid = 162 if RRid == . & inlist(cname, "OHIO SOUTHERN",
										"Ohio Southern Railroad");
replace RRid = 163 if RRid == . & cname == "OHIO, INDIANA & WESTERN";
replace RRid = 164 if RRid == . & inlist(cname, "OREGON & TRANSCONTINENTAL CO.",
										"Oregon and Transcontinental Company");
replace RRid = 165 if RRid == . & inlist(cname, "OREGON IMPROVEMENT COMPANY",
										"Oregon Improvement Company",
										"THE OREGON IMPROVEMENT COMPANY");
replace RRid = 166 if RRid == . & inlist(cname, "OREGON RAILWAY & NAVIGATION CO.",
										"OREGON RAILWAY AND NAVIGATION COMPANY",
										"Oregon Railway and Navigation Co.",
										"Oregon Railway and Navigation");
replace RRid = 167 if RRid == . & inlist(cname, "OREGON SHORT LINE & UTAH NORTHERN RAILWAY CO.",
										"OREGON SHORT LINE AND UTAH NORTHERN RAILWAY",
										"Oregon Short Line Railway");

replace RRid = 168 if RRid == . & inlist(cname, "PANAMA",
										"PANAMA RAILROAD CO.",
										"Panama Railroad");
replace RRid = 70 if RRid == . & inlist(cname, "Pennsylvania RR",
										"PENNSYLVANIA RAILROAD",
										"PENNSYLVANIA RAILROAD CO.",
										"Pennsylvania Railroad");
replace RRid = 64 if RRid == . & inlist(cname, "Peoria & Eastern",
										"PEORIA & EASTERN RAILROAD CO.",
										"PEORIA AND EASTERN");
replace RRid = 169 if RRid == . & inlist(cname, "PEORIA, DECATUR & EVANSVILLE",
										"PEORIA, DECATUR & EVANSVILLE RAILWAY CO.",
										"Peoria, Decatur & Evansville",
										"Peoria, Decatur and Evansville Railway");
replace RRid = 42 if RRid == . & cname == "Pere Marquette";
replace RRid = 85 if RRid == . & cname == "Pitts & West Virginia";
replace RRid = 171 if RRid == . & inlist(cname, "PITTSBURGH & WESTERN",
										"PITTSBURGH & WESTERN RAILROAD CO.");
replace RRid = 72 if RRid == . & inlist(cname, "Pitts Cin Chic & St Louis",
										"Pitt Cin Chic & St. Louis",
										"PITTSBURGH, CINCINNATI, CHICAGO & ST. LOUIS");
replace RRid = 172 if RRid == . & inlist(cname, "PITTSBURGH, FORT WAYNE AND CHICAGO RAILWAY COMPANY",
										"Pittsburgh Ft Wayne & Chicago",
										"Pittsburgh, Fort Wayne and Chicago Railway");

replace RRid = 173 if RRid == . & inlist(cname, "RENSSELAER & SARATOGA RAILROAD CO.",
										"RENSSELAER AND SARATOGA RAILROAD",
										"Rensselaer and Saratoga Railroad");
replace RRid = 178 if RRid == . & cname == "Richmond and Alleghany Railroad";
replace RRid = 175 if RRid == . & inlist(cname, "RICHMOND AND WEST POINT TERMINAL RAILWAY AND WAREHOUSE COMPANY",
										"Richmond and West Point Terminal Railway and Warehouse Co.");
replace RRid = 275 if RRid == . & inlist(cname, "RICHMOND & DANVILLE",
										"Richmond and Danville Railroad");
replace RRid = 43 if RRid == . & inlist(cname, "Reading Co", "Reading",
										"PHILADELPHIA & READING",
										"PHILADELPHIA & READING RAILROAD CO.",
										"Philadelphia and Reading Railroad");
replace RRid = 179 if RRid == . & cname == "Rochester and Pittsburgh Railroad";
replace RRid = 177 if RRid == . & inlist(cname, "ROME, WATERTOWN & OGDENSBURG RAILROAD CO.",
										"ROME, WATERTOWN & OGDENSBURGH",
										"Rome, Watertown and Ogdensburg Railroad");
replace RRid = 69 if RRid == . & cname == "Rutland";

replace RRid = 50 if RRid == . & cname == "Seaboard Air Line";
replace RRid = 180 if RRid == . & cname == "SOUTH CAROLINA";
replace RRid = 51 if RRid == . & inlist(cname, "Southern",
										"SOUTHERN RAILWAY CO.");
replace RRid = 74 if RRid == . & inlist(cname, "Southern Pacific",
										"SOUTHERN PACIFIC COMPANY");
replace RRid = 47 if RRid == . & inlist(cname, "St Joseph & Grand Island",
										"St. Joseph & Grand");
replace RRid = 185 if RRid == . & cname == "St Lawrence & Adirondack";
replace RRid = 186 if RRid == . & inlist(cname, "St Louis, Iron Mountain and Southern RR.",
										"St. Louis, Iron Mountain and Southern RR.");
replace RRid = 48 if RRid == . & inlist(cname, "St Louis & San Francisco",
										"ST. LOUIS & SAN FRANCISCO",
										"St Louis and San Francisco Railway",
										"St. Louis and San Francisco Railway");
replace RRid = 49 if RRid == . & inlist(cname, "St Louis Southwestern",
										"St. Louis Southwestern",
										"ST. LOUIS SOUTHWESTERN RAILWAY CO.",
										"ST. LOUIS SOUTHWESTERN RAILWAY COMPANY");
replace RRid = 249 if RRid == . & cname == "ST. LOUIS, ARKANSAS & TEXAS";
replace RRid = 181 if RRid == . & inlist(cname, "ST. LOUIS, ALTON & TERRE HAUTE",
										"ST. LOUIS, ALTON & TERRE HAUTE RAILROAD CO.",
										"St Louis, Alton and Terre Haute Railroad",
										"St. Louis, Alton and Terre Haute Railroad");
replace RRid = 187 if RRid == . & cname == "St. Paul and Sioux City Railroad"; 
replace RRid = 183 if RRid == . & inlist(cname, "ST. PAUL & DULUTH",
										"ST. PAUL & DULUTH RAILROAD CO.");
replace RRid = 184 if RRid == . & inlist(cname, "ST. PAUL MINNEAPOLIS AND MANITOBA RAILWAY",
										"ST. PAUL, MINNEAPOLIS & MANITOBA RAILWAY CO.",
										"St. Paul, Minneapolis and Manitoba Railway");

replace RRid = 52 if RRid == . & inlist(cname, "Texas & Pacific",
										"TEXAS & PACIFIC",
										"TEXAS & PACIFIC RAILWAY CO.",
										"Texas and Pacific Railway");
replace RRid = 188 if RRid == . & inlist(cname, "TOLEDO & OHIO CENTRAL",
										"TOLEDO & OHIO CENTRAL RAILWAY CO.",
										"Toledo and Ohio Central Railroad");
replace RRid = 189 if RRid == . & cname == "TOLEDO, PEORIA & WESTERN";
replace RRid = 53 if RRid == . & cname == "Toledo St Louis & Western";

replace RRid = 55 if RRid == . & inlist(cname, "Union Pacific",
										"UNION PACIFIC",
										"UNION PACIFIC RAILWAY CO.",
										"Union Pacific Railway");
replace RRid = 190 if RRid == . & cname == "UTAH CENTRAL";

replace RRid = 73 if RRid == . & cname == "Vandalia";
replace RRid = 191 if RRid == . & inlist(cname, "VIRGINIA MIDLAND",
										"VIRGINIA MIDLAND RAILWAY CO.");

replace RRid = 56 if RRid == . & inlist(cname, "Wabash",
										"WABASH RAILROAD",
										"WABASH RAILROAD CO.",
										"Wabash, St. Louis and Pacific Railway");
replace RRid = 58 if RRid == . & cname == "Western Maryland";
replace RRid = 87 if RRid == . & cname == "Western Pacific";
replace RRid = 193 if RRid == . & cname == "Western Union Railroad";
replace RRid = 57 if RRid == . & inlist(cname, "Wheeling & Lake Erie",
										"WHEELING & LAKE ERIE",
										"WHEELING & LAKE ERIE RAILWAY CO.");
replace RRid = 11 if RRid == . & inlist(cname, "Wisconsin Central",
										"WISCONSIN CENTRAL");
drop if RRid == 70 & year <1895;
*Pennsylvania;
drop if RRid == 154;
*NY Brooklyn & Manhattan Beach - not actually NYSE-listed;
drop if RRid == 135;
*International & Great Northern was the wrong one;
drop if RRid == 165;
*Oregon Improvement - does own some railroad company stocks but also shipping and coal;


egen minyear = min(year_std), by(RRid);
gen cohort = 1880 if minyear == 1880;
foreach yr in 1890 1900 1910 1920 {;
	replace cohort = `yr' if inlist(minyear, `yr'-5, `yr');
};

cd Thesis/Merges;

save "RR_1880-1920_clean.dta", replace;
*/
/*
#delimit cr
* Fixing name typos in main original file
use "RR_1880-1920_clean.dta", clear
	keep if (first == "August" & last == "Belmonte" & year_std == 1880 & ///
				cname == "Cleveland and Pittsburgh Railroad") ///
			| (first == "E." & last == "Miller" & year_std == 1890 & ///
				cname == "CENTRAL PACIFIC RAILROAD COMPANY")
	replace last = "Belmont" if last == "Belmonte"
	replace middle = "H." if middle == "Ll."
	drop firsti middlei fullname_m
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	tempfile typos
	save `typos', replace
	
* Fixing the boards for Ches & Ohio and NYC & HR
import excel  "../../RR board corrections.xlsx", first case(lower) clear
	ren year year_std
	ren mi middle
	drop note remarks
	gen sector = "RR"
	gen minyear = 1880
	gen cohort = 1880
	gen flag = 0
	gen RRid = 62 if cname == "New York Central and Hudson River"
		replace RRid = 12 if cname == "Chesapeake and Ohio"
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	tempfile corrections1
	save `corrections1', replace	

* Fixing the boards for Canadian Pacific, Norfolk & Western, and Philadelphia & Reading
import excel "../../1890 and 1895 corrections.xlsx", first clear
	drop if cname == ""
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	tempfile corrections2
	save `corrections2', replace	
	
* Add 1900 RRs traded less frequently (not in original NYSE list)
import excel "../../New Data - 1900 Railroads.xlsx", first case(lower) clear
	gen newly_added = 1
	gen year_std = 1900 
	drop remarks
	gen sector = "RR"
	ren mi middle
	tostring suffix, replace
		replace suffix = "" if suffix == "."
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	gen RRid = 64 if cname == "Peoria & Eastern"
		replace RRid = 42 if cname == "Pere Marquette"
		replace RRid = 194 if cname == "Colorado Midland"
		replace RRid = 124 if cname == "Ft Worth & Den City"
		replace RRid = 195 if cname == "Ft Worth & Rio Grande"
		assert RRid != .
	tempfile new1900
	save `new1900', replace

* Add 1905 RRs traded less frequently (not in original NYSE list)
import excel "../../New Data - 1905 Railroads.xlsx", first case(lower) clear
	gen newly_added = 1
	gen year_std = 1905
	gen sector = "RR"
	ren mi middle
	tostring suffix, replace
		replace suffix = "" if suffix == "."
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	gen RRid = 120 if cname == "Cleveland Lorain & Wheeling"
		replace RRid = 50 if cname == "Seaboard Air Line"
		replace RRid = 138 if cname == "Chicago Indianapolis and Louisville"
		replace RRid = 42 if cname == "Pere Marquette"
		replace RRid = 1 if cname == "Ann Arbor"
		replace RRid = 129 if cname == "Evansville and Terra Haute"
		replace RRid = 61 if cname == "Green Bay & Western"
		replace RRid = 111 if cname == "Chicago and Eastern Illinois "
		replace RRid = 132 if cname == "Texas Central"
		replace RRid = 41  if cname == "Northern Pacific"
		replace RRid = 177 if cname == "Rome Watertown & Ogdensburg"
		replace RRid = 106 if cname == "Canada Southern"
		replace RRid = 69 if cname == "Rutland"
		replace RRid = 79 if cname == "Cleveland and Pittsburgh"
		replace RRid = 73 if cname == "Vandalia"
		replace RRid = 9 if cname == "Duluth South Shore and Atlantic"
		replace RRid = 144 if cname == "Mexican Central"
		replace RRid = 77 if cname == "Buffalo and Susquehanna"
		replace RRid = 40 if cname == "Norfok & Southern"
		replace RRid = 124 if cname == "Fort Worth and Denver City"
		replace RRid = 196 if cname == "Northern Central"
		drop if cname == "" & first == "" & last == ""

		assert RRid != .
	tempfile new1905
	save `new1905', replace

import excel "../../New Data - Misc Years.xlsx", first case(lower) clear
	drop remarks
	gen newly_added = 1
	ren year year_std
	gen sector = "RR"
	ren mi middle
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	gen RRid = 6 if cname == "Baltimore & Ohio"
		replace RRid = 77 if cname == "Buffalo and Susquehanna"
		replace RRid = 106 if cname == "Canada Southern"
		replace RRid = 46 if cname == "Chicago Rock Island & Pacific"
		replace RRid = 79 if cname == "Cleveland & Pittsburgh"
		replace RRid = 124 if cname == "Fort Worth and Denver City"
		replace RRid = 132 if cname == "Houston & Texas Central"
		replace RRid = 31 if cname == "Minneapolis & St. Louis"
		replace RRid = 168 if cname == "Panama"
		replace RRid = 172 if cname == "Pittsburgh Ft Wayne & Chicago"
	assert RRid != .
	
	tempfile newmisc
	save `newmisc', replace

use "RR_1880-1920_clean.dta", clear
	* typos
	drop if (first == "August" & last == "Belmonte" & year_std == 1880 & ///
				cname == "Cleveland and Pittsburgh Railroad") ///
			| (first == "E." & last == "Miller" & year_std == 1890 & ///
				cname == "CENTRAL PACIFIC RAILROAD COMPANY")
	* corrections1
	drop if (cname == "CHESAPEAKE, OHIO & SOUTHWESTERN" & year_std == 1890) ///
			| (cname == "New York Central, Hudson River and Fort Orange Rail Road" & year_std == 1885)
	* corrections2
	drop if (cname == "CANADIAN PACIFIC RAILWAY COMPANY" & year_std == 1890) ///
			| (cname == "NORFOLK & WESTERN RAILROAD CO." & year_std == 1895) ///
			| (cname == "PHILADELPHIA & READING RAILROAD CO." & year_std == 1895)

append using `typos'
append using `corrections1'
append using `corrections2'
append using `new1900'
append using `new1905'
append using `newmisc'
	drop minyear cohort
	bys RRid: egen minyear = min(year_std)
	replace newly_added = 0 if newly_added == .
	gen cohort = 1880 if minyear == 1880
	forval yr = 1890(10)1920 {
		replace cohort = `yr' if inlist(minyear, `yr'-5, `yr')
	}
replace fullname_m = subinstr(fullname_m, " ", "", .)
	
replace fullname_m = subinstr(fullname_m, "_s", "", .) if substr(fullname_m, -2, .) == "_s";

save "RR_boards_titlesmissing.dta", replace

*/
********************************************************************************;
/*
*Industrials;
#delimit;
cap cd "C:/Users/lmostrom/Documents/PersonalResearch/";


use "Ind_1890-1905_clean.dta", clear;

merge m:1 cname using industrialids, keep(1 3) nogen;

sort cid cname;
replace cid = cid+200;

replace cid = 1100 if cid == . & cname == "Amalgamated Copper";


use Ind_clean, clear;
keep if inlist(year, 1911, 1915, 1920);
replace cid = cid +200;
append using "Ind_1890-1905_clean.dta";
gen year_std = year;
replace year_std = 1900 if year == 1901;
replace year_std = 1910 if year == 1911;

gen sector = "Ind";

replace cname = "American Cotton Oil Co." if cname == "American Cotton Oil Trust";
replace cname = "Colorado Coal & Iron Developmemt Co."
			if cname == "Colorado Coal and Iron";
replace cname = "Columbus & Hocking Coal and Iron Co."
			if cname == "Columbus & Hocking Coal & Iron";
replace cname = "Consolidated Gas Co. of New York"
			if cname == "Consolidated Gas of New York";
replace cname = "Consolidation Coal Co." if cname == "Consolidation";
replace cname = "Equitable Gas Light Co. of New York" if cname == "Equitable Gas Light";
replace cname = "Pacific Mail Steamship Co." if cname == "Pacific Mail Steamship";
replace cname = "Pullman's Palace Car Co." if cname == "Pullman Palace Car";
replace cname = "Quicksilver Mining Co." if cname == "Quicksilver Mining";
replace cname = "Tennessee Coal, Iron and Railroad Co."
			if cname == "Tennessee Coal, Iron, and Railroad";
			
drop if cname == "Adams Express Co." & year == 1895;
* President listed only;
drop if cname == "United States Express Co." & year == 1895;
* President listed only;
drop if cname == "Western Express";
* Unclear if NYSE listed - seems like no;

replace fullname_m = subinstr(fullname_m, "_s", "", .) if substr(fullname_m, -2, .) == "_s";

/*
American Cotton Oil Co. (95) /Trust (90)
Colorado Coal & Iron Development Co. (95) / Colorado Coal and Iron (90)
Columbus & Hocking Coal & Iron (90) / Columbus & Hocking Coal and Iron Co. (95)
Consolidated Gas [Co. (1895)] of New York
Consolidation [Coal Co. (95)]
Equitable Gas Light [Co. of New York (95)]
Pacific Mail Steamship [Co. (95)]
Pullman Palace Car (90) / Pullman's Palace Car Co. (95)
Quicksilver Mining [Co. (95)]
Tennessee Coal, Iron[, (90)] and Railroad [Co. (95)]
*/
save "Ind_1890-1920.dta", replace;

********************************************;
* This block finds the people with Junior in their name whose name later appears
* without the suffix. We think these people probably dropped the junior when their
* father passed;
drop flag fullname_nojr;

gen flag = suffix == "Jr" | suffix == "2d";
gen fullname_nojr = substr(fullname_m, 1, strlen(fullname_m)-2) if flag == 1;

levelsof fullname_nojr, local(juniors);
foreach name in `juniors' {;
	replace flag = 1 if inlist(fullname_m, "`name'");
};
replace fullname_nojr = fullname_m if flag == 1 & fullname_nojr == "";

sort flag last fullname_nojr year;

replace suffix = "Jr" if fullname_m == "EFBeale" & year > 1895;
replace suffix = "Jr" if fullname_m == "GOCarpenter" & year > 1895;
replace suffix = "Jr" if fullname_m == "EBJudson" & year > 1901;
replace suffix = "Jr" if fullname_m == "PLorillard" & year > 1901;
replace suffix = "Jr" if fullname_m == "JLMorgan" & year > 1901;
replace suffix = "Jr" if fullname_m == "SNorris" & year > 1901;
replace suffix = "Jr" if fullname_m == "GWestinghouse" & year > 1890;

********************************************;

replace fullname_m = firsti + middlei + last + suffix;

sort last fullname_m year;

drop if first == "J." & middle == "L." & last == "Birney";
* ^ either J. L. McBirney is correct or J. L. Birney is correct, uncertain;

*Fixing different people with identical fullname codes;
replace fullname_m = "AlCox" if first == "Allyn" & last == "Cox";
*To distinguish him from Attilla;
replace fullname_m = "ElHiggins" if first == "Elias" & fullname_m == "EHiggins";
replace fullname_m = "EuHiggins" if first == "Eugene" & fullname_m == "EHiggins";
replace fullname_m = "JeMilbank" if first == "Jeremiah" & last == "Milbank";
*To distinguish him from Joseph Milbank;
replace fullname_m = "JoSharp" if first == "John" & last == "Sharp";
replace fullname_m = "JaSharp" if first == "James" & last == "Sharp";
replace fullname_m = "ElSmith" if first == "Elijah" & last == "Smith";
replace fullname_m = "EdSmith" if first == "Edmund" & last == "Smith";
replace fullname_m = "MoHSmith" if first == "Morris" & last == "Smith";
*There might be other Morris Smiths - double check if they match (not CBs);
*Distinguishes him from Milton H Smith;
replace fullname_m = "JoRTaylor" if first == "John" & last == "Taylor";
replace fullname_m = "JaRTaylor" if substr(first, 1, 2) == "Ja" & last == "Taylor";
*There might be others - double check if they match (not CBs);
replace fullname_m = "ArBrown" if first == "Archer" & last == "Brown";
replace fullname_m = "AlBrown" if substr(first, 1, 4) == "Alex" & last == "Brown";
replace fullname_m = "JcCampbell" if first == "Jacob" & fullname_m == "JCampbell";
replace fullname_m = "JmCampbell" if first == "James" & fullname_m == "JCampbell";
replace fullname_m = "ChClark" if first == "Charles" & fullname_m == "CClark";
replace fullname_m = "CyClark" if first == "Cyrus" & fullname_m == "CClark";
replace fullname_m = "ClClark" if first == "Clarence" & fullname_m == "CClark";
replace fullname_m = "AlFink" if first == "Albert" & fullname_m == "AFink";
replace fullname_m = "OlAmes" if first == "Oliver" & last == "Ames";
	replace fullname_m = fullname_m + suffix if fullname_m = "OlAmes";
replace fullname_m = "OkAmes" if first == "Oakes" & last == "Ames";
replace fullname_m = "JoSharp" if first == "John" & last == "Sharp";
replace fullname_m = "JaSharp" if first == "James" & last == "Sharp";
replace fullname_m = "JaWilliams" if first == "James" & fullname_m == "JWilliams";
replace fullname_m = "JoWilliams" if substr(first, 1, 3) == "Jos" & fullname_m == "JWilliams";
replace fullname_m = "WaHTaylor" if inlist(first, "W.", "Walter") & fullname_m == "WHTaylor";
replace fullname_m = "WmHTaylor" if inlist(first, "Wm", "William") & fullname_m == "WHTaylor";
replace fullname_m = "JoRichardson" if first == "Joseph" & fullname_m == "JRichardson";

save "Ind_1890-1920_clean.dta", replace;


#delimit cr
import excel "New Data - 1895 Industrials.xlsx", first case(lower) clear
	gen newly_added = 1
	gen year_std = 1895
	gen hon = remarks == "Hon"
	gen sector = "Ind"
	ren mi middle
	tostring suffix, replace
		replace suffix = "" if suffix == "."
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	tempfile new1895
	save `new1895', replace
	
import excel "New Data - 1905 Industrials.xlsx", first case(lower) clear
	gen newly_added = 1
	gen year_std = 1905
	gen sector = "Ind"
	tostring suffix, replace
		replace suffix = "" if suffix == "."
	gen firsti = substr(first,1,1)
	gen middlei = substr(middle,1,1)
	gen fullname_m = firsti + middlei + last + suffix
	
	gen cid = 354 if cname == "Virginia-Carolina Chemical"
	replace cid = 742 if cname == "U S Express"
	replace cid = 756 if cname == "Wells Fargo and Company"
	replace cid = 779 if cname == "Knickerbocker Ice"
	
	tempfile new1905
	save `new1905', replace

use "Ind_1890-1920_clean.dta", clear
replace title = title_1 if title == "" & title_1 != ""
	
append using `new1895'
append using `new1905'
	replace newly_added = 0 if newly_added == .
	replace cname = "American District Telegraph" if cname == "American District Telegraph Co."
	replace cname = "American Spirits Manufacturing" if cname == "American Spirits Manufacturing Co"
	replace cname = "American Sugar Refining Co." if cname == "American Sugar Refining Company"
	replace cname = "American Tobacco Co." if cname == "American Tobacco Company"
	replace cname = "Claflin Company" if cname == "Claflin H B Co"
	replace cname = "Columbus & Hocking Coal and Iron Co." if cname == "Columbus & Hock Coal & Iron"
	replace cname = "Consolidated Gas NY" if cname == "Consolidated Gas Co. of New York"
	replace cname = "Consolidation Coal Company" if cname == "Consolidation Coal Co."
	replace cname = "Laclede Gaslight Co." if cname == "Laclede Gas (St Louis)"
	replace cname = "National Lead Co" if cname == "National Lead Co."
	replace cname = "National Starch" if cname == "National Strach Manufacturing Co."
	replace cname = "North American Co" if cname == "North American Co."
	replace cname = "Philadelphia Co" if cname == "Philadelphia Company"
	replace cname = "Wells Fargo and Co" if cname == "Wells. Fargo & Co. Express"
	replace cname = "Westinghouse Electric and Manufacturing" ///
						if cname == "Westinghouse Electric & Manufacturing Co"
	replace cname = "du Pont de Nemours Powder Company" if cname == "Dupont and Co"
	replace cname = "Tennessee Coal & Iron" if cname == "Tennessee Coal, Iron and Railroad Co."
	
	bys cname: ereplace cid = min(cid)
	
	replace cid = 54 if cname == "Colorado Coal & Iron Developmemt Co."
		// merged w/ something else to become Colorado Fuel & Iron
	replace cid = 66 if cname == "Distilling Co of America"
	replace cid = 138 if cname == "Pullman's Palace Car Co."
	
	replace cname = "Dupont and Co" if year_std == 1920 ///
					& cname == "du Pont de Nemours Powder Company"

	egen id_add = group(cname)
	summ cid
		local rmax = `r(max)'
	replace cid = `rmax' + id_add if cid == .
	
	replace cname = "Tennessee Coal, Iron and Railroad Co." if year_std < 1900 ///
				& cname == "Tennessee Coal & Iron"
	replace cid = 17 if cid == 181 & cname == "American Ice Co" // American Ice Securities

save "Ind_boards_final.dta", replace

*/

********************************************************************************;
/*
* Merge in newly acquired titles;
#delimit cr

forval yr = 1880(5)1905 {
if `yr' != 1900 {
	import excel "../../Add Director Titles/`yr' RRs Titles.xlsx", clear first
	foreach var of varlist first middle last {
	    replace `var' = subinstr(`var', " ", "", .) if substr(`var', -1, 1) == " "
	}

	tostring suffix, replace
		replace suffix = "" if suffix == "."
	
	duplicates tag cname first middle last suffix sector year_std, gen(dup)
	drop if dup & director == . & manager == .
	drop dup
	
	tempfile titles`yr'
	save `titles`yr'', replace
}
}


use "RR_boards_titlesmissing.dta", clear
	replace last = "Billings" if first == "Fredk." & middle == "Billings"
		replace middle = "" if first == "Fredk." & last == "Billings"
		replace fullname_m = "FBillings" if first == "Fredk." & last == "Billings"
	replace middle = "B." if substr(middle,1,1) == "B" & ///
			inlist(fullname_m, "HBPayne", "WBLoomis", "JBWilliams")
	
	foreach var of varlist first middle last {
	    replace `var' = subinstr(`var', " ", "", .) if substr(`var', -1, 1) == " "
	}
	

	forval yr = 1880(5)1905 {
	if `yr' != 1900 {
		dis "`yr'"
	    merge m:1 cname first middle last suffix sector year_std ///
			using `titles`yr'', gen(_m`yr') keepus(city director manager) ///
			update replace
		replace fullname_m = substr(first,1,1) + substr(middle,1,1) + last + suffix ///
			if _m`yr' == 2
	}
	}

save "RR_boards_final.dta", replace
*/
********************************************************************************;
/*
#delimit ;
use "Util_boards.dta", clear;
ren sample sector;
egen utilid = group(cname);

gen cid = 810 if cname == "Amer Telegraph & Cable";
	replace cid = 811 if cname == "Amer Teleph & Teleg";
	replace cid = 857 if cname == "Brooklyn Rapid Transit";
	replace cid = 883 if cname == "Cent & South Amer Teleg";
	replace cid = 902 if cname == "Connecticut Railway & Lighting";
	replace cid = 903 if cname == "Consolidated Gas NY";
	replace cid = 994 if cname == "Kings County Elec Lt & P";
	replace cid = 1013 if cname == "Manhattan Railway";
	replace cid = 1020 if cname == "Metropolitan Street Ry";
	replace cid = 1045 if cname == "North American Co";
	replace cid = 1067 if cname == "People's Gas Lt & Coke";
	replace cid = 1070 if cname == "Philadelphia Co";
	replace cid = 1116 if cname == "Third Avenue";
	replace cid = 1121 if cname == "Twin City Rapid Transit";
	replace cid = 1157 if cname == "Western Union Telegraph";
save "Util_boards_final.dta", replace;
********************************************************************************;
#delimit ;
foreach file in "Ind_boards_final.dta" "RR_boards_final.dta"
				"Ind_boards_wtitles.dta" "RR_boards_wtitles.dta"
				"Util_boards_final.dta" "All_boards_final.dta"
				"CB_1880-1920_NY" "UW_1880-1920_top10" "UW_1880-1920_top25" {;
	use "`file'", clear;
	replace fullname_m = subinstr(fullname_m, "_s", "", .) if substr(fullname_m, -2, .) == "_s";
	
	replace fullname_m = "AlCox" if first == "Allyn" & last == "Cox";
	*To distinguish him from Attilla;
	replace fullname_m = "ElHiggins" if first == "Elias" & fullname_m == "EHiggins";
	replace fullname_m = "EuHiggins" if first == "Eugene" & fullname_m == "EHiggins";
	replace fullname_m = "JeMilbank" if first == "Jeremiah" & last == "Milbank";
	*To distinguish him from Joseph Milbank;
	replace fullname_m = "JoSharp" if first == "John" & last == "Sharp";
	replace fullname_m = "JaSharp" if inlist(first, "James", "Jas.") & last == "Sharp";
	replace fullname_m = "ElSmith" if first == "Elijah" & last == "Smith";
	replace fullname_m = "EdSmith" if first == "Edmund" & last == "Smith";
	replace fullname_m = "MoHSmith" if first == "Morris" & last == "Smith";
	*There might be other Morris Smiths - double check if they match (not CBs);
	*Distinguishes him from Milton H Smith;
	replace fullname_m = "JoRTaylor" if first == "John" & last == "Taylor";
	replace fullname_m = "JaRTaylor" if substr(first, 1, 2) == "Ja" & last == "Taylor";
	*There might be others - double check if they match (not CBs);
	replace fullname_m = "ArBrown" if first == "Archer" & last == "Brown";
	replace fullname_m = "AlBrown" if substr(first, 1, 4) == "Alex" & last == "Brown";
	replace fullname_m = "JcCampbell" if first == "Jacob" & fullname_m == "JCampbell";
	replace fullname_m = "JmCampbell" if first == "James" & fullname_m == "JCampbell";
	replace fullname_m = "ChClark" if first == "Charles" & fullname_m == "CClark";
	replace fullname_m = "CyClark" if first == "Cyrus" & fullname_m == "CClark";
	replace fullname_m = "ClClark" if first == "Clarence" & fullname_m == "CClark";
	replace fullname_m = "AlFink" if first == "Albert" & fullname_m == "AFink";
	replace fullname_m = "OlAmes" + suffix if first == "Oliver" & last == "Ames";
		replace fullname_m = "OlAmesJr" if fullname_m == "OlAmes2d";
	replace fullname_m = "OkAmes" if first == "Oakes" & last == "Ames";
	replace fullname_m = "JaWilliams" if first == "James" & fullname_m == "JWilliams";
	replace fullname_m = "JoWilliams" if substr(first, 1, 3) == "Jos" & fullname_m == "JWilliams";
	replace fullname_m = "WaHTaylor" if first == "Walter" & fullname_m == "WHTaylor";
	replace fullname_m = "WHTaylor" if first == "W." & fullname_m == "WaHTaylor";
	replace fullname_m = "WmHTaylor" if inlist(first, "Wm", "William") & fullname_m == "WHTaylor";
	replace fullname_m = "JoRichardson" if first == "Joseph" & fullname_m == "JRichardson";
	
	save "`file'", replace;
};
*/
********************************************************************************;
/*
*Put Railroads and Industrials together so we can plot them together;
use "Ind_1890-1920_clean.dta", clear;
append using "RR_1880-1920_clean.dta";
save "All_1880-1920_clean.dta", replace;

#delimit ;
use "Ind_boards_wtitles.dta", clear;
append using "RR_boards_wtitles.dta";
append using "Util_boards_final.dta";
	qui summ cid;
		local rmax = r(max);
		replace cid = utilid + `rmax' if sector == "Util" & cid == .;
		drop utilid;
	replace newly_added = 1 if sector == "Util" & newly_added == .;
save "All_boards_final.dta", replace;
*/
********************************************************************************;
/*
*Consolidating all the NY CBs;
use CB_clean, clear;
keep if inlist(year, 1911, 1915, 1920);
append using "CB_1880-1905_clean.dta";
gen year_std = year;
replace year_std = 1910 if year == 1911;
save "CB_1880-1925_clean.dta", replace;
keep if city == "New York";
save "CB_1880-1920_NY.dta", replace;
*/
********************************************************************************;
/*
use Underwriters, clear;
keep if inlist(year, 1900, 1905, 1906, 1910, 1911, 1915, 1920);
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
append using "Underwriters_pre-1900_top10.dta";
gen year_std = year;
replace year_std = 1905 if year == 1906;
replace year_std = 1910 if year == 1911;

replace fullname_m = fullname_d if fullname_m == "";
replace fullname_m = fullname if fullname_m == "";

save "UW_1880-1920_top10.dta", replace;
*/

/*
use Underwriters, clear;

keep if inlist(year, 1900, 1905, 1906, 1910, 1911, 1915, 1920);
keep if inlist(cname, "Kidder Peabody & Co",
					"Morgan J P & Co",
					"Read Wm A & Co", "Dillon Read & Co",
					"Fisk Harvey & Sons",
					"Clark Dodge & Co",
					"Seligman J & W & Co",
					"First National",
					"National City");
append using "../Underwriters_LM/Underwriters_pre-1900_JayCooke.dta", force;
gen year_std = year;
replace year_std = 1905 if year == 1906;
replace year_std = 1910 if year == 1911;

replace fullname_m = fullname_d if fullname_m == "";
replace fullname_m = fullname if fullname_m == "";

save "UW_1880-1920_JayCooke.dta", replace;
*/
/*
use Underwriters, clear;
keep if inlist(year, 1900, 1905, 1906, 1910, 1911, 1915, 1920);
keep if inlist(cname, "Blair & Co", "Blair & Co Inc",
					"First National",
					"Hallgarten & Co",
					"Kidder Peabody & Co",
					"Kuhn Loeb & Co",
					"Lee Higginson & Co") |
		inlist(cname, "Morgan J P & Co",
					"National City", "National City Co",
					"Read Wm A & Co", "Dillon Read & Co",
					"Speyer & Co") |
		inlist(cname, "Fisk Harvey & Sons",
					"Clark Dodge & Co",
					"Seligman J & W & Co");
append using "../Underwriters_LM/Underwriters_pre-1900_top10_plus_early.dta";
gen year_std = year;
replace year_std = 1905 if year == 1906;
replace year_std = 1910 if year == 1911;

replace fullname_m = fullname_d if fullname_m == "";
replace fullname_m = fullname if fullname_m == "";

save "UW_1880-1920_top10_plus_early.dta", replace;
*/
/*
use Underwriters, clear;
keep if inlist(year, 1900, 1905, 1906, 1910, 1911, 1915, 1920);
keep if inlist(cname, "Blair & Co", "Blair & Co Inc",
					"First National",
					"Hallgarten & Co",
					"Kidder Peabody & Co",
					"Kuhn Loeb & Co",
					"Lee Higginson & Co") |
		inlist(cname, "Morgan J P & Co",
					"National City", "National City Co",
					"Read Wm A & Co",
					"Speyer & Co") |
		inlist(cname, "Ladenburg Thalmann & Co",
					"Brown Brothers & Co",
					"White Weld & Co", "Moffat & White",
					"Salomon William & Co",
					"Fisk Harvey & Sons") |
		inlist(cname, "Guaranty Co", "Guaranty Trust Co",
					"Clark Dodge & Co",
					"Seligman J & W & Co",
					"Redmond & Co",
					"Harris Forbes & Co") |
		inlist(cname, "Potter Choate & Prentice", "Potter Brothers & Co",
						"Potter & Co",
					"Kean Taylor & Co",
					"Lehman Bros",
					"Hayden Stone & Co");

* Flower & Co disappears after 1895, Winslow Lanier & Co also disappears
*	but Charles Lanier shows up in Central Trust Co;

append using "Underwriters_pre-1900_top25.dta";
append using "UW_Addenda_1900-1905_top25.dta", force;
gen year_std = year;
replace year_std = 1905 if year == 1906;
replace year_std = 1910 if year == 1911;

replace fullname_m = fullname_d if fullname_m == "";
replace fullname_m = fullname if fullname_m == "";

save "UW_1880-1920_top25.dta", replace;


keep if inlist(cname, "Brown Bros. & Co", "Brown Bros. & Co.",
						"Brown Brothers & Co",
					"Clark Dodge & Co", "Clark, Dodge & Co.",
					"Drexel Morgan & Co", "Drexel, Morgan & Co.") |
		inlist(cname, "First National", "First National Bank",
						"First National Bank of the City of New York",
					"Fisk & Hatch", "Fisk Harvey & Sons",
						"Fisk, Harvey & Sons",
					"Hallgarten & Co", "Hallgarten & Co.") |
		inlist(cname, "Kidder Peabody & Co", "Kidder, Peabody & Co",
						"Kidder, Peabody & Co.",
					"Kuhn Loeb & Co", "Kuhn, Loeb & Co", "Kuhn, Loeb & Co.",
					"Ladenburg Thalmann & Co", "Ladenburg, Thalmann & Co",
						"Ladenburg, Thalmann & Co.") |
		inlist(cname, "Lee Higginson & Co", "Lee, Higginson & Co",
						"Lee, Higginson & Co.",
					"National City", "National City Co", "National City Bank",
						"National City Bank of New York",
					"Seligman J & W & Co", "Seligman, J. & W., & Co.") |
		inlist(cname, "Speyer & Co", "Speyer & Co.",
					"Vermilye & Co", "Vermilye & Co.", "Read Wm A & Co");

save "UW_1880-1920_top14.dta", replace;
*/
********************************************************************************;
************** OPENING FIRM BOARD LISTS ****************************************;
********************************************************************************;
#delimit;
*use "All_boards_final.dta", clear;

cap drop _merge;
********************************************************************************;
************** MERGING IN UNDERWRITERS *****************************************;
********************************************************************************;


*Merging in underwriters;
local num = "top10";
use "Ind_boards_final.dta", clear;
append using "Util_boards_final.dta";

merge m:m fullname_m year_std using "../../Gilded Age Boards/UW_1880-1920_Ind`num'.dta", keep(1 3);
*merge m:m fullname_m year_std using "UW_1880-1920_1880cohort.dta", keep(1 3);


gen uw = _merge == 3;
gen nuw = _merge == 1;

replace sector = "Ind" if sector == "Util";

collapse (sum) nuw uw, by(cname year_std sector);

gen Puw = uw > 0;

sort year_std sector cname;
by year_std sector: summ Puw;

*tab cohort;
collapse (mean) Puw, by(year_std sector);
scatter Puw year_std;

sort year_std sector;
outsheet Puw year_std sector using all_Puw_`num'_Inds.csv, comma replace;
*---------------------------------;
local num = "top10";
use "RR_boards_final.dta", clear;

merge m:m fullname_m year_std using "UW_1880-1920_`num'.dta", keep(1 3);
*merge m:m fullname_m year_std using "UW_1880-1920_1880cohort.dta", keep(1 3);


gen uw = _merge == 3;
gen nuw = _merge == 1;

replace sector = "Ind" if sector == "Util";

collapse (sum) nuw uw, by(cname year_std sector);

gen Puw = uw > 0;

sort year_std sector cname;
by year_std sector: summ Puw;

*tab cohort;
collapse (mean) Puw, by(year_std sector);
scatter Puw year_std;

sort year_std sector;
outsheet Puw year_std sector using all_Puw_`num'_RRs.csv, comma replace;
*/
/*
* Utilities Merges;
#delimit;

use "Util_boards_final.dta", clear;
	ren sample sector;
	keep if director == 1;
	
local num = "top10";
joinby fullname_m year_std using "UW_1880-1920_`num'.dta", unm(master) _merge(top10_merge);

gen top10uw = top10_merge == 3;
collapse (max) top10uw, by(cname year_std sector);
sort year_std sector cname;
export delimited "Util_top10_merge.csv", replace;
*/
/*
restore;


preserve;

collapse (sum) uw, by(RRid year_std sector cohort);
rename uw numuw;
sort year_std sector cohort RRid;
by year_std sector cohort: summ numuw;

collapse (mean) numuw, by(year_std sector cohort);
scatter numuw year_std;

sort sector cohort year_std ;
outsheet numuw year_std sector cohort using all_numuw_top`num'.csv, comma replace;

restore;
*/
********************************************************************************;
************** MERGING IN COMMERCIAL BANKERS ***********************************;
********************************************************************************;
/*
merge m:m fullname_m year_std using "CB_1880-1920_NY.dta", keep(1 3);

sort cname year_std last fullname_m;

*Only do this if you want to get the number of bankers and not the number of banks;
drop if fullname_m == fullname_m[_n-1] & cname == cname[_n-1] & year == year[_n-1];

gen cb = _merge == 3;
gen ncb = _merge == 1;


preserve;
collapse (sum) ncb cb, by(cname year_std sector);

gen Pcb = cb > 0;
sort year_std sector cname;
by year_std sector: summ Pcb;


collapse (mean) Pcb, by(year_std sector);
scatter Pcb year_std;

sort sector year_std;
outsheet Pcb year_std sector using all_Pcb_NY.csv, comma replace;

restore;
*/
/*
*Major Comercial Bankers;
preserve;
	use "CB_1880-1920_NY.dta", clear;
	collapse (count) n_boards = year (first) first middle last, by(fullname_m year_std);
	bys year_std: egen rank = rank(n_boards), field;
	gsort year_std rank;
	order first middle last fullname_m year_std n_boards rank;
	export delimited ranked_CBs.csv, replace;
	keep if rank <= 15;
	export delimited most_important_CBs.csv, replace;
	tempfile majorCBs;
	save `majorCBs', replace;
restore;

merge m:m fullname_m year_std using `majorCBs', keep(1 3);

sort cname year_std last fullname_m;

*Only do this if you want to get the number of bankers and not the number of banks;
drop if fullname_m == fullname_m[_n-1] & cname == cname[_n-1] & year == year[_n-1];

gen cb = _merge == 3;
gen ncb = _merge == 1;


replace sector = "Ind" if sector == "Util";
preserve;
collapse (sum) ncb cb, by(cname year_std sector);

gen Pcb = cb > 0;
sort year_std sector cname;
by year_std sector: summ Pcb;


collapse (mean) Pcb, by(year_std sector);
scatter Pcb year_std;

sort sector year_std;
outsheet Pcb year_std sector using major_Pcb_NY.csv, comma replace;

restore;
*/

/*
*Biggest Commercial Banks' Directors;
preserve;
	use "CB_1880-1920_NY.dta", clear;
	keep if inlist(cname, "National Bank of Commerce",
							"National Park", "National Park Bank",
							"Hanover National", "Hanover National Bank",
							"Chase National", "Chase National Bank",
							"Western National", "Western National Bank")
			| inlist(cname, "Importers & Traders National",
								"Importers & Traders Nat. Bank",
							"Chemical National", "Chemical National Bank",
							"Fourth National", "Fourth National Bank",
							"Bank of the Manhattan Co", "Bank of America");

	export delimited biggest_CBs.csv, replace;
	tempfile bigCBs;
	save `bigCBs', replace;
restore;

merge m:m fullname_m year_std using `bigCBs', keep(1 3);

sort cname year_std last fullname_m;

*Only do this if you want to get the number of bankers and not the number of banks;
drop if fullname_m == fullname_m[_n-1] & cname == cname[_n-1] & year == year[_n-1];

gen cb = _merge == 3;
gen ncb = _merge == 1;

preserve;
keep if cb == 1;
outsheet year_std fullname_m cname sector cb
	using biggest_CB_NY_interlock_names.csv, comma replace;
restore;

replace sector = "Ind" if sector == "Util";

preserve;
collapse (sum) ncb cb, by(cname year_std sector);

gen Pcb = cb > 0;
sort year_std sector cname;
by year_std sector: summ Pcb;


collapse (mean) Pcb, by(year_std sector);
scatter Pcb year_std;

sort sector year_std;
outsheet Pcb year_std sector using biggest_Pcb_NY.csv, comma replace;

restore;
*/
/*
*Biggest Commercial Banks' Directors excluding Underwriters;
preserve;
	use "CB_1880-1920_NY.dta", clear;
	keep if inlist(cname, "National Bank of Commerce",
							"National Park", "National Park Bank",
							"Hanover National", "Hanover National Bank",
							"Chase National", "Chase National Bank",
							"Western National", "Western National Bank")
			| inlist(cname, "Importers & Traders National",
								"Importers & Traders Nat. Bank",
							"Chemical National", "Chemical National Bank",
							"Fourth National", "Fourth National Bank",
							"Bank of the Manhattan Co", "Bank of America");
	egen tagged = tag(fullname_m year_std);
	keep if tagged;
	merge 1:m fullname_m year_std using "UW_1880-1920_top10.dta",
		nogen keep(1) keepus(firsti); drop firsti;
	export delimited biggest_CBs_exUWs.csv, replace;
	tempfile bigCBs_exUW;
	save `bigCBs_exUW', replace;
restore;

merge m:m fullname_m year_std using `bigCBs_exUW', keep(1 3);

sort cname year_std last fullname_m;

*Only do this if you want to get the number of bankers and not the number of banks;
drop if fullname_m == fullname_m[_n-1] & cname == cname[_n-1] & year == year[_n-1];

gen cb = _merge == 3;
gen ncb = _merge == 1;

replace sector = "Ind" if sector == "Util";

preserve;
collapse (sum) ncb cb, by(cname year_std sector);

gen Pcb = cb > 0;
sort year_std sector cname;
by year_std sector: summ Pcb;


collapse (mean) Pcb, by(year_std sector);
scatter Pcb year_std;

sort sector year_std;
outsheet Pcb year_std sector using biggest_Pcb_NY_exUWs.csv, comma replace;

restore;
*/
/*
*Literally just GF Baker;

gen gfb = fullname_m == "GFBaker";
gen ngfb = fullname_m != "GFBaker";


preserve;
collapse (sum) ngfb gfb, by(cname year_std sector);

gen Pgfb = gfb > 0;
sort year_std sector cname;
by year_std sector: summ Pgfb;


collapse (mean) Pgfb, by(year_std sector);
scatter Pgfb year_std;

sort sector year_std;
outsheet Pgfb year_std sector using Pgfb.csv, comma replace;

restore;
*/

/*
*Major Comercial Bankers excluding Top 10 Underwriters;
preserve;
	use "CB_1880-1920_NY.dta", clear;
	collapse (count) n_boards = year (first) first middle last, by(fullname_m year_std);
		merge 1:m fullname_m year_std using "UW_1880-1920_top10.dta",
				nogen keep(1) keepus(firsti); drop firsti;
	bys year_std: egen rank = rank(n_boards), field;
	gsort year_std rank;
	order first middle last fullname_m year_std n_boards rank;
	export delimited ranked_CBs_exUWs.csv, replace;
	keep if rank <= 15;
	export delimited most_important_CBs_exUWs.csv, replace;
	tempfile majorCBs_exUWs;
	save `majorCBs_exUWs', replace;
restore;

merge m:m fullname_m year_std using `majorCBs_exUWs', keep(1 3);

sort cname year_std last fullname_m;

*Only do this if you want to get the number of bankers and not the number of banks;
drop if fullname_m == fullname_m[_n-1] & cname == cname[_n-1] & year == year[_n-1];

gen cbxuw = _merge == 3;
gen ncbxuw = _merge == 1;

replace sector = "Ind" if sector == "Util";

preserve;
collapse (sum) ncbxuw cbxuw, by(cname year_std sector);

gen Pcbxuw = cbxuw > 0;
sort year_std sector cname;
by year_std sector: summ Pcbxuw;


collapse (mean) Pcbxuw, by(year_std sector);
scatter Pcbxuw year_std;

sort sector year_std;
outsheet Pcbxuw year_std sector using major_Pcbxuw_NY.csv, comma replace;

restore;
*/

/*
*Major Investment Bankers;
preserve;
	use "UW_1880-1920_top25.dta", clear;
	joinby fullname_m year using "CB_1880-1920_NY.dta";
	collapse (count) n_boards = year (first) first middle last, by(fullname_m year_std);
	bys year_std: egen rank = rank(n_boards), field;
	gsort year_std rank;
	export delimited ranked_UWs.csv, replace;
	keep if rank <= 15;
	export delimited most_important_UWs.csv, replace;
	tempfile majorUWs;
	save `majorUWs', replace;
restore;

merge m:m fullname_m year_std using `majorUWs', keep(1 3);

sort cname year_std last fullname_m;

*Only do this if you want to get the number of bankers and not the number of banks;
drop if fullname_m == fullname_m[_n-1] & cname == cname[_n-1] & year == year[_n-1];

gen uw = _merge == 3;
gen nuw = _merge == 1;

replace sector = "Ind" if sector == "Util";
preserve;
collapse (sum) nuw uw, by(cname year_std sector);

gen Puw = uw > 0;
sort year_std sector cname;
by year_std sector: summ Puw;


collapse (mean) Puw, by(year_std sector);
scatter Puw year_std;

sort sector year_std;
outsheet Puw year_std sector using major_Puw_NY.csv, comma replace;

restore;
*/

/*
*All Investment Banking Partners;
preserve;
	#delimit cr
	import excel "../../NYSE 1883.xlsx", clear first case(lower)
		replace first = "N" ///
				if first == "" & firmname == "Thouron, N., & Co (Philadelphia)"
		replace last = "Thouron" ///
				if last == "" & firmname == "Thouron, N., & Co (Philadelphia)"
		replace last = "Kuhn" if last == "Kuhn, of Frank fort-on-the-Main"
		replace last = proper(last)
		ren firmname cname
	gen fullname_m = substr(first,1,1) + substr(middle,1,1) + last + suffix
		drop if fullname_m == "Bk of Com & Ind'ty Darmstadt"
	replace fullname_m = subinstr(fullname_m," ","",.)
	gen year_std = 1885
	tempfile nyse1885
	save `nyse1885', replace

	import excel "../../NYSE 1895.xlsx", clear first case(lower)
		ren firmname cname
		replace last = proper(last)
	gen fullname_m = substr(first,1,1) + substr(middle,1,1) + last + suffix
	replace fullname_m = subinstr(fullname_m," ","",.)
	gen year_std = 1895
	tempfile nyse1895
	save `nyse1895', replace
	
	use "CB_1880-1920_NY.dta", clear
		keep if inlist(cname, "Farmers Loan & Trust Co", ///
			"Equitable Trust Co", "Bankers Trust Co")
	tempfile bef
	save `bef', replace
		
	use "../../IB_clean.dta", clear
		replace last = proper(last)
		replace last = "Trask" if last == "Trash" & first == "Wayland"
			replace fullname_m = "WTrask" if fullname_m == "WTrash"
		gen year_std = year
			replace year_std = 1905 if year == 1906
	
	/* Joining to see where names don't quite match
	joinby fullname_m using `nyse1885', unm(both) _merge(_m85)
		replace last = last85 if last == ""
	joinby fullname_m using `nyse1895', unm(both) _merge(_m95)
		replace last = last95 if last == ""
	*/
	append using `nyse1885'
	append using `nyse1895'
	append using `bef'
	append using "UW_1880-1920_top25.dta"
	
	replace fullname_m = subinstr(fullname_m, "_s", "", 1)
	replace fullname_m = subinstr(fullname_m," ","",.)

	keep fullname_m year_std
	duplicates drop

	tempfile all_nyse
	save `all_nyse', replace
restore

#delimit ;
joinby fullname_m year_std using `all_nyse', unm(master);

sort cname year_std last fullname_m;

*Only do this if you want to get the number of bankers and not the number of banks;
*drop if fullname_m == fullname_m[_n-1] & cname == cname[_n-1] & year == year[_n-1];

gen uw = _merge == 3;
gen nuw = _merge == 1;

replace sector = "Ind" if sector == "Util";
preserve;
collapse (sum) nuw uw, by(cname year_std sector);

gen Puw = uw > 0;
sort year_std sector cname;
by year_std sector: summ Puw;


collapse (mean) Puw, by(year_std sector);
scatter Puw year_std;

sort sector year_std;
outsheet Puw year_std sector using P_all_nyse_partners.csv, comma replace;

restore;
*/
/*
preserve;

collapse (sum) cb ncb, by(cname year_std sector);
rename cb numcb;
gen boardsize = numcb + ncb;
sort year_std sector cname;
by year_std sector: summ numcb;

collapse (mean) numcb boardsize, by(year_std sector);
scatter numcb boardsize year_std;

sort sector year_std;
outsheet numcb boardsize year_std sector using all_numcb_NY.csv, comma replace;

restore;
*/
/*
*Investigating the Vanishing Commercial Banker Problem;
collapse (sum) ncb cb, by(cname year_std sector);

keep if year_std >= 1890 & year_std <= 1905;
reshape wide cb ncb, i(cname) j(year_std);
*/

