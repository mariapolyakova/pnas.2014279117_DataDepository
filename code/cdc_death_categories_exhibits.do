**** INITIALIZE DIRECTORIES ***********************
    global external_data_path "../data"
    global temp_data_path "../temp"
    cap mkdir $temp_data_path
    global output_figures_path "../output/figures"
    cap mkdir $output_figures_path
    global output_tables_path "../output/tables"
    cap mkdir $external_data_path

****************************************************

version 16
set more off

global allcause_label "All-Cause"
global malignant_label "Cancer"
global diabetes_label "Diabetes"
global alzheimer_label "Alzheimer's"
global influenza_label "Influenza/Pneumonia"
global influenza_covid_label "Flu/COVID/Pneumonia"
global chronic_resp_label "Lower Resp."
global heart_label "Heart Diseases"
global cerebrovascular_label "Cerebrovascular"
global unnatural_label "Unnatural Causes"

global excess_label "Mortality (per 10,000)"
global excess_deaths_label "Deaths"

program main
    gen_statefip_labels
    national_cause_comparison
    economic_damage_comparison
    summary_table
end

program gen_statefip_labels
    foreach var in statefip {
        global `var'1_label "AL"
        global `var'2_label "AK"
        global `var'4_label "AZ"
        global `var'5_label "AR"
        global `var'6_label "CA"
        global `var'8_label "CO"
        global `var'9_label "CT"
        global `var'10_label "DE"
        global `var'11_label "DC"
        global `var'12_label "FL"
        global `var'13_label "GA"
        global `var'15_label "HI"
        global `var'16_label "ID"
        global `var'17_label "IL"
        global `var'18_label "IN"
        global `var'19_label "IA"
        global `var'20_label "KS"
        global `var'21_label "KY"
        global `var'22_label "LA"
        global `var'23_label "ME"
        global `var'24_label "MD"
        global `var'25_label "MA"
        global `var'26_label "MI"
        global `var'27_label "MN"
        global `var'28_label "MS"
        global `var'29_label "MO"
        global `var'30_label "MT"
        global `var'31_label "NE"
        global `var'32_label "NV"
        global `var'33_label "NH"
        global `var'34_label "NJ"
        global `var'35_label "NM"
        global `var'36_label "NY"
        global `var'37_label "NC"
        global `var'38_label "ND"
        global `var'39_label "OH"
        global `var'40_label "OK"
        global `var'41_label "OR"
        global `var'42_label "PA"
        global `var'44_label "RI"
        global `var'45_label "SC"
        global `var'46_label "SD"
        global `var'47_label "TN"
        global `var'48_label "TX"
        global `var'49_label "UT"
        global `var'50_label "VT"
        global `var'51_label "VA"
        global `var'53_label "WA"
        global `var'54_label "WV"
        global `var'55_label "WI"
        global `var'56_label "WY"
    }
end

program national_cause_comparison
    * April predicted vs. actual by group
    foreach cause in allcause malignant diabetes alzheimer influenza chronic_resp heart cerebrovascular unnatural {
        use "${external_data_path}/cdc_category_excess/`cause'_predictions2020_start2011_national.dta", clear
        sum `cause'_mort if month == 4
        local max = r(max)
        local min = r(min)
        local graph_min_temp = 0.99*`min'
        local graph_min_temp = max(0, `graph_min_temp')
        local graph_max_temp = `max'
        local units = 0.05
        global y_min = `units'*floor(`graph_min_temp'/`units')
        global y_max = `units'*floor(`graph_max_temp'/`units')+`units'
        global y_step = max(`units',`units'*floor((`graph_max_temp'-`graph_min_temp')/(5*`units')))

        sum `cause'_mort if (year == 2020 & month == 4)
        local apr_label_pos = r(mean)
        sum `cause'_mort_pred_trend if (year == 2020 & month ==4)
        local pred_label_pos = r(mean)
        if (`apr_label_pos' - `pred_label_pos' > 0 & `apr_label_pos' - `pred_label_pos' < 0.01) {
            local apr_label_pos = `apr_label_pos' + 0.005
        }
        if (`apr_label_pos' - `pred_label_pos' < 0 & `apr_label_pos' - `pred_label_pos' > -0.01) {
            local apr_label_pos = `apr_label_pos' - 0.005
        }

        twoway (connected `cause'_mort year if month == 4 & year >= 2011, lcolor("193 5 52") mcolor("193 5 52") msize(small) lpattern(solid)) ///
            (connected `cause'_mort_pred_trend year if month == 4 & year >= 2011, lcolor("61 126 186") mcolor("61 126 186") msize(small) lpattern(dash)), ///
            scheme(s1mono) plotregion(style(none)) xtitle("Year") ytitle("") ylabel(${y_min}(${y_step})${y_max}, angle(0)) legend(off) ///
            text(`apr_label_pos' 2020.25 "April", place(e) color("193 5 52")) ///
            text(`pred_label_pos' 2020.25 "April Trend", place(e) color("61 126 186")) ///
            xsc(range(2011 2021.5)) xlabel(2011(1)2020) ///
            yscale(range(${y_min} ${y_max})) subtitle("${`cause'_label} Mortality per 10,000", size(medium) color(black) position(11))
        graph export "${output_figures_path}/`cause'_national_mort_series_april_line.pdf", replace

        sum `cause'_mort if month <= 4
        local max = r(max)
        local min = r(min)
        local graph_min_temp = 0.99*`min'
        local graph_min_temp = max(0, `graph_min_temp')
        local graph_max_temp = `max'
        local units = 0.05
        global y_min = `units'*floor(`graph_min_temp'/`units')
        global y_max = `units'*floor(`graph_max_temp'/`units')+`units'
        global y_step = max(`units',`units'*floor((`graph_max_temp'-`graph_min_temp')/(5*`units')))

        gen month_l = month - 0.3
        keep if year == 2020 & month <= 4
        twoway (bar `cause'_mort_pred_trend month_l, barw(0.25) bcolor("193 5 52") blcolor(black)) ///
            (bar `cause'_mort month, barw(0.25) bcolor("61 126 186") blcolor(black)) ///
            (rcap `cause'_mort_pred_low `cause'_mort_pred_high month_l, lcolor(black)), scheme(s1mono) ///
            ytitle("") ylabel(${y_min}(${y_step})${y_max}, angle(0)) yscale(range(${y_min} ${y_max})) ///
            xtitle("")  xlabel(0.85 "January" 1.85 "February" 2.85 "March" 3.85 "April") ///
            legend(label(1 "Predicted (Trend since 2011)") label(2 "Observed") label(3 "95% CI") size(small) rows(1)) ///
            subtitle("${`cause'_label} Mortality 2020", position(11) justification(left) size(medium)) plotregion(style(none))
       graph export "${output_figures_path}/`cause'_pred_bars2020.pdf", replace
    }

    * Comparison April 2020 across categories
    use "${external_data_path}/cdc_category_excess/allcause_predictions2020_start2011_national.dta", clear
    keep if (year == 2020 & month == 4)
    gen cause = "allcause"
    keep year month cause *_mort *_pred_trend *_pred_high *_pred_low *_excess *_excess_low *_excess_high allcause_pop
    rename (allcause_mort allcause_mort_pred_trend allcause_mort_pred_high allcause_mort_pred_low allcause_mort_excess allcause_mort_excess_low allcause_mort_excess_high) ///
        (mortality pred_trend pred_high pred_low excess excess_low excess_high)
    global label_temp1 "${allcause_label}"
    local i = 2
    foreach cause in malignant diabetes alzheimer influenza chronic_resp heart cerebrovascular unnatural {
        append using "${external_data_path}/cdc_category_excess/`cause'_predictions2020_start2011_national.dta", ///
            keep(year month `cause'_mort `cause'_mort_pred_trend `cause'_mort_pred_high `cause'_mort_pred_low `cause'_mort_excess `cause'_mort_excess_low `cause'_mort_excess_high)
        keep if (year == 2020 & month == 4)
        replace cause = "`cause'" if cause == ""
        replace mortality = `cause'_mort if mortality == .
        drop `cause'_mort
        replace pred_trend = `cause'_mort_pred_trend if pred_trend == .
        drop `cause'_mort_pred_trend
        replace pred_high = `cause'_mort_pred_high if pred_high == .
        drop `cause'_mort_pred_high
        replace pred_low = `cause'_mort_pred_low if pred_low == .
        drop `cause'_mort_pred_low
        replace excess = `cause'_mort_excess if excess == .
        drop `cause'_mort_excess
        replace excess_low = `cause'_mort_excess_low if excess_low == .
        drop `cause'_mort_excess_low
        replace excess_high = `cause'_mort_excess_high if excess_high == .
        drop `cause'_mort_excess_high
        global label_temp`i' "${`cause'_label}"
        local i = `i' + 1
    }
    gen pos_original = _n
    gen order = -1*mortality if cause != "unlisted"
    sort order
    drop order
    gen pos = _n
    gen pos_l = _n - 0.3
    forvalues i = 1/9 {
        sum pos_original if _n == `i'
        local index = r(mean)
        global label`i' "${label_temp`index'}"
    }

    * Graph predicted vs. expected mortality by category
    twoway (bar pred_trend pos_l if pos >= 2, barw(0.25) bcolor("61 126 186") blcolor(black)) ///
        (bar mortality pos if pos >= 2, barw(0.25) bcolor("193 5 52") blcolor(black)) ///
        (rcap pred_low pred_high pos_l if pos >= 2, lcolor(black)), scheme(s1mono) ///
        ytitle("") ylabel(, angle(0)) xtitle("") ///
        xsc(r(1.5 9)) xlabel(1.85 "${label2}" 2.85 "${label3}" 3.85 "${label4}" 4.85 "${label5}" 5.85 "${label6}" 6.85 "${label7}" 7.85 "${label8}" 8.85 "${label9}", notick angle(35) labsize(vsmall)) ///
        legend(label(1 "Predicted (Trend Since 2011)") label(2 "Observed") label(3 "95% C.I.") size(small) rows(1) pos(12)) ///
        subtitle("National Mortality (per 10,000) April 2020 by Non-COVID Cause", position(11) justification(left) size(medium)) plotregion(style(none)) ///
        graphregion(margin(4 4 16 4))
    graph export "${output_figures_path}/predicted_expected_national_mort_category_april2020.pdf", replace

    egen population = max(allcause_pop)
    drop allcause_pop
    gen excess_deaths = excess*population/10000
    gen excess_deaths_low = excess_low*population/10000
    gen excess_deaths_high = excess_high*population/10000

    * Graph excess deaths by category
    foreach var in excess excess_deaths {
        twoway (bar `var' pos if pos >= 2, bcolor("61 126 186") blcolor(black)) ///
            (rcap `var'_low `var'_high pos if pos >= 2, lcolor(black)), scheme(s1mono) ytitle("") ///
            ylabel(, angle(0)) xtitle("") ///
            xlabel(1.85 "${label2}" 2.85 "${label3}" 3.85 "${label4}" 4.85 "${label5}" 5.85 "${label6}" 6.85 "${label7}" 7.85 "${label8}" 8.85 "${label9}", notick angle(35) labsize(vsmall)) ///
            legend(label(1 "Excess ${`var'_label} (Trend Since 2011)") label(2 "95% C.I.") size(small) pos(12)) ///
            subtitle("Non-COVID Excess ${`var'_label} April 2020 by Cause", position(11) justification(left) size(medium)) plotregion(style(none)) ///
            graphregion(margin(4 4 16 4))
       graph export "${output_figures_path}/`var'_national_category_april2020.pdf", replace
    }
end

program economic_damage_comparison
    foreach var in malignant diabetes alzheimer influenza chronic_resp heart cerebrovascular unnatural {
        use "${external_data_path}/excess_outcomes/mortality_predictions2020_start2011_statefip.dta", clear
        keep year month statefip state mortality_excess_trend covid_mortality mortality_pred_trend mortality_excess_low_trend mortality_excess_high_trend mortality_impute0 mortality
        merge 1:1 state year month using "${external_data_path}/excess_outcomes/emp_rate_predictions2020_start2011_statefip.dta", assert(2 3) keepusing(emp_rate_excess_trend) nogen
        merge 1:1 statefip year month using "${external_data_path}/cdc_category_excess/`var'_predictions2020_start2011_statefip.dta", nogen
        replace emp_rate_excess_trend = -1*emp_rate_excess_trend
        gen incomplete_data = (mortality_impute0/mortality)*100 < 90
        keep if `var'_mort_pred_trend != .

        label_states
        keep if year == 2020 & month == 4
        count if incomplete_data == 0
        local state_count_complete = r(N)

        * Scatter against economic damage with slope
        reg `var'_mort_excess emp_rate_excess_trend if incomplete_data == 0, r
        local slope = _b[emp_rate_excess_trend]
        local se = _se[emp_rate_excess_trend]
        twoway (scatter `var'_mort_excess emp_rate_excess_trend if incomplete_data == 0 & label == 0, mcolor(gray) msize(small)) ///
            (scatter `var'_mort_excess emp_rate_excess_trend if incomplete_data == 0 & label == 1, mlabcolor(black) mlabsize(small) mlabposition(8) mlabel(statefip_code) mcolor(blue) msize(small) msymbol(o)) ///
            (lfit `var'_mort_excess emp_rate_excess_trend if incomplete_data == 0, lcolor(red)), ///
            scheme(s1mono) xtitle("Excess Decline in Employment-Population Ratio") ytitle("") ylabel(, angle(0)) ///
            subtitle("${`var'_label} Death Excess Mortality (per 10,000)", size(medium) position(11)) ///
            note("Note: Sample of `state_count_complete' states with > 90% of est. deaths recorded and sufficient mortality data") ///
            legend(on order(- "Slope = `: di %6.4f `slope''" ///
            "            (`: di %6.4f `se'')") ///
            pos(2) ring(0) region(lp(solid)))
        graph export "${output_figures_path}/`var'_mort_excess_economic_april2020.pdf", replace

       * Dotplot by state
        drop if incomplete == 1
        local high_var "`var'_mort_excess_high"
        local low_var "`var'_mort_excess_low"
        sort `var'_mort_excess
        gen row = _n
        count if (year == 2020 & month == 4)
        local num_states = r(N)
        global numlist ""
        forvalues i = 1/`num_states' {
            global numlist "$numlist `i'"
        }
        local label_lines $numlist
        gen graph_label = ""
        forvalues i = 1/`num_states' {
            sum statefip if row == `i'
            local statefip = r(mean)
            replace graph_label = "${statefip`statefip'_label}" if row == `i'
        }
        forvalues i = 1/`num_states' {
            levelsof graph_label if row == `i'
            label define y_labels `i' `r(levels)', add
        }
        label values row y_labels
        gen significant_negative = (`high_var' < 0)
        count if (significant_negative == 1)
        local significant_negative = r(N)
        gen significant_positive = (`low_var' > 0)
        count if (significant_positive == 1)
        local significant_positive = r(N)

        twoway (dot `var'_mort_excess row if incomplete == 0 & significant_negative == 0 & significant_positive == 0, horizontal msymbol(circle) msize(small) ///
            dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)`num_states')) ///
            (dot `var'_mort_excess row if incomplete == 0 & significant_negative == 1, horizontal msymbol(circle) msize(small) mcolor(green) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)`num_states')) ///
            (dot `var'_mort_excess row if incomplete == 0 & significant_positive == 1, horizontal msymbol(circle) msize(small) mcolor(red) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)`num_states')) ///
            (rcap `low_var' `high_var' row, horizontal lpattern(solid) lwidth(thin) lcolor(gs6)) ///
            , scheme(s1mono) xline(0, lwidth(thin) lpattern(dash)) ytitle("") ///
            ylabel(1(1)`num_states', valuelabel angle(0) labsize(small) nogrid) ///
            yline(`label_lines', lwidth(thin) lcolor(gs14)) xtitle("") ///
            legend(pos(6) size(vsmall) symxsize(small) region(lstyle(solid)) cols(2) ///
            order(1 "Excess ${`var'_label} Mortality" 2 "Significant Negative" 3 "Significant Positive" 4 "95% Confidence Interval")) ///
            ysize(15) xsize(8) ///
            note("Note: `significant_negative' states significantly negative and `significant_positive' significantly positive (out of `num_states')", size(vsmall)) ///
            subtitle("Excess ${`var'_label} Mortality: April 2020", position(11) justification(left) size(small))
        graph export "${output_figures_path}/`var'_excess_mort_dotplot_april2020.pdf", replace
        drop row graph_label significant_negative
        label drop _all
    }
end

program summary_table
    use year month mortality_excess_trend using "${external_data_path}/excess_outcomes/mortality_predictions2020_start2011_all.dta", clear
    keep if (year == 2020 & month == 4)
    sum mortality_excess_trend
    local total_excess = r(mean)

    foreach cause in unnatural influenza malignant heart chronic_resp diabetes cerebrovascular alzheimer {
        use year month `cause'_mort_excess_high `cause'_mort_excess_low `cause'_mort_excess `cause'_mort ///
            `cause'_mort_pred_high `cause'_mort_pred_low `cause'_mort_pred_trend ///
            using "${external_data_path}/cdc_category_excess/`cause'_predictions2020_start2011_national.dta", clear
        keep if (year == 2020 & month == 4)
        foreach var in `cause'_mort `cause'_mort_pred_trend `cause'_mort_pred_low `cause'_mort_pred_high ///
            `cause'_mort_excess `cause'_mort_excess_low `cause'_mort_excess_high {
            sum `var'
            local mean = r(mean)
            matrix `cause'_row = nullmat(`cause'_row), `mean'
        }
        local pct_excess = 100*`mean'/`total_excess'
        matrix `cause'_row = nullmat(`cause'_row), `pct_excess'
    }

    foreach cause in unnatural influenza malignant heart chronic_resp diabetes cerebrovascular alzheimer {
        use "${external_data_path}/excess_outcomes/mortality_predictions2020_start2011_statefip.dta", clear
        keep year month statefip state mortality_excess_trend covid_mortality mortality_pred_trend mortality_excess_low_trend mortality_excess_high_trend mortality_impute0 mortality
        merge 1:1 statefip year month using "${external_data_path}/cdc_category_excess/`cause'_predictions2020_start2011_statefip.dta", keepusing(`cause'_mort_excess `cause'_mort) nogen
        merge 1:1 statefip year month using "${external_data_path}/excess_outcomes/emp_rate_predictions2020_start2011_statefip.dta", assert(1 2 3) keepusing(emp_rate_excess_trend) nogen
        gen incomplete_data = (mortality_impute0/mortality)*100 < 90
        drop if incomplete_data == 1
        keep if (year == 2020 & month == 4)
        keep if `cause'_mort_excess != .
        replace emp_rate_excess_trend = -1*emp_rate_excess_trend

        reg `cause'_mort_excess emp_rate_excess_trend, r
        local slope = _b[emp_rate_excess_trend]
        local se = _se[emp_rate_excess_trend]
        local ci_low = `slope' - 1.96*`se'
        local ci_high = `slope' + 1.96*`se'

        count if incomplete_data == 0
        local state_count = r(N)

        matrix `cause'_row = nullmat(`cause'_row), (`slope', `ci_low', `ci_high', `state_count')
    }

    foreach cause in unnatural influenza malignant heart chronic_resp diabetes cerebrovascular alzheimer {
        matrix noncovid_excess = nullmat(noncovid_excess) \ `cause'_row
    }
    matrix_to_txt, saving(${output_tables_path}/noncovid_excess.txt) ///
        mat(noncovid_excess) format(%10.3f)  title(<tab:noncovid_excess>) replace
end

program label_states
    gen label = 0
    local samp "statefip"
    gen `samp'_code = ""
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
    replace statefip_code = "NC" if statefip == 37
    replace label = 1 if statefip == 2
    replace statefip_code = "AK" if statefip == 2
end

* EXECUTE
main
