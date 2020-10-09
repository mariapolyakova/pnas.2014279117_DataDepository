version 13
set more off

global unemp_rate_label "Unemployment Rate"
global emp_rate_label "Employment-Population Ratio"
global emp_rate2_label "Restricted Employment-Population Ratio"
global working_rate_label "Percent of Population Working"
global partic_rate_label "Participation Rate"
global avg_hours_label "Average Hours Worked"
global unemp_level_label "Unemployed Pop. (Thousands)"
global emp_label "Employed Pop. (Thousands)"
global labor_force_label "Labor Force Pop. (Thousands)"

global all_full_vallist "1"
global male_full_vallist "0 1"
global race_full_vallist "1 2 3 4 5 6 7"
global statefip_full_vallist "1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56"
global agegrp_full_vallist "16 25 35 45 55 65 75"
global agegrpcdc_full_vallist "0 25 45 65 75 85"
global agegrpbroad_full_vallist "16 25 65"
global allage_full_vallist "1"

global month1_label "January"
global month2_label "February"
global month3_label "March"
global month4_label "April"

global start_year = 2011
global end_year = 2020

global predict_years "2020"
global start_years "2011 2015"

global input_data_path "../data"
global raw_data_path "../raw"

program main
    import_aggregates_all
    foreach samp in all allage agegrp agegrpbroad agegrpcdc statefip race male {
        create_overall_time_series, samp(`samp')
        foreach predict_year in ${predict_years} {
            create_overall_prediction, samp(`samp') predict_year(`predict_year')
            combine_excess_estimates, samp(`samp') predict_year(`predict_year')
        }
    }
end

program import_aggregates_all
    import_aggregates, import_file(LaborForce_Adj) var(labor_force_adj)
    import_aggregates, import_file(LaborForce_Unadj) var(labor_force_unadj)
    import_aggregates, import_file(Unemployment_Rate_Adj) var(unemp_rate_adj)
    import_aggregates, import_file(Unemployment_Rate_Unadj) var(unemp_rate_unadj)
    import_aggregates, import_file(Unemployment_Level_Adj) var(unemp_level_adj)
    import_aggregates, import_file(Unemployment_Level_Unadj) var(unemp_level_unadj)
    import_aggregates, import_file(Emp_Adj) var(emp_adj)
    import_aggregates, import_file(Emp_Unadj) var(emp_unadj)
    import_aggregates, import_file(Population_Unadj) var(pop_unadj)
    import_aggregates, import_file(EmpRatio_Adj) var(emp_rate_adj)
    import_aggregates, import_file(EmpRatio_Unadj) var(emp_rate_unadj)
    import_aggregates, import_file(ParticRate_Adj) var(partic_rate_adj)
    import_aggregates, import_file(ParticRate_Unadj) var(partic_rate_unadj)
end

program import_aggregates
    syntax, import_file(str) var(str)
    import excel ${raw_data_path}/`import_file'.xlsx, cellrange(A12:M28) firstrow clear
    rename Jan `var'1
    rename Feb `var'2
    rename Mar `var'3
    rename Apr `var'4
    rename May `var'5
    rename Jun `var'6
    rename Jul `var'7
    rename Aug `var'8
    rename Sep `var'9
    rename Oct `var'10
    rename Nov `var'11
    rename Dec `var'12
    drop if Year == .
    reshape long `var', i(Year) j(Month)
    gen year_month = ym(Year, Month)
    format year_month %tm
    sort year_month
    save "../temp/`var'_bls_aggregate.dta", replace
end

program create_overall_time_series
    syntax, samp(str)
    use $input_data_path/monthly_cps_2005_2020.dta, clear
    gen all = 1
    gen allage = 1 if agegrpcdc >= 25
    collapse (sum) *_wgt, by(year_month year month `samp')
    if "`samp'" == "all" {
        foreach var in unemp_rate_unadj unemp_rate_adj emp_rate_unadj emp_rate_adj partic_rate_unadj partic_rate_adj ///
            labor_force_adj labor_force_unadj unemp_level_adj unemp_level_unadj emp_adj emp_unadj {
            merge 1:1 year_month using "../temp/`var'_bls_aggregate.dta", assert(1 2 3) keep(1 2 3) nogen
        }
    }
    gen_rate_measures
    keep if (year >= ${start_year} & year <= ${end_year})

    * Compare emp-pop ratios at state level in April 2020
    if "`samp'" == "statefip" {
        gen label = 0
        gen statefip_code = ""
        replace label = 1 if statefip == 26
        replace label = 1 if statefip == 15
        replace label = 1 if statefip == 32
        replace label = 1 if statefip == 34
        replace label = 1 if statefip == 36
        replace statefip_code = "MI" if statefip == 26
        replace statefip_code = "HI" if statefip == 15
        replace statefip_code = "NV" if statefip == 32
        replace statefip_code = "NJ" if statefip == 34
        replace statefip_code = "NY" if statefip == 36
	    drop label statefip_code
    }

    * Plot overall time series for full sample
    if "`samp'" == "all" {
        tsset year_month
        tsfill, full
        gen emp_pop_diff = emp_rate - emp_rate2
        rename (unemployed_wgt employed_wgt laborforce_wgt) (unemp_level emp labor_force)
    }
    save "../temp/time_series_combined_`samp'.dta", replace
end

program create_overall_prediction
    syntax, samp(str) predict_year(int)
    use "../temp/time_series_combined_`samp'.dta", clear
    levelsof `samp', local(levels)
    local val_list `r(levels)'
    local variables "unemp_rate emp_rate emp_rate2 avg_hours employment"
    cap rename emp employment
    cap rename employed_wgt employment
    replace employment = employment*1000
    foreach var in `variables'{
        foreach series_start in ${start_years} {
            foreach val in `val_list' {
                preserve
                keep month year `var' `samp' total_wgt
                keep if `samp' == `val'
                rename total_wgt `var'_population
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
    foreach series_start in ${start_years} {
        foreach var in unemp_rate emp_rate emp_rate2 avg_hours employment {
            clear
            foreach val in ${`samp'_full_vallist} {
                append using "../temp/`var'_predictions`predict_year'_start`series_start'_`samp'`val'.dta"
            }
            save "${input_data_path}/`var'_predictions`predict_year'_start`series_start'_`samp'.dta", replace
        }
    }
end

program gen_rate_measures
    foreach var in unemployed_wgt emp_positive_wgt laborforce_wgt employed_wgt total_wgt working_wgt {
        replace `var' = `var'/1000
    }
    gen unemp_rate = 100*unemployed_wgt/laborforce_wgt
    gen emp_rate = 100*employed_wgt/total_wgt
    gen emp_rate2 = 100*emp_positive_wgt/total_wgt
    gen working_rate = 100*working_wgt/total_wgt
    gen partic_rate = 100*laborforce_wgt/total_wgt
    gen avg_hours = hours_wgt/(1000*total_wgt)
end

* EXECUTE
main
