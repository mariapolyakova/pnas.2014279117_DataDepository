**** INITIALIZE DIRECTORIES ***********************
    global external_data_path "../data"
    global temp_data_path "../temp"
    cap mkdir $temp_data_path
    global output_figures_path "../output/figures"
    cap mkdir $output_figures_path
    global output_tables_path "../output/tables"
    cap mkdir $external_data_path
****************************************************

version 12
set more off

program main
    import_oi_data
    compare_state_unemployment
end

program import_oi_data
    import delimited "${external_data_path}/oi_economic_data/OI_Tracker_Variables_April15.csv"
    keep state changespend* changeemprate*
    rename (changespend_april15_2020 changeemprate_april15_2020) (pct_changespend_oi pct_changeemp_oi)
    save "${temp_data_path}/oi_economic_data.dta", replace
end

program compare_state_unemployment
    use "${external_data_path}/excess_outcomes/unemp_rate_predictions2020_start2011_statefip.dta", clear
    keep year month statefip unemp_rate unemp_rate_excess_trend
    drop if year == 2020 & month > 4
    merge 1:1 month year statefip using "${external_data_path}/excess_outcomes/emp_rate_predictions2020_start2011_statefip.dta", assert(2 3) keep(3) nogen
    merge 1:1 month year statefip using "${external_data_path}/ui_predictions/iur_predicted_excess2020_statefip.dta", assert(2 3) keep(3) nogen
    keep if (year == 2020 & month == 4)
    label_states
    merge 1:1 state using "${temp_data_path}/oi_economic_data.dta", assert(3) keep(3) nogen

    replace emp_rate_excess_trend = -1*emp_rate_excess_trend
    replace pct_changespend_oi = -1*pct_changespend_oi
    replace pct_changeemp_oi = -1*pct_changeemp_oi
    foreach var in iur_excess_pred iu_per_excess_pred unemp_rate_excess_trend emp_rate_excess_trend pct_changespend_oi pct_changeemp_oi {
        sum `var'
        local st_dev = r(sd)
        local mean = r(mean)
        gen `var'_z = (`var'-`mean')/`st_dev'
    }

    local var1 "emp_rate_excess_trend"
    local var2 "unemp_rate_excess_trend"
    local var3 "iur_excess_pred"
    local var4 "iu_per_excess_pred"
    local var5 "pct_changespend_oi"
    local var6 "pct_changeemp_oi"

    forvalues i = 1/5 {
        local i_1 = `i' + 1
        forvalues j = `i_1'/6 {
            corr `var`i'' `var`j''
            local corr`i'`j' = r(rho)
        }
    }

    matrix cps_corr_matrix = (., `corr12', `corr13', `corr14', `corr15', `corr16') \ ///
                         (., ., `corr23', `corr24', `corr25', `corr26') \ ///
                         (., ., ., `corr34', `corr35', `corr36') \ ///
                         (., ., ., ., `corr45', `corr46') \ ///
                         (., ., ., ., ., `corr56')

    matrix_to_txt, saving(${output_tables_path}/cps_corr_matrix.txt) ///
        mat(cps_corr_matrix) format(%10.3f) title(<tab:cps_corr_matrix>) replace
end

program label_states
    gen label = 0
    gen statefip_code = ""
    replace label = 1 if statefip == 34
    replace statefip_code = "NJ" if statefip == 34
    replace label = 1 if statefip == 26
    replace statefip_code = "MI" if statefip == 26
    replace label = 1 if statefip == 36
    replace statefip_code = "NY" if statefip == 36
    replace label = 1 if statefip == 15
    replace statefip_code = "HI" if statefip == 15
    replace label = 1 if statefip == 32
    replace statefip_code = "NV" if statefip == 32
    replace label = 1 if statefip == 56
    replace statefip_code = "WY" if statefip == 56
    replace label = 1 if statefip == 22
    replace statefip_code = "LA" if statefip == 22
    replace label = 1 if statefip == 11
    replace statefip_code = "DC" if statefip == 11
    replace label = 1 if statefip == 17
    replace statefip_code = "IL" if statefip == 17
    replace label = 1 if statefip == 6
    replace statefip_code = "CA" if statefip == 6
    replace label = 1 if statefip == 25
    replace statefip_code = "MA" if statefip == 25
    replace label = 1 if statefip == 37
    replace statefip_code = "NC (incomplete)" if statefip == 37
end

* EXECUTE
main
