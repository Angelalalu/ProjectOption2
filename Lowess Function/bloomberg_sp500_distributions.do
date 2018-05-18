********************************************************************************
/*
	By: Sooji Kim
	Date: 04/17/18
	
	This program uses the prices of options (obtained from Bloomberg) 
	based on the S&P 500 and the lowess smoothing command in Stata to infer 
	option-implied distributions of the stock market for the following dates:
	
	1. October 7, 2016 - ~1 month before 2016 Presidential election
	2. November 7, 2016 - 1 day before 2016 Presidential election
	3. November 10, 2016 - 2 days after 2016 Presidential election
	4. December 8, 2016 - 1 month after 2016 Presidential election
	5. December 29, 2017 - last business day in 2017
	6. January 25, 2018 - 1 week before jump in VIX
	7. February 6, 2018 - peak in VIX
	8. April 17, 2018 - last available date in data (i.e. today)
*/
********************************************************************************
if "`c(os)'" == "Unix" {
	global path "/bulk/data/refm-lab/users/sooji_kim/miscellaneous/options"
}
else if "`c(os)'" == "Windows" {
	global path "\\Client\Y$\miscellaneous\options"
	
}

cd $path
********************************************************************************
* import excel using Raw/bloomberg_sp500_option_prices.xlsx, firstrow clear

cd "C:\Users\Sizhu\Documents\03_2018Summer\Option\ProjectOption"
import excel using spOptions_Bloomberg.xlsx, firstrow clear
drop F-J

* Mark relevant dates. *
gen elect_1m_b = price_date == td(07oct2016)
gen elect_1d_b = price_date == td(07nov2016)
gen elect_2d_a = price_date == td(10nov2016)
gen elect_1m_a = price_date == td(08dec2016)
gen last_2017 = price_date == td(29dec2017)
gen before_vix = price_date == td(25jan2018)
gen vix_jump = price_date == td(06feb2018)
gen today = price_date == td(17apr2018)

* Keep relevant variables. *
keep price_date strike_price bid elect_1m_b - today

********************************************************************************
* Make strike differences uniform.
bysort price_date (strike_price): gen diff = strike_price[_n+1]-strike_price[_n]
expand diff/5 if diff != 5 & diff != .
sort price_date strike_price
bysort price_date strike_price: gen order = _n - 1
bysort price_date strike_price: replace bid = . if _n > 1 & diff > 5 & diff != .
bysort price_date strike_price: replace strike_price = strike_price + 5 * (_n - 1)
bysort price_date: csipolate bid strike_price, gen (ipl_bid)
order ipl_bid, before(bid)
drop diff order

********************************************************************************
* Smooth prices using lowess. *
tsset price_date strike_price

foreach date of varlist elect_1m_b - today {
	lowess ipl_bid strike_price if `date' == 1, gen(lowess_`date') bwidth(0.3) nograph 
	
	graph twoway (scatter ipl_bid strike_price) (scatter bid strike_price, mc(yellow)) ///
		(line lowess_`date' strike_price, lc(red)) if `date' == 1, ///
		title("Option Price") xtitle("S&P 500 Strike Price")  ///
		legend(off) graphregion(color(white)) name(`date', replace) nodraw	
}

********************************************************************************
* Calculate the second derivative for the smoothed data. *

foreach date of varlist elect_1m_b - today {

	if "`date'" == "elect_1m_b" {
		local date_desc "1 month before 2016 U.S. Pres. election"
		local date_num "10/07/16"
	}
	else if "`date'" == "elect_1d_b" {
		local date_desc "1 day before 2016 U.S. Pres. election"
		local date_num "11/07/16"
	}
	else if "`date'" == "elect_2d_a" {
		local date_desc "2 days after 2016 U.S. Pres. election"
		local date_num "11/10/16"
	}
	else if "`date'" == "elect_1m_a" {
		local date_desc "1 month after 2016 U.S. Pres. election"
		local date_num "12/08/16"
	}
	else if "`date'" == "last_2017" {
		local date_desc "Last available date in 2017"
		local date_num "12/29/17"
	}
	else if "`date'" == "before_vix" {
		local date_desc "1 week before VIX jump in Feb. 2018"
		local date_num "01/25/18"
	}	
	else if "`date'" == "vix_jump" {
		local date_desc "Day of VIX jump"
		local date_num "02/06/18"
	}
	else {
		local date_desc "Last available date"
		local date_num "04/17/18"
	}
	
	bysort price_date (strike_price): gen dd2_lowess_`date' = ((lowess_`date'[_n-1] - lowess_`date'[_n]) - (lowess_`date'[_n] - lowess_`date'[_n+1]))/25
	replace dd2_lowess_`date' = 0 if dd2_lowess_`date' < 0
	
	graph twoway scatter dd2_lowess_`date' strike_price if `date' == 1, ///
		title("Implied Distribution") ///
		xtitle("S&P 500 Strike Price") ytitle("") ///
		graphregion(color(white)) name(dd2_`date', replace) nodraw
	
	graph combine `date' dd2_`date', ///
		title("`date_desc' (`date_num')") subtitle("Call option, Bid price") ///
		graphregion(color(white))
	graph export bloomberg_`date'.png
}

* Combine implied distributions for before_vix, vix_jump, and today. *
graph twoway (line dd2_lowess_before_vix dd2_lowess_vix_jump dd2_lowess_today strike_price, lwidth(thick thick thick) lpattern(dash "--.." solid)) ///
	if strike_price >= 1500 & strike_price <= 3500, ///
	xlabel(1500(500)3500) xtitle("S&P 500 Strike Price") ytitle("") ///
	legend(order(1 "01/25/18 (Before VIX)" 2 "02/06/18 (VIX jump)" ///
	3 "04/17/18 (Last day)") rows(1) symxsize(4)) ///
	graphregion(color(white))
graph save Temp/Graphs/sp500/bloomberg_2018_dates, replace
graph export Temp/Graphs/sp500/bloomberg_2018_dates.png, replace
