********************************************************************************
/*
	By: Sooji Kim
	Date: 04/16/18
	
	This program uses the prices of options based on the S&P 500 and the lowess
	smoothing command in Stata to infer option-implied distributions of the 
	stock market for the following dates:
	
	1. August 21, 2015 - 1 business day before jump in VIX
	2. August 24, 2015 - day of jump in VIX
	3. October 7, 2016 - ~1 month before 2016 Presidential election
	4. November 7, 2016 - 1 day before 2016 Presidential election
	5. November 9, 2016 - 1 day after 2016 Presidential election
	6. October 6, 2017 - ~1 year after October 2016 date
	7. December 29, 2017 - last available date in data
*/
********************************************************************************
if "`c(os)'" == "Unix" {
	global path "/bulk/data/refm-lab/users/sooji_kim/miscellaneous/options"
}
else if "`c(os)'" == "Windows" {
	global path "\\Client\Y$\miscellaneous\options"
}

cd $path

* Save maturity to use. *
global maturity = 49

* Mark as 1 if want to compare interpolation methods. *
global ipl_compare = 1
********************************************************************************

import delimited using Raw/sp500_option_prices.csv, clear

* Format dates. *
tostring date exdate, replace
gen price_date = date(date, "YMD")
order price_date, before(date)
gen mat_date = date(exdate, "YMD")
order mat_date, before(exdate)
format price_date mat_date %td

* Mark relevant dates. *
gen vix_before = price_date == td(21aug2015)
gen vix_jump = price_date == td(24aug2015)
gen elect_1m_b = price_date == td(07oct2016)
gen elect_1d_b = price_date == td(07nov2016)
gen elect_1d_a = price_date == td(09nov2016)
gen oct_2017 = price_date == td(06oct2017)
gen dec_2017 = price_date == td(29dec2017)

gen keep = .
foreach var of varlist vix_before - dec_2017 {
	replace keep = 1 if `var' == 1
}
keep if keep == 1

* Differentiate between SPX and SPXW options. *
gen space = strpos(symbol, " ")
gen symbol_type = substr(symbol, 1, space - 1)
keep if symbol_type == "SPXW"

* Calculate maturity. *
gen maturity = mat_date - price_date
order maturity, before(mat_date)

* Keep relevant variables. *
keep secid price_date symbol_type maturity mat_date cp_flag strike_price best_bid best_offer volume open_interest impl_volatility vix_before-dec_2017

* Keep options with specified maturity. *
gen diff = abs(maturity - $maturity)
bysort price_date (maturity): egen mindiff = min(diff)
keep if diff == mindiff
drop diff mindiff

sort price_date cp_flag strike_price
replace strike_price = strike_price /1000

********************************************************************************
* Make strike differences uniform.
bysort secid price_date cp_flag (strike_price): gen diff = strike_price[_n+1]-strike_price[_n]
expand diff/5 if diff != 5 & diff != .
sort secid price_date cp_flag strike_price
bysort secid price_date cp_flag strike_price: gen order = _n - 1
bysort secid price_date cp_flag strike_price: replace best_bid = . if _n > 1 & diff > 5 & diff != .
bysort secid price_date cp_flag strike_price: replace best_offer = . if _n > 1 & diff > 5 & diff != .
bysort secid price_date cp_flag strike_price: replace strike_price = strike_price + 5 * (_n - 1)
bysort secid price_date cp_flag: csipolate best_bid strike_price, gen (ipl_bid)
bysort secid price_date cp_flag: csipolate best_offer strike_price, gen (ipl_offer)
order ipl_bid ipl_offer, before(best_bid)

********************************************************************************
* Smooth prices using lowess. *
egen ogroup = group(secid price_date cp_flag)
tsset ogroup strike_price

levelsof cp_flag, local(cp)
local bidoffer "bid offer"

foreach date of varlist vix_before-dec_2017 {
	foreach otype of local cp {
		foreach ptype of local bidoffer {
			lowess ipl_`ptype' strike_price if `date' == 1 & cp_flag == "`otype'", ///
				gen(lowess_`date'_`otype'`ptype') bwidth(0.2) nograph 
			
			graph twoway (scatter ipl_`ptype' strike_price) (scatter best_`ptype' strike_price, mc(yellow)) ///
				(line lowess_`date'_`otype'`ptype' strike_price, lc(red)) ///
				if `date' == 1 & cp_flag == "`otype'", ///
				title("Interpolation & Lowess smoother") ///
				xtitle("S&P 500 Strike Price") ytitle("`ptype' price") ///
				legend(order(2 "Raw" 1 "Interpolated" 3 "Lowess") rows(1) symxsize(4)) ///
				graphregion(color(white)) name(`date'_`otype'`ptype', replace) nodraw
		}
	}
}

********************************************************************************
* Calculate the second derivative for the smoothed data. *

levelsof cp_flag, local(cp)
local bidoffer "bid offer"

foreach date of varlist vix_before-dec_2017 {

	if "`date'" == "vix_before" {
		local date_desc "1 bus. day before VIX jump"
		local date_num 	"08/21/15"
	}
	else if "`date'" == "vix_jump" {
		local date_desc "Day of VIX jump"
		local date_num "08/24/15" 
	}
	else if "`date'" == "elect_1m_b" {
		local date_desc "1 month before 2016 U.S. Pres. election"
		local date_num "10/07/16"
	}
	else if "`date'" == "elect_1d_b" {
		local date_desc "1 day before 2016 U.S. Pres. election"
		local date_num "11/07/16"
	}
	else if "`date'" == "elect_1d_a" {
		local date_desc "1 day after 2016 U.S. Pres. election"
		local date_num "11/09/16"
	}
	else if "`date'" == "oct_2017" {
		local date_desc "October 2017"
		local date_num "10/06/17"
	}
	else {
		local date_desc "Last available date"
		local date_num "12/29/17"
	}
	
	foreach otype of local cp {
		
		if "`otype'" == "C" local cp_desc "call"
		else local cp_desc "put"
		
		foreach ptype of local bidoffer {
			bysort secid price_date cp_flag (strike_price): gen dd2_lowess_`date'_`otype'`ptype' = ((lowess_`date'_`otype'`ptype'[_n-1] - lowess_`date'_`otype'`ptype'[_n]) - (lowess_`date'_`otype'`ptype'[_n] - lowess_`date'_`otype'`ptype'[_n+1]))/25
			
			graph twoway (scatter dd2_lowess_`date'_`otype'`ptype' strike_price if dd2_lowess_`date'_`otype'`ptype' >= 0) ///
				(scatter dd2_lowess_`date'_`otype'`ptype' strike_price if dd2_lowess_`date'_`otype'`ptype' < 0, mc(red)) ///
				if `date' == 1 & cp_flag == "`otype'", ///
				title("2nd Derivative") ///
				xtitle("S&P 500 Strike Price") ytitle("Probability") ///
				legend(order(1 ">= 0" 2 "< 0")) graphregion(color(white)) ///
				name(dd2_`date'_`otype'`ptype', replace) nodraw
			
			graph combine `date'_`otype'`ptype' dd2_`date'_`otype'`ptype', ///
				title("`date_desc' (`date_num')") subtitle("`cp_desc' option, `ptype' price") ///
				graphregion(color(white))
			graph save Temp/Graphs/sp500/`date'_`otype'`ptype', replace
			graph export Temp/Graphs/sp500/`date'_`otype'`ptype'.png, replace
			
		}	
	}
}
