version 12
set more off

global keep_vars "cpsidp race hispan sex wtfinl empstat whyabsnt age month year ahrsworkt labforce statefip"
* Note: If using weekly earnings, will need to use earnwt variable

global raw_data_path "../raw"
global output_data_path "../data"

program main
    construct_cps_measures
end

program construct_cps_measures
    use ${keep_vars} using ../external/cps/cps_jan_jun_2020.dta, clear
    forvalues year = 2017/2019 {
        append using $raw_data_path/cps_jan_dec_`year'.dta, keep(${keep_vars})
    }
    append using  $raw_data_path/cps_jan_2013_dec_2016.dta, keep(${keep_vars})
    append using  $raw_data_path/cps_jan_2009_dec_2012.dta, keep(${keep_vars})
    append using  $raw_data_path/cps_jan_2005_dec_2008.dta, keep(${keep_vars})

    * Only counts work hours if at work and not in the Armed Forces
    replace ahrsworkt = 0 if ahrsworkt == 999
    rename ahrsworkt hours

    keep if age >= 16
    gen working = (empstat == 10)
    gen employed_nworking = (empstat == 12)
    gen employed = (employed_nworking == 1 | empstat == 10)
    gen unemployed = (empstat == 20 | empstat == 21 | empstat == 22)
    gen absent_other = (empstat == 12 & whyabsnt == 15)
    gen emp_positive = (employed == 1 & absent_other == 0) // Variable for employed and not absent with unknown reason
    gen laborforce = (empstat > 1 & empstat <= 22)

    * Generate gender variables
    gen male = (sex == 1)
    drop sex

    * Generate race variables
    rename race race_cps
    gen race = .
    replace race = 1 if (hispan >= 100 & hispan <= 500)
    replace race = 2 if (race_cps == 100 & race != 1)
    replace race = 3 if (race_cps == 200 & race != 1)
    replace race = 4 if (race_cps == 651 & race != 1)
    replace race = 5 if (race_cps == 300 & race != 1)
    replace race = 6 if (race_cps == 652 & race != 1)
    replace race = 7 if (race  == .)
    drop race_cps
    label define race_label 1 "Hispanic" 2 "White non-Hispanic" 3 "Black non-Hispanic" 4 "Asian non-Hispanic" 5 "American Indian/Alaskan" 6 "Hawaii and Pacific Islander" 7 "Other, or two or more"
    label values race race_label

    * Generate age group
    gen agegrp = .
    replace agegrp = 16 if (age >= 16 & age <= 24)
    forvalues i = 25(10)85 {
        local max_age = `i' + 9
        replace agegrp = `i' if (age >= `i' & age <= `max_age')
    }

    * Clean states
    replace statefip = . if statefip >= 61

    * Exclude military in total count
    gen total = (labforce == 1 | labforce == 2)
    foreach var in total hours unemployed laborforce employed working employed_nworking emp_positive {
        gen `var'_wgt = wtfinl*`var'
    }

    * Sample Sizes
    * Number of individuals in April 2020
    count if total == 1 & year == 2020 & month == 4 & statefip != .

    * Number of individuals since January 2011
    unique cpsidp if total == 1 & year >= 2011 & statefip != .

    * Minimum number of individuals in a month
    bys year month: egen samp_size = sum(total) if statefip != .
    sum samp_size if year >= 2011 & statefip != .
    local min_samp_size = r(min)
    di "Minimum sample size: `min_samp_size'"
    drop samp_size

    keep employed total *_wgt year month male statefip race agegrp  ag*
    save "${output_data_path}/cps_2005_2020_indiv.dta", replace

    gcollapse (sum) *_wgt, by(year month male statefip race agegrp)

    gen agegrpbroad = .
    replace agegrpbroad = 16 if agegrp == 16
    replace agegrpbroad = 25 if (agegrp >= 25 & agegrp <= 55)
    replace agegrpbroad = 65 if (agegrp >= 65)

    gen agegrpcdc = .
    replace agegrpcdc = 0 if agegrp == 16
    replace agegrpcdc = 25 if (agegrp == 25 | agegrp == 35)
    replace agegrpcdc = 45 if (agegrp == 45 | agegrp == 55)
    replace agegrpcdc = 65 if agegrp == 65
    replace agegrpcdc = 75 if agegrp == 75
    replace agegrpcdc = 85 if agegrp == 85

    gen unemployment_rate = unemployed_wgt/laborforce_wgt
    lab var unemployment_rate "Unemployment rate, unadjusted"
    gen employment_rate = employed_wgt/total_wgt
    lab var employment_rate "Employed divided by total population, unadjusted"

    gen year_month = ym(year, month)
    format year_month %tm
    sort year_month
    save "${output_data_path}/monthly_cps_2005_2020.dta", replace
end

* EXECUTE
main
