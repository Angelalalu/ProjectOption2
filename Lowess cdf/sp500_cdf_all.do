cd "C:\Users\Sizhu\Documents\03_2018Summer\Option\ProjectOption\Lowess cdf"
import delimited using sp500_option_prices_1996_2017.csv, clear
set more off

* Save maturity to use. *
global maturity = 49

* Format dates. *
tostring date exdate, replace
gen price_date = date(date, "YMD")
order price_date, before(date)
gen mat_date = date(exdate, "YMD")
order mat_date, before(exdate)
format price_date mat_date %td

* Keep 2013 options. *
gen price_year = substr(date, 1, 4)
order price_year, before(date)
destring price_year, replace
keep if price_year > 2001
drop price_year

* Save distinct values of price_date


* Differentiate between SPX and SPXW options. *
gen space = strpos(symbol, " ")
gen symbol_type = substr(symbol, 1, space - 1)
keep if symbol_type == "SPXW"

* Calculate maturity. *
gen maturity = mat_date - price_date
order maturity, before(mat_date)

* Keep relevant variables. *
keep secid price_date symbol_type maturity mat_date cp_flag strike_price best_bid best_offer volume open_interest impl_volatility

* Keep options with specified maturity. *
gen diff = abs(maturity - $maturity)
bysort price_date (maturity): egen mindiff = min(diff)
keep if diff == mindiff
drop diff mindiff

sort price_date cp_flag strike_price
replace strike_price = strike_price /1000

********************************************************************************
* Make strike differences uniform. *
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

* Check the number of days. *
*by price_date maturity, sort: gen nvals = _n==1
*count if nvals
*drop nvals
*by price_date cp_flag, sort: gen nvals = _n==1
*count if nvals
*drop nvals

********************************************************************************
* Smooth prices using lowess. *
egen ogroup = group(secid price_date cp_flag)
tsset ogroup strike_price

* Generate the lowess, 2nd derivative(pdf) and cdf. * 
levelsof price_date, local(datelist)
levelsof cp_flag, local(cp)
local bidoffer "bid offer"

foreach t of local datelist{
di "`t'"
	foreach otype of local cp{
		foreach ptype of local bidoffer{
			lowess ipl_`ptype' strike_price if price_date == `t' & cp_flag == "`otype'", gen(lowess_`t'_`otype'`ptype') bwidth(0.2) nograph
			bysort secid price_date cp_flag (strike_price): gen dd2_lowess_`t'_`otype'`ptype' = ((lowess_`t'_`otype'`ptype'[_n-1] - lowess_`t'_`otype'`ptype'[_n]) - (lowess_`t'_`otype'`ptype'[_n] - lowess_`t'_`otype'`ptype'[_n+1]))/25
			replace dd2_lowess_`t'_`otype'`ptype' = 0 if dd2_lowess_`t'_`otype'`ptype' < 0
			gen cum_dd2_lowess_`t'_`otype'`ptype' = sum(dd2_lowess_`t'_`otype'`ptype')
		}
	}
}

* Combine cdfs into one variable
gen cum_Pbid = .
gen cum_Poffer = .
gen cum_Cbid = .
gen cum_Coffer = .

levelsof price_date, local(datelist)
levelsof cp_flag, local(cp)
local bidoffer "bid offer"
foreach t of local datelist{
	foreach otype of local cp{
		foreach ptype of local bidoffer{
			replace cum_`otype'`ptype' = cum_dd2_lowess_`t'_`otype'`ptype' if price_date == `t' & cp_flag == "`otype'"
		}
	}
}

keep secid price_date maturity mat_date cp_flag strike_price ipl_bid ipl_offer best_bid best_offer volume open_interest impl_volatility symbol_type diff order cum_Pbid cum_Poffer cum_Cbid cum_Coffer
sort cp_flag price_date strike_price
order cum_Pbid cum_Cbid, before(ipl_bid)

* Standarize cdf
sort price_date cp_flag strike_price
bysort price_date cp_flag: egen standPbid = max(cum_Pbid)
bysort price_date cp_flag: egen standCbid = max(cum_Cbid)
gen standcum_Pbid = cum_Pbid / standPbid
gen standcum_Cbid = cum_Cbid / standCbid

* Save temporary data
* save "C:\Users\Sizhu\Documents\03_2018Summer\Option\ProjectOption\Lowess cdf\lowess_cdf_temporary.dta"

* Generate time series
local perclistP "5 10 25 50"
foreach i of local perclistP{
	use lowess_cdf_temporary.dta, clear
	gen d`i' = abs(standcum_Pbid - `i'/100)
	bysort price_date cp_flag: egen mind`i' = min(d`i')
	bysort price_date cp_flag: gen isp`i' = d`i'==mind`i'
	replace isp`i' = . if cp_flag == "C"
	keep secid price_date cp_flag strike_price isp`i'
	keep if isp`i' == 1
	keep price_date strike_price
	rename strike_price p`i'
	save p`i'.dta, replace
}
local perclistC "75 90 95"
foreach i of local perclistC{
	use lowess_cdf_temporary.dta, clear
	gen d`i' = abs(standcum_Cbid - `i'/100)
	bysort price_date cp_flag: egen mind`i' = min(d`i')
	bysort price_date cp_flag: gen isp`i' = d`i'==mind`i'
	replace isp`i' = . if cp_flag == "P"
	keep secid price_date cp_flag strike_price isp`i'
	keep if isp`i' == 1
	keep price_date strike_price
	rename strike_price p`i'
	save p`i'.dta, replace
}
use p5.dta, clear
merge 1:1 price_date using p10.dta
drop _merge
merge 1:1 price_date using p25.dta
drop _merge
merge 1:1 price_date using p50.dta
drop _merge
merge 1:1 price_date using p75.dta
drop _merge
merge 1:1 price_date using p90.dta
drop _merge
merge 1:1 price_date using p95.dta
drop _merge
save time_series.dta, replace


********************************************************************************
********************************************************************************
* Test codes below
* Test data - 02jan2013, call option, bid price
lowess ipl_bid strike_price if price_date == td(02jan2013) & cp_flag == "C", ///
	gen(lowess_02jan2013_Cbid) bwidth(0.2)

graph twoway (scatter ipl_bid strike_price) (scatter best_bid strike_price, mc(yellow)) ///
				(line lowess_02jan2013_Cbid strike_price, lc(red)) ///
				if price_date == td(02jan2013) & cp_flag == "C", ///
				title("Interpolation & Lowess smoother") ///
				xtitle("S&P 500 Strike Price") ytitle("bid price") ///
				legend(order(2 "Raw" 1 "Interpolated" 3 "Lowess") rows(1) symxsize(4)) ///
				graphregion(color(white)) name(jan2013_Cbid, replace)

bysort secid price_date cp_flag (strike_price): gen dd2_lowess_02jan2013_Cbid = ///
	((lowess_02jan2013_Cbid[_n-1] - lowess_02jan2013_Cbid[_n]) - ///
	(lowess_02jan2013_Cbid[_n] - lowess_02jan2013_Cbid[_n+1]))/25

graph twoway (scatter dd2_lowess_02jan2013_Cbid strike_price if dd2_lowess_02jan2013_Cbid >= 0) ///
				(scatter dd2_lowess_02jan2013_Cbid strike_price if dd2_lowess_02jan2013_Cbid < 0, mc(red)) ///
				if price_date == td(02jan2013) & cp_flag == "C", ///
				title("2nd Derivative") ///
				xtitle("S&P 500 Strike Price") ytitle("Probability") ///
				legend(order(1 ">= 0" 2 "< 0")) graphregion(color(white)) ///
				name(dd2_02jan2013_Cbid, replace)
				
gen cum_dd2_lowess_02jan2013_Cbid = sum(dd2_lowess_02jan2013_Cbid)
				
* Test data - 02jan2013, put option, bid price
lowess ipl_bid strike_price if price_date == td(02jan2013) & cp_flag == "P", ///
	gen(lowess_02jan2013_Pbid) bwidth(0.2)

graph twoway (scatter ipl_bid strike_price) (scatter best_bid strike_price, mc(yellow)) ///
				(line lowess_02jan2013_Pbid strike_price, lc(red)) ///
				if price_date == td(02jan2013) & cp_flag == "P", ///
				title("Interpolation & Lowess smoother") ///
				xtitle("S&P 500 Strike Price") ytitle("bid price") ///
				legend(order(2 "Raw" 1 "Interpolated" 3 "Lowess") rows(1) symxsize(4)) ///
				graphregion(color(white)) name(jan2013_Pbid, replace)

bysort secid price_date cp_flag (strike_price): gen dd2_lowess_02jan2013_Pbid = ///
	((lowess_02jan2013_Pbid[_n-1] - lowess_02jan2013_Pbid[_n]) - ///
	(lowess_02jan2013_Pbid[_n] - lowess_02jan2013_Pbid[_n+1]))/25

graph twoway (scatter dd2_lowess_02jan2013_Pbid strike_price if dd2_lowess_02jan2013_Pbid >= 0) ///
				(scatter dd2_lowess_02jan2013_Pbid strike_price if dd2_lowess_02jan2013_Pbid < 0, mc(red)) ///
				if price_date == td(02jan2013) & cp_flag == "P", ///
				title("2nd Derivative") ///
				xtitle("S&P 500 Strike Price") ytitle("Probability") ///
				legend(order(1 ">= 0" 2 "< 0")) graphregion(color(white)) ///
				name(dd2_02jan2013_Pbid, replace)
				
gen cum_dd2_lowess_02jan2013_Pbid = sum(dd2_lowess_02jan2013_Pbid)

* Test data - 5th percentile
