/*
prequin_import.do

Dataset acquired from Prequin (see README.txt)
*/

clear all
set more off
pause on

local tables 0
local plots 1
local guess_stage 0
local investor_tab 0


global repo "C:/Users/lmostrom/Documents/GitHub/healthcare_trends/"
global drop "C:/Users/lmostrom/Dropbox/Amitabh"

cap cd "$drop/VC_Deals/Data"

import excel "PreqinVentureDeals_20200323160505.xlsx", ///
	clear cellra(A14:W36128) first case(lower)

isid venture_id // unique

keep if vcindustryclassification == "Healthcare"
gen dealyear = year(dealdate)


