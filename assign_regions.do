/*
assign_regions.do
*/


merge m:1 cname using "Data/RR_Financials1890.dta", ///
			nogen keep(1 3) keepus(region)

replace region = "N" if inlist(cname, "ALBANY & SUSQUEHANNA", "Albany and Susquehanna Railroad", "A&S")
replace region = "N" if cname == "Ann Arbor"
replace region = "W" if inlist(cname, "ATCHISON, TOPEKA & SANTA FE RAILWAY CO.", ///
							"ATCHISON, TOPEKA & SANTA FE")
replace region = "W" if inlist(cname, "ATLANTIC & PACIFIC RAILROAD CO.", ///
							"ATLANTIC & PACIFIC")
replace region = "S" if cname == "Atlanta Birm & Atlan"
replace region = "S" if cname == "Atlantic Coast Line RR"
replace region = "N" if inlist(cname, "BALTIMORE & OHIO RAILROAD CO.", "BALTIMORE & OHIO", ///
								"Baltimore and Ohio Railroad", "Baltimore and Ohio")
replace region = "N" if cname == "Boston and New York Air-line Railroad"
replace region = "S" if cname == "BRUNSWICK & WESTERN"
replace region = "N" if inlist(cname, "BUFFALO, ROCHESTER & PITTSBURGH RAILWAY CO.", ///
						"Buffalo Rochester & Pittsb", "BUFFALO, ROCHESTER & PITTSBURGH")
replace region = "W" if inlist(cname, "BURLINGTON, CEDAR RAPIDS & NORTHERN", ///
							"Burlington, Cedar Rapids & Northern Railway", ///
							"Burlington, Cedar Rapids and Northern Railway")
replace region = "N" if inlist(cname, "Buffalo and Susquehanna", "Buffalo & Susq", ///
							"Buff & Susq", "Buffalo & Susquehanna")
replace region = "N" if inlist(cname, "CANADA SOUTHERN RAILWAY", ///
							"Canada Southern Railway", "Canada South")
replace region = "W" if inlist(cname, "CANADIAN PACIFIC RAILWAY CO.", ///
							"CANADIAN PACIFIC RAILWAY COMPANY", "Canadian Pacific Railway")
replace region = "W" if inlist(cname, "CEDAR FALLS & MINNESOTA RAILROAD CO.", ///
							"CEDAR FALLS AND MINNESOTA RAILROAD COMPANY", ///
							"Cedar Falls and Minnesota Railroad")
replace region = "W" if cname == "Central Iowa Railway"
replace region = "W" if inlist(cname, "CENTRAL PACIFIC RR.", "Central Pacific Railroad", ///
							"CENTRAL PACIFIC RAILROAD COMPANY")
replace region = "N" if inlist(cname, "CENTRAL RAILROAD COMPANY OF NEW JERSEY", ///
							"Central Railroad Of New Jersey")
replace region = "S" if cname == "CHARLOTTE, COLUMBIA AND AUGUSTA RAILROAD"
replace region = "S" if inlist(cname, "CHESAPEAKE & OHIO RAILWAY CO.", ///
							"CHESAPEAKE, OHIO & SOUTHWESTERN", "Chesapeake and Ohio Railway")
replace region = "W" if inlist(cname, "CHICAGO & ALTON RAILROAD CO.", "CHICAGO & ALTON", ///
							"Chicago and Alton Railroad")
replace region = "W" if inlist(cname, "CHICAGO, BURLINGTON & QUINCY RAILROAD CO.", ///
							"CHICAGO, BURLINGTON & QUINCY", ///
							"Chicago, Burlington and Quincy Railroad")
replace region = "W" if cname == "Chic Great West"
replace region = "W" if inlist(cname, "Chic Rock Island & Pacific", ///
								"CHICAGO, ROCK ISLAND & PACIFIC RAILWAY CO.", ///
								"CHICAGO, ROCK ISLAND & PACIFIC", ///
								"Chicago, Rock Island and Pacific Railroad", ///
								"Chicago, Rock Island and Pacific Railway")
replace region = "W" if inlist(cname, "Chicago & Eastern Ill", "CHICAGO & EASTERN ILLINOIS", ///
								"CHICAGO & EASTERN ILLINOIS RAILROAD CO.", "Chic & E Ill") ///
								| strpos(cname, "Chicago and Eastern Illinois") > 0
replace region = "N" if cname == "Chicago Indianapolis and Louisville"
replace region = "W" if inlist(cname, "Chicago & North Western", "CHICAGO & NORTHWESTERN", ///
							"CHICAGO & NORTHWESTERN RAILWAY CO.", "Chicago and Northwestern Railway", ///
							"Chicago and North-western Railway")
replace region = "N" if cname == "Chicago Indianapolis & Louisville"
replace region = "W" if inlist(cname, "Chicago Milwaukee & St Paul", "CHICAGO, MILWAUKEE & ST. PAUL", ///
								"CHICAGO, MILWAUKEE & ST. PAUL.", ///
								"Chicago, Milwaukee and St. Paul Railway")
replace region = "W" if inlist(cname, "Chicago St P Minn & Omaha", ///
							"CHICAGO, ST. PAUL, MINNEAPOLIS & OMAHA RAILWAY CO.", ///
							"CHICAGO, ST. PAUL, MINNEAPOLIS AND OMAHA RAILWAY CO.", ///
							"Chicago, St. Paul and Minneapolis Railway", ///
							"Chicago, St. Paul, Minneapolis and Omaha Railway")
replace region = "N" if cname == "Chicago Terminal Transfer"
replace region = "N" if inlist(cname, "Cleve Cincin Chic & St Louis", ///
							"CLEVELAND, CINCINNATI, CHICAGO & ST. LOUIS RAILWAY CO.", ///
							"CLEVELAND, CINCINNATI, ST. LOUIS & CHICAGO")
replace region = "N" if inlist(cname, "Cleveland, Columbus, Cincinnati and Indianapolis Railway", ///
						"Cleveland, Columbus, Cincinnati, and Indianapolis Railway")
replace region = "S" if cname == "Chicago, St. Louis and New Orleans Railroad"
replace region = "N" if inlist(cname, "CHICAGO, ST. LOUIS & PITTSBURGH", ///
						"Chicago, St. Louis and Pittsburgh Railroad")
replace region = "N" if cname == "CINCINNATI, WASHINGTON & BALTIMORE"
replace region = "N" if inlist(cname, "Cleve Lorain & Wheeling", "Cleve Lorr & wheeling", ///
									"Cleveland Lorain & Wheeling")
replace region = "N" if inlist(cname, "Cleveland & Pitts", ///
								"CLEVELAND & PITTSBURGH", "Cleve & Pitts" ///
								"Cleveland and Pittsburgh", ///
								"Cleveland and Pittsburgh Railroad", ///
								"CLEVELAND & PITTSBURGH RAILROAD CO.", ///
								"Cleveland and Pittsburgh")
replace region = "W" if cname == "Colorado & Southern"
replace region = "W" if inlist(cname, "Colorado Midland", "Col. Mid.")
replace region = "S" if cname == "COLUMBIA & GREENVILLE"
replace region = "N" if cname == "Columbus, Chicago & Indiana Central Railway"
replace region = "N" if inlist(cname, "COLUMBUS, HOCKING VALLEY & TOLEDO RAILWAY CO.", ///
								"COLUMBUS, HOCKING VALLEY & TOLEDO")
replace region = "W" if cname == "Cripple Creek Cent"
replace region = "N" if cname == "Cumberland and Pennsylvania Railroad"
replace region = "N" if inlist(cname, "Delaware Lackaw & Western", ///
								"DELAWARE, LACKAWANNA & WESTERN RAILROAD CO.", ///
								"DELAWARE, LACKAWANNA & WESTERN", ///
								"Delaware, Lackawanna and Western Railroad")
replace region = "N" if inlist(cname, "DELAWARE & HUDSON CANAL CO.", ///
								"Delaware and Hudson Canal Company")
replace region = "W" if inlist(cname, "DENVER & RIO GRANDE RAILROAD CO.", ///
								"DENVER & RIO GRANDE", ///
								"Denver and Rio Grande Railway")
replace region = "W" if cname == "DENVER, TEXAS & FORT WORTH"
replace region = "W" if cname == "Denver & Southwestern"
replace region = "W" if cname == "DES MOINES AND FORT DODGE RAILROAD"
replace region = "N" if cname == "Detroit & Mackinac"
replace region = "W" if cname == "Dubuque and Sioux City Railroad"
replace region = "N" if inlist(cname, "Duluth South Shore & Atlan", "Duluth S S Atl", ///
								"Duluth South Shore and Atlantic")
replace region = "S" if inlist(cname, "EAST TENNESSEE, VIRGINIA & GEORGIA", ///
								"East Tennessee, Virginia and Georgia Railroad")
replace region = "S" if cname == "ELIZABETHTOWN, LEXINGTON AND BIG SANDY RAILROAD CO."
replace region = "N" if inlist(cname, "Erie", "Erie & Pittsburgh")
replace region = "N" if inlist(cname, "Evansville & Terra Haute", "Evansville & TH", ///
								"Evansville and Terra Haute", "Evansville & T H", ///
								"EVANSVILLE & TERRE HAUTE RAILROAD CO.", ///
								"EVANSVILLE & TERRE HAUTE", ///
								"Evansville and Terre Haute Railroad")
replace region = "W" if inlist(cname, "Ft Worth & Den City", "FT Woth & Den City", ///
								"Fort Worth and Denver City")
replace region = "W" if inlist(cname, "Ft Worth & Rio Grande", "Ft Worth & Rio grands")
replace region = "W" if cname == "GREAT NORTHERN RAILWAY CO."
replace region = "W" if cname == "Green Bay & Western"
replace region = "W" if inlist(cname, "GREEN BAY, WINONA & ST. PAUL RAILROAD CO.", ///
								"GREEN BAY, WINONA & ST. PAUL", ///
								"Green Bay, Winona and St. Paul Railroad")
replace region = "S" if cname == "Gulf Mob & Nor"
replace region = "W" if cname == "Hannibal and St. Joseph Railroad"
replace region = "N" if inlist(cname, "HARLEM RIVER AND PORT CHESTER RAILROAD", ///
								"Harlem River and Portchester Railroad")
replace region = "N" if cname == "Hocking Valley"
replace region = "W" if inlist(cname, "HOUSTON & TEXAS CENTRAL", ///
								"Houston and Texas Central Railroad", ///
								"Houston and Texas Central Railway")
replace region = "S" if inlist(cname, "ILLINOIS CENTRAL RAILROAD CO.", "ILLINOIS CENTRAL", ///
								"Illinois Central Railroad")
replace region = "N" if cname == "Indiana, Bloomington and Western Railway"
replace region = "N" if cname == "Indianapolis, Cincinnati & Lafayette Railroad"
replace region = "W" if cname == "IOWA CENTRAL RAILWAY CO."
replace region = "W" if cname == "K C F S & M"
replace region = "N" if cname == "Kanawha & Michigan"
replace region = "W" if cname == "Kansas City Southern"
replace region = "W" if inlist(cname, "KEOKUK & DES MOINES", "Keokuk & DesM", ///
								"KEOKUK & DES MOINES RAILROAD CO.", "Keokuk & DesMoines", ///
								"Keokuk and Des Moines Railroad")
replace region = "N" if cname == "KINGSTON & PEMBROKE"
replace region = "N" if inlist(cname, "LAKE ERIE & WESTERN RAILROAD CO.", ///
								"LAKE ERIE & WESTERN", ///
								"Lake Erie and Western Railway")
replace region = "N" if inlist(cname, "Lake Shore & Mich Southern", ///
								"LAKE SHORE & MICHIGAN SOUTHERN RAILWAY CO.", ///
								"LAKE SHORE & MICHIGAN SOUTHERN", ///
								"Lake Shore and Michigan Southern Railway", ///
								"Lakeshore and Michigan Southern Railway")
replace region = "N" if cname == "Lehigh Valley"
replace region = "N" if cname == "Ligonier Valley Railroad"
replace region = "N" if inlist(cname, "LONG ISLAND RAILROAD CO.", "LONG ISLAND", ///
								"Long Island Railroad")
replace region = "W" if cname == "Louisiana and Missouri River Railroad"
replace region = "S" if inlist(cname, "LOUISVILLE & NASHVILLE RAILROAD CO.", ///
								"LOUISVILLE & NASHVILLE", ///
								"Louisville and Nashville Railroad")
replace region = "N" if inlist(cname, "LOUISVILLE, NEW ALBANY & CHICAGO.", ///
								"LOUISVILLE, NEW ALBANY & CHICAGO", ///
								"Louisville, New Albany and Chicago Railway")
replace region = "N" if inlist(cname, "MANHATTAN RAILWAY CO.", "MANHATTAN", ///
								"Manhattan Railway")
replace region = "N" if cname == "MAHONING COAL RAILROAD"
replace region = "N" if cname == "Marietta and Cincinnati Railroad"
replace region = "W" if cname == "MARQUETTE, HOUGHTON AND ONTONAGON RAILROAD COMPANY"
replace region = "S" if cname == "Memphis and Charleston Railroad"
replace region = "N" if cname == "Metropolitan Elevated Railway"
replace region = "W" if inlist(cname, "MEXICAN CENTRAL RAILWAY CO., LIMITED", ///
								"MEXICAN CENTRAL", "MEXICAN NATIONAL RAILROAD CO.", ///
								"MEXICAN NATIONAL", "Mex Central")
replace region = "N" if inlist(cname, "MICHIGAN CENTRAL RAILROAD CO.", ///
								"MICHIGAN CENTRAL", "Michigan Central Railroad")
replace region = "W" if inlist(cname, "MILWAUKEE, LAKE SHORE & WESTERN", ///
								"Milwaukee, Lake Shore and Western Railway")
replace region = "W" if inlist(cname, "Minn St Paul & S S M", "Minn St. Paul & S S M")
replace region = "W" if inlist(cname, "Minneapolis & St. Louis", ///
								"MINNEAPOLIS & ST. LOUIS", ///
								"Minneapolis and St. Louis Railway")
replace region = "W" if inlist(cname, "MISSOURI PACIFIC RAILWAY CO.", ///
								"MISSOURI PACIFIC", "Missouri Pacific Railway")
replace region = "W" if inlist(cname, "MISSOURI, KANSAS & TEXAS RAILWAY CO.", ///
								"MISSOURI, KANSAS & TEXAS", ///
								"Missouri, Kansas and Texas Railway")
replace region = "S" if inlist(cname, "MOBILE & OHIO RAILROAD CO.", ///
								"MOBILE & OHIO", "Mobile and Ohio Railroad")
replace region = "N" if inlist(cname, "Morris & Essex Railroad Co", ///
							"MORRIS AND ESSEX RR.", "MORRIS AND ESSEX RAILROAD", ///
							"Morris and Essex Railroad")
replace region = "S" if inlist(cname, "Nashville Chatt & St Louis", ///
								"NASHVILLE, CHATTANOOGA & ST. LOUIS RAILWAY", ///
								"NASHVILLE, CHATTANOOGA & ST. LOUIS", ///
								"Nashville, Chattanooga and St. Louis Railway")
replace region = "W" if cname == "National Rys of Mex"
replace region = "W" if cname == "New Orleans Tex & Mex"
replace region = "N" if inlist(cname, "NEW YORK AND NEW ENGLAND RAILROAD COMPANY", ///
								"NEW YORK & NEW ENGLAND")
replace region = "N" if cname == "NEW YORK & NORTHERN"
replace region = "N" if cname == "NY & Harlem"
replace region = "N" if inlist(cname, "NEW YORK CENTRAL & HUDSON RIVER", ///
							"NEW YORK CENTRAL & HUDSON RIVER RAILROAD CO.", ///
							"New York Central & Hudson River Railroad", ///
							"New York Central, Hudson River and Fort Orange Rail Road")
replace region = "N" if inlist(cname, "NEW YORK, CHICAGO & ST. LOUIS", ///
								"NEW YORK, CHICAGO & ST. LOUIS RAILROAD CO.", ///
								"New York, Chicago and St. Louis Railway")
replace region = "N" if inlist(cname, "New York Elevated Railroad", ///
								"New York and Elevated Railroad")
replace region = "N" if inlist(cname,"NEW YORK, LACKAWANNA & WESTERN", ///
								"NEW YORK, LACKAWANNA & WESTERN RAILROAD CO.", ///
								"New York, Lackawanna and Western Railroad")
replace region = "N" if inlist(cname, "NEW YORK, LAKE ERIE & WESTERN", ///
								"NEW YORK, LAKE ERIE & WESTERN RAILROAD CO.", ///
								"New York, Lake Erie and Western Railroad")
replace region = "N" if inlist(cname, "New York and New England Railroad")
replace region = "N" if inlist(cname, "NEW YORK, NEW HAVEN & HARTFORD", ///
								"NEW YORK, NEW HAVEN & HARTFORD RAILROAD CO.", ///
								"New York, New Haven and Hartford Railroad", ///
								"New York, New Haven, and Hartford Railroad")
replace region = "N" if inlist(cname, "New York, Ontario and Western Railway", ///
								"NEW YORK, ONTARIO AND WESTERN RAILWAY COMPANY")
replace region = "N" if inlist(cname, "NEW YORK, SUSQUEHANNA & WESTERN", ///
								"NEW YORK, SUSQUEHANNA & WESTERN RAILROAD CO.", ///
								"New York, Susquehanna and Western Railroad")
replace region = "S" if inlist(cname, "NORFOLK & WESTERN", ///
								"Norfolk and Western Railroad", ///
								"NORFOLK & WESTERN RAILROAD CO.")
replace region = "W" if inlist(cname, "NORTHERN PACIFIC RAILROAD CO.", ///
								"NORTHERN PACIFIC TERMINAL CO. OF OREGON", ///
								"NORTHERN PACIFIC", "Northern Pacific Railroad")
replace region = "S" if cname == "NO Mobile & Chicago"
replace region = "S" if inlist(cname, "Norfok & Southern", "Norfolk Southern")
replace region = "N" if cname == "Northern Central"
replace region = "N" if cname == "OHIO, INDIANA & WESTERN"
replace region = "S" if inlist(cname, "Ohio and Mississippi Railway", ///
								"OHIO & MISSISSIPPI")
replace region = "N" if inlist(cname, "OHIO SOUTHERN", "Ohio Southern Railroad")
replace region = "W" if inlist(cname, "OREGON RAILWAY & NAVIGATION CO.", ///
								"OREGON & TRANSCONTINENTAL CO.", ///
								"Oregon and Transcontinental Company", ///
								"OREGON RAILWAY AND NAVIGATION COMPANY", ///
								"Oregon Railway and Navigation", ///
								"Oregon Railway and Navigation Co.")
replace region = "W" if inlist(cname, "Oregon Short Line Railway", ///
								"OREGON SHORT LINE & UTAH NORTHERN RAILWAY CO.", ///
								"OREGON SHORT LINE AND UTAH NORTHERN RAILWAY")
replace region = "W" if inlist(cname, "PANAMA RAILROAD CO.", "PANAMA", ///
								"Panama Railroad")
replace region = "N" if inlist(cname, "Pennsylvania RR", ///
								"PENNSYLVANIA RAILROAD CO.")
replace region = "N" if inlist(cname, "Peoria, Decatur & Evansville", ///
								"PEORIA, DECATUR & EVANSVILLE RAILWAY CO.", ///
								"PEORIA, DECATUR & EVANSVILLE", ///
								"Peoria, Decatur and Evansville Railway")
replace region = "N" if inlist(cname, "PEORIA & EASTERN RAILROAD CO.", ///
								"PEORIA AND EASTERN")
replace region = "N" if cname == "Pere Marquette"
replace region = "N" if inlist(cname, "PHILADELPHIA & READING RAILROAD CO.", ///
								"PHILADELPHIA & READING", ///
								"Philadelphia and Reading Railroad")
replace region = "N" if inlist(cname, "Pitts Cin Chic & St Louis", "Pitt Cin Chic & St. Louis", ///
								"PITTSBURGH, CINCINNATI, CHICAGO & ST. LOUIS")
replace region = "N" if inlist(cname, ///
							"PITTSBURGH, FORT WAYNE AND CHICAGO RAILWAY COMPANY", ///
							"Pittsburgh, Fort Wayne and Chicago Railway")
replace region = "N" if inlist(cname, "PITTSBURGH & WESTERN RAILROAD CO.", ///
								"PITTSBURGH & WESTERN", "Pitts & West Virginia")
replace region = "N" if cname == "Reading"
replace region = "N" if inlist(cname, "RENSSELAER & SARATOGA RAILROAD CO.", ///
							"RENSSELAER AND SARATOGA RAILROAD", "Rens & Sara", ///
							"Rensselaer and Saratoga Railroad", "Rens & Saratoga")
replace region = "S" if inlist(cname, "Richmond and Alleghany Railroad")
replace region = "S" if inlist(cname, "RICHMOND & DANVILLE", ///
							"Richmond and Danville Railroad")
replace region = "S" if inlist(cname, ///
				"RICHMOND AND WEST POINT TERMINAL RAILWAY AND WAREHOUSE COMPANY", ///
				"Richmond and West Point Terminal Railway and Warehouse Co.")
replace region = "W" if inlist(cname, "RIO GRANDE WESTERN RAILWAY CO.", ///
							"RIO GRANDE WESTERN")
replace region = "W" if cname == "Rock Island Co"
replace region = "N" if inlist(cname, "Rochester and Pittsburgh Railroad")
replace region = "N" if inlist(cname, "ROME, WATERTOWN & OGDENSBURGH", "Rome Water & Ogden", ///
						"ROME, WATERTOWN & OGDENSBURG RAILROAD CO.", "Rome Watertown & Ogdensb", ///
						"Rome, Watertown and Ogdensburg Railroad", "Rome Wat & Og")
replace region = "N" if cname == "Rutland"
replace region = "S" if cname == "Seaboard Air Line"
replace region = "S" if inlist(cname, "Southern", "SOUTHERN RAILWAY CO.", ///
							"SOUTH CAROLINA")
replace region = "W" if cname == "SOUTHERN PACIFIC COMPANY"
replace region = "W" if inlist(cname, "St Joseph & Grand Island", "St. Joseph & Grand")
replace region = "N" if cname == "St Lawrence & Adirondack"
replace region = "W" if cname == "St Louis Southwestern"
replace region = "N" if inlist(cname, "ST. LOUIS, ALTON & TERRE HAUTE", ///
							"ST. LOUIS, ALTON & TERRE HAUTE RAILROAD CO.", ///
							"St. Louis, Alton and Terre Haute Railroad")
replace region = "W" if inlist(cname, "ST. LOUIS, ARKANSAS & TEXAS")
replace region = "W" if inlist(cname, "St. Louis, Iron Mountain and Southern RR.")
replace region = "W" if inlist(cname, "ST. LOUIS & SAN FRANCISCO", ///
							"St. Louis and San Francisco Railway")
replace region = "W" if inlist(cname, "ST. LOUIS SOUTHWESTERN RAILWAY CO.", ///
							"ST. LOUIS SOUTHWESTERN RAILWAY COMPANY")
replace region = "W" if inlist(cname, "ST. PAUL & DULUTH RAILROAD CO.", ///
							"ST. PAUL & DULUTH")
replace region = "W" if inlist(cname, "St. Paul and Sioux City Railroad")
replace region = "W" if inlist(cname, "ST. PAUL MINNEAPOLIS AND MANITOBA RAILWAY", ///
							"ST. PAUL, MINNEAPOLIS & MANITOBA RAILWAY CO.", ///
							"St. Paul, Minneapolis and Manitoba Railway")
replace region = "W" if cname == "Texas Central"
replace region = "W" if inlist(cname, "TEXAS & PACIFIC RAILWAY CO.", ///
							"TEXAS & PACIFIC", "Texas and Pacific Railway")
replace region = "N" if inlist(cname,"TOLEDO, ANN ARBOR & NORTH MICHIGAN", ///
							"TOLEDO, ANN ARBOR & NORTH MICHIGAN RAILWAY CO.")
replace region = "N" if inlist(cname, "TOLEDO & OHIO CENTRAL RAILWAY CO.", ///
							"TOLEDO & OHIO CENTRAL", ///
							"Toledo and Ohio Central Railroad")
replace region = "N" if inlist(cname, "TOLEDO, PEORIA & WESTERN")
replace region = "N" if cname == "Toledo St Louis & Western"
replace region = "W" if inlist(cname, "UTAH CENTRAL")
replace region = "W" if inlist(cname, "UNION PACIFIC RAILWAY CO.", "UNION PACIFIC", ///
							"Union Pacific Railway")
replace region = "N" if cname == "Vandalia"
replace region = "S" if inlist(cname, "VIRGINIA MIDLAND RAILWAY CO.", ///
							"VIRGINIA MIDLAND")
replace region = "W" if inlist(cname, "WABASH RAILROAD CO.", "WABASH RAILROAD", ///
							"Wabash, St. Louis and Pacific Railway")
replace region = "N" if cname == "Western Maryland"
replace region = "W" if cname == "Western Pacific"
replace region = "W" if cname == "Western Union Railroad"
replace region = "N" if inlist(cname, "WHEELING & LAKE ERIE RAILWAY CO.", ///
							"WHEELING & LAKE ERIE")
replace region = "W" if inlist(cname, "WISCONSIN CENTRAL")