version 13
set more off

global statefip_full_vallist "1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56"
global agegrpcdc_full_vallist "0 25 45 65 75 85"
global all_full_vallist "1"
global allage_full_vallist "1"

global predict_years "2020"
global start_years "2011 2015"

global raw_data_path "../raw"
global output_data_path "../data"
cap mkdir "../temp"

program main
    import_pop
    import_nyt_covid_deaths
    import_cdc_covid_deaths
    import_cdc_wonder_deaths
    import_cdc_excess_deaths
    combine_natl_state_deaths
    import_agegrp_deaths
    foreach predict_year in ${predict_years} {
        generate_overall_predictions, predict_year(`predict_year')
        foreach samp in allage statefip agegrpcdc {
            generate_predictions, samp(`samp') predict_year(`predict_year')
            combine_excess_estimates, samp(`samp') predict_year(`predict_year')
        }
    }
end

program import_pop
    import excel "${raw_data_path}/census_monthly_pop_estimates_2019_vintage_ManuallyCleaned.xlsx", sheet("NA-01") firstrow clear
    rename (Year Month ResidentPopulation) (year month population)
    keep year month population
    duplicates drop
    save  "../temp/monthly_population_census.dta", replace

    import excel "${raw_data_path}/census_annual_pop_estimates_state_2019_ManuallyCleaned.xlsx", firstrow sheet("NST01") clear
    rename (D E F G H I J K L M) (Pop2010 Pop2011 Pop2012 Pop2013 Pop2014 Pop2015 Pop2016 Pop2017 Pop2018 Pop2019)
    drop Census Est*
    rename GeographicArea state
    replace state = substr(state, 2, .)
    reshape long Pop, i(state) j(year)
    rename Pop population
    save "../temp/annual_state_population_census.dta", replace

    import delimited "${raw_data_path}/nc-est2019-agesex-res.csv", clear
    drop census2010pop estimates*
    keep if sex == 0
    drop if age == 999
    reshape long popestimate, i(age) j(year)
    rename popestimate population
    gen agegrpcdc = .
    replace agegrpcdc = 0 if age >= 0 & age <= 24
    replace agegrpcdc = 25 if age >= 25 & age <= 44
    replace agegrpcdc = 45 if age >= 45 & age <= 64
    replace agegrpcdc = 65 if age >= 65 & age <= 74
    replace agegrpcdc = 75 if age >= 75 & age <= 84
    replace agegrpcdc = 85 if age >= 85 & age <= 100
    collapse (sum) population, by(year agegrpcdc)
    save "../temp/annual_agegrpcdc_population_census.dta", replace
end

program import_nyt_covid_deaths
    import delimited "${raw_data_path}/us-states.txt", clear
    rename fips statefip
    gen year = substr(date, 1, 4)
    gen month = substr(date, 6, 2)
    gen day = substr(date, 9, 2)
    destring year, force replace
    destring month, force replace
    destring day, force replace
    * June data incomplete at time of upload
    keep if month < 6

    * Deaths cumulative, keep last recorded day per month to get deaths by end of month
    bys state month: egen max_day = max(day)
    keep if day == max_day
    sort state year month
    drop if (state == "Puerto Rico" | state == "Guam" | state == "Northern Mariana Islands" | state == "Virgin Islands")

    gen monthly_covid_deaths = .
    replace monthly_covid_deaths = deaths[_n] - deaths[_n-1] if state[_n] == state[_n-1]
    replace monthly_covid_deaths = deaths if state[_n] != state[_n-1]
    keep state statefip year month monthly_covid_deaths
    save "../temp/nyt_covid_deaths.dta", replace
end

program import_cdc_covid_deaths
    import delimited "${raw_data_path}/Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2019-2020.csv", clear
    keep jurisdictionofoccurrence mmwryear mmwrweek weekendingdate covid19u071mu
    rename (jurisdictionofoccurrence mmwryear mmwrweek weekendingdate covid19u071mu) ///
        (state year weeknum weekendingdate covid_deaths_cdc)
    drop if (state == "United States" | state == "Puerto Rico")

    * New York City included separately from rest of New York state
    replace state = "New York" if state == "New York City"

    collapse (sum) covid_deaths_cdc, by(state year weeknum weekendingdate)
    gen weekdate = date(weekendingdate, "MDY")
    gen month= month(weekdate)
    gen day = day(weekdate)
    gen weekdate_begin = weekdate - 6

    gen fraction_in_month = 1
    forvalues i = 1/6 {
        replace fraction_in_month = `i'/7 if day == `i'
    }
    keep state year weeknum month covid_deaths_cdc fraction_in_month
    gen covid_deaths_month = fraction_in_month*covid_deaths_cdc
    gen covid_deaths_prevmonth = (1-fraction_in_month)*covid_deaths_cdc

    collapse (sum) covid_deaths_month covid_deaths_prevmonth, by(state year month)
    sort state year month
    gen add_deaths_month = covid_deaths_prevmonth[_n+1]
    drop covid_deaths_prevmonth
    gen covid_deaths_cdc = covid_deaths_month + add_deaths_month
    drop covid_deaths_month add_deaths_month
    keep state year month covid_deaths_cdc
    add_fips_codes, state_var(statefip)
    save "../temp/cdc_covid_deaths.dta", replace
end

program import_cdc_wonder_deaths
    import delimited "${raw_data_path}/Multiple_Cause_of_Death_2011-2018.txt", clear
    drop if notes == "Total"
    keep state statecode monthcode deaths
    drop if deaths == .
    gen year = substr(monthcode, 1, 4)
    destring year, force replace
    gen month = substr(monthcode, 6, 2)
    destring month, force replace
    drop monthcode
    rename statecode statefip
    rename deaths allcause_impute0
    gen allcause_impute1 = allcause_impute0
    save "../temp/cdc_wonder_deaths.dta", replace

    import delimited "${raw_data_path}/Multiple_Cause_of_Death_Age_2011-2018.txt", clear
    drop if notes == "Total"
    keep singleyearagescode monthcode deaths
    destring singleyearagescode, force replace
    rename singleyearagescode age
    drop if age == .
    gen year = substr(monthcode, 1, 4)
    gen month = substr(monthcode, 6, 2)
    destring month, force replace
    destring year, force replace
    drop monthcode
    rename deaths allcause
    gen agegrpcdc = .
    replace agegrpcdc = 0 if age >= 0 & age <= 24
    replace agegrpcdc = 25 if age >= 25 & age <= 44
    replace agegrpcdc = 45 if age >= 45 & age <= 64
    replace agegrpcdc = 65 if age >= 65 & age <= 74
    replace agegrpcdc = 75 if age >= 75 & age <= 84
    replace agegrpcdc = 85 if age >= 85 & age <= 100
    collapse (sum) allcause, by(year month agegrpcdc)
    save "../temp/cdc_wonder_agegrpcdc_deaths.dta", replace
end

program import_cdc_excess_deaths
    * Currently do not use these - suppresses if less than 9 in a month
    import delimited "${raw_data_path}/Excess_Deaths_Associated_with_COVID-19.csv", clear
    keep *weekendingdate observednumber state year outcome type
    keep if outcome == "All causes"
    drop outcome
    drop if (state == "United States" | state == "Puerto Rico")
    replace state = "New York" if state == "New York City"
    rename *weekendingdate week_ending
    gen imputed = 1
    replace imputed = 0 if (type == "Unweighted")
    drop type

    gen month = substr(week_ending, 6, 2)
    gen day = substr(week_ending, 9, 2)
    destring month, force replace
    destring day, force replace
    gen fraction_in_month = 1
    forvalues i = 1/6 {
        replace fraction_in_month = `i'/7 if day == `i'
    }
    gen deaths_month = fraction_in_month*observednumber
    gen deaths_prevmonth = (1-fraction_in_month)*observednumber
    collapse (sum) deaths*, by(state imputed month year)
    add_fips_codes, state_var(statefip)
    sort imputed state year month
    gen add_deaths_month = deaths_prevmonth[_n+1] if imputed[_n+1] == imputed[_n]
    drop deaths_prevmonth
    gen observednumber = add_deaths_month + deaths_month

    foreach val in 0 1 {
        preserve
        keep if imputed == `val'
        rename observednumber allcause_impute`val'
        keep state statefip year month allcause_impute`val'
        keep if year >= 2018
        save "../temp/excessfile_impute`val'.dta", replace
        restore
    }

    use "../temp/excessfile_impute0.dta", clear
    merge 1:1 state year month using "../temp/excessfile_impute1.dta", assert(3) keep(3) nogen
    save "../temp/cdc_excess_deaths.dta", replace
end

program combine_natl_state_deaths
    use "../temp/cdc_excess_deaths.dta", clear
    keep if year >= 2019
    append using "../temp/cdc_wonder_deaths.dta"
    drop if (year == 2020 & month >= 5)
    merge 1:m state month year using "../temp/nyt_covid_deaths.dta", assert(1 2 3) keep(1 3) nogen
    replace monthly_covid_deaths = 0 if monthly_covid_deaths == .

    preserve
    merge m:1 state year using "../temp/annual_state_population_census.dta", assert(1 2 3) keep(1 3) nogen
    save "../temp/monthly_statefip_death_counts_cdc.dta", replace

    restore
    collapse (sum) allcause* monthly_covid_deaths, by(year month)
    merge 1:1 year month using "../temp/monthly_population_census.dta", assert(1 2 3) keep(3) nogen
    save  "../temp/monthly_allcause_death_counts_cdc.dta", replace
end

program import_agegrp_deaths
     import delimited "${raw_data_path}/Weekly_counts_of_deaths_by_jurisdiction_and_age_group.csv", clear
     keep jurisdiction year week weekendingdate numberofdeaths agegroup
     rename (jurisdiction week numberofdeaths agegroup) (state weeknum allcause agegrpcdc)
     keep if state == "United States"

     collapse (sum) allcause, by(year weeknum weekendingdate agegrpcdc)
     gen weekdate = date(weekendingdate, "MDY")
     gen month= month(weekdate)
     gen day = day(weekdate)
     gen weekdate_begin = weekdate - 6

     gen fraction_in_month = 1
     forvalues i = 1/6 {
         replace fraction_in_month = `i'/7 if day == `i'
     }
     keep agegrpcdc year weeknum month allcause fraction_in_month
     gen allcause_month = fraction_in_month*allcause
     gen allcause_prevmonth = (1-fraction_in_month)*allcause
     collapse (sum) allcause_month allcause_prevmonth, by(year month agegrpcdc)
     sort agegrpcdc year month
     gen add_deaths_month = allcause_prevmonth[_n+1]
     drop allcause_prevmonth
     gen allcause = allcause_month + add_deaths_month
     drop allcause_month add_deaths_month

     gen agegroup_temp = .
     replace agegroup_temp = 0 if agegrpcdc == "Under 25 years"
     replace agegroup_temp = 25 if agegrpcdc == "25-44 years"
     replace agegroup_temp = 45 if agegrpcdc == "45-64 years"
     replace agegroup_temp = 65 if agegrpcdc == "65-74 years"
     replace agegroup_temp = 75 if agegrpcdc == "75-84 years"
     replace agegroup_temp = 85 if agegrpcdc == "85 years and older"
     drop agegrpcdc
     rename agegroup_temp agegrpcdc

     keep if year >= 2019
     append using "../temp/cdc_wonder_agegrpcdc_deaths.dta"
     drop if (year == 2020 & month >= 5)
     merge m:1 agegrpcdc year using "../temp/annual_agegrpcdc_population_census.dta", assert(1 2 3) keep(1 3) nogen
     save "../temp/monthly_agegrpcdc_death_counts_cdc.dta", replace

     keep if agegrpcdc >= 25
     collapse (sum) allcause population, by(year month)
     gen allage = 1
     * All for ages 25+, ages in age groups
     save "../temp/monthly_allage_death_counts_cdc.dta", replace
end

program generate_overall_predictions
    syntax, predict_year(int)
    foreach var in mortality mortality0 allcause {
        foreach series_start in ${start_years} {
            use  "../temp/monthly_allcause_death_counts_cdc.dta", clear
            tsset year month
            tsfill, full
            egen yearmonth = group(year month)

            cap rename allcause_impute1 allcause
            gen mortality = 10000*allcause/population
            gen mortality_impute0 = 10000*allcause_impute0/population
            gen mortality0 = mortality_impute0
            gen covid_mortality = 10000*monthly_covid_deaths/population
            drop if mortality_impute0 == .
            gen all = 1

            keep month year `var' mortality_impute0 all population covid_mortality
            rename population `var'_population
            reg `var' i.month year if (year < `predict_year' & year >= `series_start'), robust cluster(year)
            glo df = e(df_r)
            glo conf = 0.05
            predict `var'_pred_trend, xb
            predict `var'_sd_trend, stdp
            gen `var'_moe_trend = invttail(${df},${conf}/2)*`var'_sd_trend

            reg `var' i.month if (year < `predict_year' & year >= `series_start'), robust cluster(year)
            glo df = e(df_r)
            glo conf = 0.05
            predict `var'_pred_avg, xb
            predict `var'_sd_avg, stdp
            gen `var'_moe_avg = invttail(${df}, ${conf}/2)*`var'_sd_avg

            foreach method in avg trend {
                gen `var'_pred_low_`method' = `var'_pred_`method' - `var'_moe_`method'
                gen `var'_pred_high_`method' = `var'_pred_`method' + `var'_moe_`method'
                gen `var'_excess_`method' = `var' - `var'_pred_`method'
                gen `var'_excess_low_`method' = `var'_excess_`method' - `var'_moe_`method'
                gen `var'_excess_high_`method' = `var'_excess_`method' + `var'_moe_`method'

                * Use delta method to calculate SE on percent change
                gen `var'_pct_excess_moe_`method' = 100*(`var'/(`var'_pred_`method'^2))*`var'_moe_`method'
                gen `var'_pct_excess_`method' = 100*(`var'-`var'_pred_`method')/`var'_pred_`method'
                gen `var'_pct_excess_low_`method' = `var'_pct_excess_`method' - `var'_pct_excess_moe_`method'
                gen `var'_pct_excess_high_`method' = `var'_pct_excess_`method' + `var'_pct_excess_moe_`method'
            }
            save "${output_data_path}/`var'_predictions`predict_year'_start`series_start'_all.dta", replace
        }
    }
end

program generate_predictions
    syntax, samp(str) predict_year(int)
    use "../temp/monthly_`samp'_death_counts_cdc.dta", clear
    levelsof `samp', local(levels)
    local val_list `r(levels)'
    if "`samp'" == "statefip" {
        local variables "mortality0 mortality allcause"
    }
    if ("`samp'" == "agegrpcdc" | "`samp'" == "allage") {
        local variables "mortality allcause"
    }
    foreach var in `variables' {
        foreach series_start in ${start_years} {
            foreach val in `val_list' {
                preserve
                keep if `samp' == `val'
                cap rename allcause_impute1 allcause
                replace allcause=. if year==2020 & month>4

                * Impute for 2020 when unknown in Census
                reg population year if year < 2020, cluster(year)
                predict Pop_pred if year == 2020, xb
                replace population = Pop_pred if year == 2020
                drop Pop_pred

                gen mortality = 10000*allcause/population
                if "`samp'" == "statefip" {
                    gen mortality_impute0 = 10000*allcause_impute0/population
                    gen mortality0 = mortality_impute0
                    gen covid_mortality = 10000*monthly_covid_deaths/population
                    keep month year `var' `samp' population mortality_impute0 covid_mortality
                }
                else {
                    keep month year `var' `samp' population
                }
                drop if `var' == .
                rename population `var'_population
                reg `var' i.month year if (year < `predict_year' & year >= `series_start'), robust cluster(year)
                glo df = e(df_r)
                glo conf = 0.05
                predict `var'_pred_trend, xb
                predict `var'_sd_trend, stdp
                gen `var'_moe_trend = invttail(${df},${conf}/2)*`var'_sd_trend

                reg `var' i.month if (year < `predict_year' & year >= `series_start'), robust cluster(year)
                glo df = e(df_r)
                glo conf = 0.05
                predict `var'_pred_avg, xb
                predict `var'_sd_avg, stdp
                gen `var'_moe_avg = invttail(${df}, ${conf}/2)*`var'_sd_avg

                foreach method in avg trend {
                    gen `var'_pred_low_`method' = `var'_pred_`method' - `var'_moe_`method'
                    gen `var'_pred_high_`method' = `var'_pred_`method' + `var'_moe_`method'
                    gen `var'_excess_`method' = `var' - `var'_pred_`method'
                    gen `var'_excess_low_`method' = `var'_excess_`method' - `var'_moe_`method'
                    gen `var'_excess_high_`method' = `var'_excess_`method' + `var'_moe_`method'

                    * Use delta method to calculate SE on percent change
                    gen `var'_pct_excess_moe_`method' = 100*(`var'/(`var'_pred_`method'^2))*`var'_moe_`method'
                    gen `var'_pct_excess_`method' = 100*(`var'-`var'_pred_`method')/`var'_pred_`method'
                    gen `var'_pct_excess_low_`method' = `var'_pct_excess_`method' - `var'_pct_excess_moe_`method'
                    gen `var'_pct_excess_high_`method' = `var'_pct_excess_`method' + `var'_pct_excess_moe_`method'
                }
                save "../temp/`var'_predictions`predict_year'_start`series_start'_`samp'`val'.dta", replace
                restore
            }
        }
    }
end

program combine_excess_estimates
    syntax, samp(str) predict_year(str)
    if ("`samp'" == "all" | "`samp'" == "statefip") {
        local variables "mortality mortality0 allcause"
    }
    if ("`samp'" == "agegrpcdc" | "`samp'" == "allage") {
        local variables "mortality allcause"
    }
    foreach series_start in ${start_years} {
        foreach var in `variables' {
            clear
            foreach val in ${`samp'_full_vallist} {
                append using "../temp/`var'_predictions`predict_year'_start`series_start'_`samp'`val'.dta"
            }
            save "${output_data_path}/`var'_predictions`predict_year'_start`series_start'_`samp'.dta", replace
        }
    }
end

program add_fips_codes
    syntax, state_var(str)
    gen `state_var' = .
    replace `state_var' = 1 if state == "Alabama"
    replace `state_var' = 2 if state == "Alaska"
    replace `state_var' = 4 if state == "Arizona"
    replace `state_var' = 5 if state == "Arkansas"
    replace `state_var' = 6 if state == "California"
    replace `state_var' = 8 if state == "Colorado"
    replace `state_var' = 9 if state == "Connecticut"
    replace `state_var' = 10 if state == "Delaware"
    replace `state_var' = 12 if state == "Florida"
    replace `state_var' = 13 if state == "Georgia"
    replace `state_var' = 15 if state == "Hawaii"
    replace `state_var' = 16 if state == "Idaho"
    replace `state_var' = 17 if state == "Illinois"
    replace `state_var' = 18 if state == "Indiana"
    replace `state_var' = 19 if state == "Iowa"
    replace `state_var' = 20 if state == "Kansas"
    replace `state_var' = 21 if state == "Kentucky"
    replace `state_var' = 22 if state == "Louisiana"
    replace `state_var' = 23 if state == "Maine"
    replace `state_var' = 24 if state == "Maryland"
    replace `state_var' = 25 if state == "Massachusetts"
    replace `state_var' = 26 if state == "Michigan"
    replace `state_var' = 27 if state == "Minnesota"
    replace `state_var' = 28 if state == "Mississippi"
    replace `state_var' = 29 if state == "Missouri"
    replace `state_var' = 30 if state == "Montana"
    replace `state_var' = 31 if state == "Nebraska"
    replace `state_var' = 32 if state == "Nevada"
    replace `state_var' = 33 if state == "New Hampshire"
    replace `state_var' = 34 if state == "New Jersey"
    replace `state_var' = 35 if state == "New Mexico"
    replace `state_var' = 36 if state == "New York"
    replace `state_var' = 37 if state == "North Carolina"
    replace `state_var' = 38 if state == "North Dakota"
    replace `state_var' = 39 if state == "Ohio"
    replace `state_var' = 40 if state == "Oklahoma"
    replace `state_var' = 41 if state == "Oregon"
    replace `state_var' = 42 if state == "Pennsylvania"
    replace `state_var' = 44 if state == "Rhode Island"
    replace `state_var' = 45 if state == "South Carolina"
    replace `state_var' = 46 if state == "South Dakota"
    replace `state_var' = 47 if state == "Tennessee"
    replace `state_var' = 48 if state == "Texas"
    replace `state_var' = 49 if state == "Utah"
    replace `state_var' = 50 if state == "Vermont"
    replace `state_var' = 51 if state == "Virginia"
    replace `state_var' = 53 if state == "Washington"
    replace `state_var' = 54 if state == "West Virginia"
    replace `state_var' = 55 if state == "Wisconsin"
    replace `state_var' = 56 if state == "Wyoming"
    replace `state_var' = 11 if state == "District of Columbia"
end

* EXECUTE
main
