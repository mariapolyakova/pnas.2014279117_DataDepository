version 12
set more off

global raw_data_path "../raw"
global output_data_path "../data"
cap mkdir "../temp"
cap mkdir $raw_data_path
cap mkdir $output_data_path

program main
    import_cdc_wonder_deaths
    process_cdc_excess
    cdc_deaths_65
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
    rename deaths deaths_age1_impute1
    gen deaths_age1_impute0 = deaths_age1_impute1
    save "../temp/cdc_wonder_deaths.dta", replace
end

program process_cdc_excess
    import delimited "${raw_data_path}/Excess_Deaths_Associated_with_COVID-19.csv", clear
    keep *weekendingdate observednumber state averageexpectedcount year outcome type excesslowerestimate excesshigherestimate
    keep if outcome == "All causes"
    drop outcome
    drop if (state == "United States" | state == "Puerto Rico")
    replace state = "New York" if state == "New York City"
    rename *weekendingdate week_ending
    rename averageexpectedcount expected_deaths
    gen imputed = 1
    replace imputed = 0 if (type == "Unweighted")

    gen excess_difference = (observednumber - expected_deaths)
    gen month = substr(week_ending, 6, 2)
    gen day = substr(week_ending, 9, 2)
    destring day, force replace
    destring month, force replace

    gen fraction_in_month = 1
    forvalues i = 1/6 {
        replace fraction_in_month = `i'/7 if day == `i'
    }
    gen expected_month = fraction_in_month*expected_deaths
    gen expected_prevmonth = (1-fraction_in_month)*expected_deaths
    gen observed_month = fraction_in_month*observednumber
    gen observed_prevmonth = (1-fraction_in_month)*observednumber

    collapse (sum) expected_month expected_prevmonth observed_month observed_prevmonth, by(state imputed month year)
    add_fips_codes, state_var(statefip)
    sort state imputed year month
    gen add_observed_cdc_month = observed_prevmonth[_n+1] if (state[_n+1] == state[_n] & imputed[_n+1] == imputed[_n])
    gen add_expected_cdc_month = expected_prevmonth[_n+1] if (state[_n+1] == state[_n] & imputed[_n+1] == imputed[_n])
    drop *_prevmonth
    gen observed_cdc_month = add_observed_cdc_month + observed_month
    gen expected_cdc_month = add_expected_cdc_month + expected_month
    gen excess_cdc_month = observed_cdc_month - expected_cdc_month
    keep state statefip year month excess_cdc_month expected_cdc_month imputed observed*

    preserve
    keep if imputed == 1
    keep if year == 2020 & month <= 4
    drop imputed observed*
    save "${output_data_path}/cdc_aggregate_excess_deaths2020.dta", replace
    restore

    keep state year month imputed observed_cdc_month
    rename observed_cdc_month deaths_age1_impute
    reshape wide deaths_age1_impute, i(state year month) j(imputed)
    add_fips_codes, state_var(statefip)
    keep if year >= 2019
    append using "../temp/cdc_wonder_deaths.dta"
    sort state year month
    keep if (year < 2020 | (year == 2020 & month <= 4))
    save "${output_data_path}/cdc_deaths_age1.dta", replace
end

program cdc_deaths_65
    import delimited "${raw_data_path}/Weekly_counts_of_deaths_by_jurisdiction_and_age_group.csv", clear
    keep jurisdiction year week weekendingdate numberofdeaths agegroup type
    keep if type == "Predicted (weighted)"
    rename (jurisdiction week numberofdeaths agegroup) (state weeknum allcause agegrpcdc)
    keep if (agegrpcdc == "65-74 years" | agegrpcdc == "75-84 years" | agegrpcdc == "85 years and older")
    drop agegrpcdc
    replace state = "New York" if state == "New York City" // New York City included separately
    collapse (sum) allcause, by(state year weeknum weekendingdate)
    drop if (state == "United States" | state == "Puerto Rico")
    drop year
    gen weekdate = date(weekendingdate, "MDY")
    gen month= month(weekdate)
    gen day = day(weekdate)
    gen year = year(weekdate)
    drop weekdate
    gen fraction_in_month = 1
    forvalues i = 1/6 {
        replace fraction_in_month = `i'/7 if day == `i'
    }
    keep state year weeknum month allcause fraction_in_month
    gen allcause_month = fraction_in_month*allcause
    gen allcause_prevmonth = (1-fraction_in_month)*allcause
    collapse (sum) allcause_month allcause_prevmonth, by(year month state)
    sort state year month
    gen add_deaths_month = allcause_prevmonth[_n+1] if state[_n+1] == state[_n]
    drop allcause_prevmonth
    gen deaths_age65_impute1 = allcause_month + add_deaths_month
    add_fips_codes, state_var(statefip)
    keep state statefip year month deaths
    sort state year month
    label var deaths_age65_impute1 "CDC deaths ages 65 and older"
    save "${output_data_path}/cdc_deaths_age65.dta", replace
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
