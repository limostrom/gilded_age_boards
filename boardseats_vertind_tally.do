/*
boardseats_vertind_tally.do

*/


gen counter = 1

//Agriculture
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Chemicals", "Farming Machinery", "Food & Beverages", ///
				"Land/Real Estate", "Agriculture")
gen boardseats_vertind_num = v if ind == "Agriculture"
drop v

//Automobiles
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Engines", "General Manufacturing", "Rubber", "Steel", "Automobiles")
replace boardseats_vertind_num = v if ind == "Automobiles"
drop v

//Chemicals
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Agriculture", "Sugar", "Tobacco", "Chemicals")
replace boardseats_vertind_num = v if ind == "Chemicals"
drop v

//Consumer Goods
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Leather", "Retail", "Textiles", "Consumer Goods")
replace boardseats_vertind_num = v if ind == "Consumer Goods"
drop v

//Engines
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Automobiles", "Farming Machinery", "Locomotives", ///
			"General Manufacturing", "Engines")
replace boardseats_vertind_num = v if ind == "Engines"
drop v

//Entertainment
replace boardseats_vertind_num = 0 if ind == "Entertainment"

//Express
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Locomotives", "Mining / Smelting & Refining", "Shipping", "Express")
replace boardseats_vertind_num = v if ind == "Express"
drop v

//Farming Machinery
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Agriculture", "Engines", "General Manufacturing", "Steel", ///
				"Sugar", "Tobacco", "Farming Machinery")
replace boardseats_vertind_num = v if ind == "Farming Machinery"
drop v

//Food & Beverages
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Agriculture", "Retail", "Sugar", "Food & Beverages")
replace boardseats_vertind_num = v if ind == "Food & Beverages"
drop v

//General Manufacturing
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Automobiles", "Engines", "Farming Machinery", "Locomotives", ///
				"Steel", "General Manufacturing")
replace boardseats_vertind_num = v if ind == "General Manufacturing"
drop v

//Holding
replace boardseats_vertind_num = 0 if ind == "Holding"

//Insurance
replace boardseats_vertind_num = 0 if ind == "Insurance"

//Land/Real Estate
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Agriculture", "Land/Real Estate")
replace boardseats_vertind_num = v if ind == "Land/Real Estate"
drop v
	 
//Leather
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Consumer Goods", "Leather", "Retail", "Textiles", "Leather")
replace boardseats_vertind_num = v if ind == "Leather"
drop v

//Locomotives
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Engines", "Express", "General Manufacturing", "Steel" ///
				"Mining / Smelting & Refining", "Locomotives")
replace boardseats_vertind_num = v if ind == "Locomotives"
drop v

//Mining, Smelting, Refining
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Express", "Locomotives", "Mining / Smelting & Refining", ///
				"Steel", "Mining / Smelting & Refining")
replace boardseats_vertind_num = v if ind == "Mining / Smelting & Refining"
drop v

//Oil
replace boardseats_vertind_num = 0 if ind == "Oil"

//Paper
replace boardseats_vertind_num = 0 if ind == "Paper"

//Pharmaceuticals
replace boardseats_vertind_num = 0 if ind == "Pharmaceuticals"

//Retail
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Consumer Goods", "Food & Beverages", "Leather", "Textiles", ///
			"Tobacco", "Wholesale Dry Goods", "Retail")
replace boardseats_vertind_num = v if ind == "Retail"
drop v

//Rubber
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Automobiles", "Rubber")
replace boardseats_vertind_num = v if ind == "Rubber"
drop v

//Shipping
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Express", "Shipping")
replace boardseats_vertind_num = v if ind == "Shipping"
drop v

//Steel
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Automobiles", "Farming Machinery", "General Manufacturing", ///
				"Locomotives", "Mining / Smelting & Refining", "Steel")
replace boardseats_vertind_num = v if ind == "Steel"
drop v

//Sugar
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Chemicals", "Farming Machinery", "Sugar")
replace boardseats_vertind_num = v if ind == "Sugar"
drop v

//Textiles
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Consumer Goods", "Leather", "Retail", "Textiles")
replace boardseats_vertind_num = v if ind == "Textiles"
drop v

//Tobacco
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Chemicals", "Farming Machinery", "Retail", "Tobacco")
replace boardseats_vertind_num = v if ind == "Tobacco"
drop v

//Wholesale Dry Goods
bys fullname_m repeat: egen v = total(counter) if ///
	 inlist(ind, "Retail", "Wholesale Dry Goods")
replace boardseats_vertind_num = v if ind == "Wholesale Dry Goods"
drop v


replace boardseats_vertind_num = 0 if boardseats_vertind_num == .
drop counter

replace boardseats_vertind_num = boardseats_vertind_num - boardseats_sameind_num ///
	if boardseats_vertind_num > 0
assert boardseats_vertind_num >= 0
