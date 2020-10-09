version 12
set more off

global statefip_full_vallist "1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56"
global causes "allcause natural septicemia malignant diabetes alzheimer influenza chronic_resp resp_other nephritis heart cerebrovascular"

global raw_data_path "../raw"
global output_data_path "../data"
cap mkdir "../temp"
cap mkdir $output_data_path

program main
    import_pop
    import_wonder_files
    import_national_nchs_files
    import_state_nchs_files
    generate_national_predictions
    foreach var in allcause unnatural alzheimer malignant heart cerebrovascular influenza diabetes chronic_resp {
        generate_state_predictions, var(`var')
    }
    combine_excess_estimates
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
    add_fips_codes, state_var(statefip)
    save "../temp/annual_state_population_census.dta", replace
end

program import_wonder_files
    foreach file in Multiple_Cause_of Alzheimers Cancer Cerebrovascular Diabetes External_Cause ///
        Heart_Diseases Influenza_Pneumonia Lower_Respiratory {
        import delimited "${raw_data_path}/`file'_Death_2011-2018.txt", clear
        keep state statecode monthcode deaths
        rename statecode statefip
        gen year = substr(monthcode, 1, 4)
        gen month = substr(monthcode, 6, 2)
        drop monthcode
        destring year, force replace
        destring month, force replace
        drop if (deaths == . | year == .)
        rename deaths deaths_cdc
        save "../temp/`file'_deaths_cleaned_2011-2018.dta", replace
    }
end

program import_national_nchs_files
    foreach start_year in 2014 2019 {
        if "`start_year'" == "2014" {
            local end_year = 2018
        }
        if "`start_year'" == "2019" {
            local end_year = 2020
        }
        import delimited "${raw_data_path}/Weekly_Counts_of_Deaths_by_State_and_Select_Causes__`start_year'-`end_year'.csv", clear
        keep if jurisdiction == "United States"
        drop flag*
        rename (mmwryear mmwrweek naturalcause septicemia malignant diabetes alzheimer influenza chronic other nephritis diseasesof cerebrovascular) ///
            (year weeknum natural septicemia malignant diabetes alzheimer influenza chronic_resp resp_other nephritis heart cerebrovascular)
        if "`start_year'" == "2014" {
            gen influenza_covid = influenza
        }
        if "`start_year'" == "2019" {
            gen influenza_covid = influenza + covid19u071un
        }
        collapse (sum) ${causes} influenza_covid, by(year weeknum weekendingdate)
        drop year

        if "`start_year'" == "2014" {
            gen weekdate = date(weekendingdate, "MDY")
            gen month= month(weekdate)
            gen day = day(weekdate)
            gen year = year(weekdate)
        }
        if "`start_year'" == "2019" {
            gen month = ""
            replace month = substr(weekendingdate, 1, 1) if substr(weekendingdate, 2, 1) == "/"
            replace month = substr(weekendingdate, 1, 2) if substr(weekendingdate, 2, 1) != "/"
            destring month, force replace

            gen day = ""
            replace day = substr(weekendingdate, 3, 1) if (month < 10 & substr(weekendingdate, 4, 1) == "/")
            replace day = substr(weekendingdate, 4, 1) if (month >= 10 & substr(weekendingdate, 5, 1) == "/")
            replace day = substr(weekendingdate, 3, 2) if (month < 10 & substr(weekendingdate, 4, 1) != "/")
            replace day = substr(weekendingdate, 4, 2) if (month >= 10 & substr(weekendingdate, 5, 1) != "/")
            destring day, force replace

            gen year = ""
            replace year = substr(weekendingdate, 5, 4) if (month < 10 & day < 10)
            replace year = substr(weekendingdate, 6, 4) if (month < 10 & day >= 10)
            replace year = substr(weekendingdate, 6, 4) if (month >= 10 & day < 10)
            replace year = substr(weekendingdate, 7, 4) if (month >= 10 & day >= 10)
            destring year, force replace
        }
        gen fraction_in_month = 1
        forvalues i = 1/6 {
            replace fraction_in_month = `i'/7 if day == `i'
        }
        keep year weeknum month ${causes} influenza_covid fraction_in_month
        foreach var in ${causes} influenza_covid {
            gen `var'_month = fraction_in_month*`var'
            gen `var'_prevmonth = (1-fraction_in_month)*`var'
        }
        save  "../temp/weekly_death_counts_natl_`start_year'-`end_year'.dta", replace
    }

    use "../temp/weekly_death_counts_natl_2014-2018.dta", clear
    append using "../temp/weekly_death_counts_natl_2019-2020.dta"
    collapse (sum) *_month *_prevmonth, by(year month)
    sort year month
    foreach var in ${causes} influenza_covid {
        gen add_`var'_month = `var'_prevmonth[_n+1]
    }
    drop *_prevmonth
    foreach var in ${causes} influenza_covid {
        gen `var' = `var'_month + add_`var'_month
    }
    drop *_month
    keep year month ${causes} influenza_covid
    gen unnatural = allcause - natural
    gen unlisted = allcause - septicemia - malignant - diabetes - alzheimer - chronic_resp - resp_other - nephritis - heart - cerebrovascular - influenza_covid
    label var influenza "Influenza, pneumonia, or COVID"
    drop if year == 2020 & month >= 5
    save "../temp/national_category_deaths_nchs_2014_2020.dta", replace
end

program import_state_nchs_files
    foreach start_year in 2014 2019 {
        if "`start_year'" == "2014" {
            local end_year = 2018
        }
        if "`start_year'" == "2019" {
            local end_year = 2020
        }
        import delimited "${raw_data_path}/Weekly_Counts_of_Deaths_by_State_and_Select_Causes__`start_year'-`end_year'.csv", clear
        if "`start_year'" == "2014" {
            keep jurisdictionofoccurrence mmwryear mmwrweek weekendingdate allcause naturalcause ///
                septicemia malignant diabetes alzheimer influenza chronic other nephritis diseasesof cerebrovascular
            rename (jurisdictionofoccurrence mmwryear mmwrweek weekendingdate allcause naturalcause septicemia malignant diabetes alzheimer influenza chronic other nephritis diseasesof cerebrovascular) ///
                (state year weeknum weekendingdate allcause natural septicemia malignant diabetes alzheimer influenza chronic_resp resp_other nephritis heart cerebrovascular)
            foreach var in septicemia malignant diabetes alzheimer influenza chronic_resp resp_other nephritis heart cerebrovascular {
                gen `var'_small_flag = (`var' == . | `var' == 0)
            }
            gen influenza_covid = influenza
        }
        if "`start_year'" == "2019" {
        keep jurisdictionofoccurrence mmwryear mmwrweek weekendingdate allcause naturalcause ///
            septicemia malignant diabetes alzheimer influenza chronic other nephritis diseasesof cerebrovascular covid19u071un
            rename (jurisdictionofoccurrence mmwryear mmwrweek weekendingdate allcause naturalcause septicemia malignant diabetes alzheimer influenza chronic other nephritis diseasesof cerebrovascular covid) ///
                (state year weeknum weekendingdate allcause natural septicemia malignant diabetes alzheimer influenza chronic_resp resp_other nephritis heart cerebrovascular covid)
            foreach var in septicemia malignant diabetes alzheimer influenza chronic_resp resp_other nephritis heart cerebrovascular {
                gen `var'_small_flag = (`var' == . | `var' == 0)
            }
            gen influenza_covid = influenza + covid
            drop covid
        }
        drop if (state == "United States" | state == "Puerto Rico")

        * New York City included separately from rest of New York state
        replace state = "New York" if state == "New York City"

        collapse (sum) ${causes} influenza_covid (max) *_small_flag, by(state year weeknum weekendingdate)
        drop year
        if "`start_year'" == "2014" {
            gen weekdate = date(weekendingdate, "MDY")
            gen month= month(weekdate)
            gen day = day(weekdate)
            gen year = year(weekdate)
        }
        if "`start_year'" == "2019" {
            gen month = ""
            replace month = substr(weekendingdate, 1, 1) if substr(weekendingdate, 2, 1) == "/"
            replace month = substr(weekendingdate, 1, 2) if substr(weekendingdate, 2, 1) != "/"
            destring month, force replace

            gen day = ""
            replace day = substr(weekendingdate, 3, 1) if (month < 10 & substr(weekendingdate, 4, 1) == "/")
            replace day = substr(weekendingdate, 4, 1) if (month >= 10 & substr(weekendingdate, 5, 1) == "/")
            replace day = substr(weekendingdate, 3, 2) if (month < 10 & substr(weekendingdate, 4, 1) != "/")
            replace day = substr(weekendingdate, 4, 2) if (month >= 10 & substr(weekendingdate, 5, 1) != "/")
            destring day, force replace

            gen year = ""
            replace year = substr(weekendingdate, 5, 4) if (month < 10 & day < 10)
            replace year = substr(weekendingdate, 6, 4) if (month < 10 & day >= 10)
            replace year = substr(weekendingdate, 6, 4) if (month >= 10 & day < 10)
            replace year = substr(weekendingdate, 7, 4) if (month >= 10 & day >= 10)
            destring year, force replace
        }

        gen fraction_in_month = 1
        forvalues i = 1/6 {
            replace fraction_in_month = `i'/7 if day == `i'
        }
        keep state year weeknum month ${causes} influenza_covid fraction_in_month *_small_flag
        foreach var in allcause natural septicemia malignant diabetes alzheimer influenza chronic_resp ///
            resp_other nephritis heart cerebrovascular influenza_covid {
            gen `var'_month = fraction_in_month*`var'
            gen `var'_prevmonth = (1-fraction_in_month)*`var'
        }
        save  "../temp/weekly_death_counts_`start_year'-`end_year'.dta", replace
     }

     use "../temp/weekly_death_counts_2014-2018.dta", clear
     append using "../temp/weekly_death_counts_2019-2020.dta"
     collapse (sum) *_month *_prevmonth (max) *_small_flag, by(state year month)
     sort state year month
     foreach var in ${causes} influenza_covid {
         gen add_`var'_month = `var'_prevmonth[_n+1]
     }
     drop *_prevmonth
     foreach var in ${causes} influenza_covid {
         gen `var' = `var'_month + add_`var'_month
     }
     drop *_month
     keep state year month influenza_covid ${causes} *_small_flag
     gen non_influenza = allcause - influenza
     gen unnatural = allcause - natural
     gen non_malignant = allcause - malignant

     label var influenza "Influenza, pneumonia, or COVID"
     drop if year == 2020 & month >= 5

     foreach var in septicemia malignant diabetes alzheimer influenza chronic_resp resp_other nephritis heart cerebrovascular {
         bys state: egen max_`var'_flag19_temp = max(`var'_small_flag) if (year == 2019 | year == 2020)
         bys state: egen max_`var'_flag19 = max(max_`var'_flag19_temp)
         replace `var' = . if max_`var'_flag19 == 1
     }
     replace non_influenza = . if max_influenza_flag19 == 1
     replace non_malignant = . if max_malignant_flag19 == 1
     replace influenza_covid = . if max_influenza_flag19 == 1
     drop *flag*
     add_fips_codes, state_var(statefip)
     save "../temp/state_category_deaths_nchs_2014_2020.dta", replace
end

program generate_national_predictions
    use "../temp/Multiple_Cause_of_deaths_cleaned_2011-2018.dta", clear
    rename deaths_cdc allcause_cdc
    merge 1:1 year month statefip using "../temp/Alzheimers_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc alzheimer_cdc
    merge 1:1 year month statefip using "../temp/Cancer_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc malignant_cdc
    merge 1:1 year month statefip using "../temp/Diabetes_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc diabetes_cdc
    merge 1:1 year month statefip using "../temp/External_Cause_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc unnatural_cdc
    merge 1:1 year month statefip using "../temp/Heart_Diseases_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc heart_cdc
    merge 1:1 year month statefip using "../temp/Influenza_Pneumonia_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc influenza_cdc
    merge 1:1 year month statefip using "../temp/Lower_Respiratory_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc chronic_resp_cdc
    merge 1:1 year month statefip using "../temp/Cerebrovascular_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    rename deaths_cdc cerebrovascular_cdc
    collapse (sum) *_cdc, by(year month)
    merge 1:1 year month using "../temp/national_category_deaths_nchs_2014_2020.dta", nogen
    foreach var in allcause unnatural alzheimer malignant heart cerebrovascular influenza diabetes chronic_resp {
        replace `var' = `var'_cdc if year <= 2018
    }
    merge 1:1 month year using "../temp/monthly_population_census.dta", assert(1 2 3) keep(1 3) nogen
    drop *_cdc
    drop if year == 2020 & month > 4
    foreach var in allcause unnatural alzheimer malignant heart cerebrovascular influenza diabetes chronic_resp {
        foreach series_start in 2011 {
            preserve
            gen `var'_mort = 10000*`var'/population
            keep month year `var'_mort population
            drop if `var'_mort == .
            rename population `var'_pop
            reg `var'_mort i.month year if (year < 2020 & year >= `series_start'), robust cluster(year)
            glo df = e(df_r)
            glo conf = 0.05
            predict `var'_mort_pred_trend, xb
            predict `var'_mort_sd_trend, stdp
            gen `var'_mort_moe_trend = invttail(${df},${conf}/2)*`var'_mort_sd_trend

            gen `var'_mort_pred_low = `var'_mort_pred_trend - `var'_mort_moe_trend
            gen `var'_mort_pred_high = `var'_mort_pred_trend + `var'_mort_moe_trend
            gen `var'_mort_excess = `var'_mort - `var'_mort_pred_trend
            gen `var'_mort_excess_low = `var'_mort_excess - `var'_mort_moe_trend
            gen `var'_mort_excess_high = `var'_mort_excess + `var'_mort_moe_trend

            save "${output_data_path}/`var'_predictions2020_start`series_start'_national.dta", replace
            restore
        }
    }
end

program generate_state_predictions
    syntax, var(str)
    use "../temp/state_category_deaths_nchs_2014_2020.dta", clear
    if "`var'" == "allcause" {
        merge 1:1 year month statefip using "../temp/Multiple_Cause_of_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "alzheimer" {
        merge 1:1 year month statefip using "../temp/Alzheimers_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "malignant" {
        merge 1:1 year month statefip using "../temp/Cancer_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "diabetes" {
        merge 1:1 year month statefip using "../temp/Diabetes_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "unnatural" {
        merge 1:1 year month statefip using "../temp/External_Cause_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "heart" {
        merge 1:1 year month statefip using "../temp/Heart_Diseases_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "influenza" {
        merge 1:1 year month statefip using "../temp/Influenza_Pneumonia_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "chronic_resp" {
        merge 1:1 year month statefip using "../temp/Lower_Respiratory_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    if "`var'" == "cerebrovascular" {
        merge 1:1 year month statefip using "../temp/Cerebrovascular_deaths_cleaned_2011-2018.dta", keepusing(deaths_cdc) nogen
    }
    rename deaths_cdc `var'_cdc
    gen drop_temp = (`var' == . & year >= 2019)
    bys statefip: egen drop = max(drop_temp)
    keep if drop == 0
    drop drop_temp drop
    replace `var' = `var'_cdc if year <= 2018
    merge m:1 statefip year using "../temp/annual_state_population_census.dta", assert(1 2 3) keep(1 3) nogen
    keep statefip month year population `var'
    drop if statefip == .
    levelsof statefip, local(levels)
    foreach series_start in 2011 {
        foreach val in `levels' {
            preserve
            keep if statefip == `val'
            drop if year==2020 & month>4

            * Impute for 2020 when unknown in Census
            reg population year if year < 2020, cluster(year)
            predict Pop_pred if year == 2020, xb
            replace population = Pop_pred if year == 2020
            drop Pop_pred

            gen `var'_mort = 10000*`var'/population

            keep month year `var'_mort statefip population
            drop if `var'_mort == .
            rename population `var'_mort_pop
            reg `var'_mort i.month year if (year < 2020 & year >= `series_start'), robust cluster(year)
            glo df = e(df_r)
            glo conf = 0.05
            predict `var'_mort_pred_trend, xb
            predict `var'_mort_sd_trend, stdp
            gen `var'_mort_moe_trend = invttail(${df},${conf}/2)*`var'_mort_sd_trend

            gen `var'_mort_pred_low = `var'_mort_pred_trend - `var'_mort_moe_trend
            gen `var'_mort_pred_high = `var'_mort_pred_trend + `var'_mort_moe_trend
            gen `var'_mort_excess = `var'_mort - `var'_mort_pred_trend
            gen `var'_mort_excess_low = `var'_mort_excess - `var'_mort_moe_trend
            gen `var'_mort_excess_high = `var'_mort_excess + `var'_mort_moe_trend
            save "../temp/`var'_mort_predictions2020_start`series_start'_statefip`val'.dta", replace
            restore
        }
    }
end

program combine_excess_estimates
    foreach series_start in 2011 {
        foreach var in allcause unnatural alzheimer malignant heart ///
            cerebrovascular influenza diabetes chronic_resp {
            clear
            foreach val in ${statefip_full_vallist} {
                cap append using "../temp/`var'_mort_predictions2020_start`series_start'_statefip`val'.dta"
            }
            sort statefip year month
            save "${output_data_path}/`var'_predictions2020_start`series_start'_statefip.dta", replace
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
