**** INITIALIZE DIRECTORIES ***********************

    global input_data_path "../data"
    global temp_data_path "../temp"
    cap mkdir $temp_data_path
    global output_figures_path "../output/figures"
    cap mkdir $output_figures_path
    global output_tables_path "../output/tables"
    cap mkdir $input_data_path

****************************************************

version 15
set more off
global variables "emp_rate mortality"

global unemp_rate_label "Unemployment Rate"
global emp_rate_label "Employment-Population Ratio"
global emp_rate2_label "Modified Emp-Pop Ratio"
global avg_hours_label "Average Hours Worked"
global mortality_label "Mortality (per 10,000)"

global all1_label "All"
global agegrpcdc0_label "< 25"
global agegrpcdc25_label "25-44"
global agegrpcdc45_label "45-64"
global agegrpcdc65_label "65-74"
global agegrpcdc75_label "75-84"
global agegrpcdc85_label "> 84"

global all_compare_vallist "1"
global agegrpcdc_compare_vallist "0 25 45 65 75 85"
global allage_compare_vallist "1"

global month1_label "January"
global month2_label "February"
global month3_label "March"
global month4_label "April"

* Based on NAICS industry (Industry codes don't line up)  - sample includes all employed individuals
global industry100_label "Forestry and fishing"
global industry200_label "Mining, quarrying, and oil and gas"
global industry300_label "Utilities"
global industry400_label "Construction"
global industry500_label "Manufacturing"
global industry600_label "Wholesale Trade"
global industry700_label "Retail Trade"
global industry800_label "Transportation and Warehousing"
global industry900_label "Information"
global industry1000_label "Finance and Insurance"
global industry1100_label "Real estate rental and leasing"
global industry1200_label "Professional, scientific, technical services"
global industry1300_label "Company management"
global industry1400_label "Administrative and support"
global industry1500_label "Educational services"
global industry1600_label "Health care and social assistance"
global industry1700_label "Arts, entertainment, and recreation"
global industry1800_label "Accommodation and food services"

global predict_start_years "2011"

program main
    initialize_dirs
    gen_statefip_labels
    foreach samp in all agegrpcdc {
        create_monthly_plots, samp(`samp')
    }
    foreach predict_year in 2020 {
        foreach predict_month in 4 {
            all_states_comparison, predict_year(`predict_year') predict_month(`predict_month')
        }
    }
    foreach predict_year in 2020 {
        foreach samp in all agegrpcdc {
            prediction_comparison_plot, samp(`samp') predict_year(`predict_year')
        }
        foreach predict_month in 4 {
            overall_heterogeneity_plot, predict_year(`predict_year') predict_month(`predict_month')
            foreach samp in statefip {
                compare_incidence_graph, samp(`samp') predict_year(`predict_year') predict_month(`predict_month')
            }
            foreach samp in agegrpcdc {
                compare_incidence_graph_age, samp(`samp') predict_year(`predict_year') predict_month(`predict_month')
            }
            deaths_emp_table, predict_year(`predict_year') predict_month(`predict_month')
            compare_incidence_tables, predict_year(`predict_year') predict_month(`predict_month')
            alternate_mortality_table, predict_year(`predict_year') predict_month(`predict_month')
            alternate_economic_table, predict_year(`predict_year') predict_month(`predict_month')
            alternate_specification_table, predict_year(`predict_year') predict_month(`predict_month')
        }
    }
end

program initialize_dirs
    foreach var in ${variables} {
        cap rmdir "${output_figures_path}/`var'_figs"
        cap mkdir "${output_figures_path}/`var'_figs"
    }
    cap rmdir "${output_figures_path}/compare_incidence_figs"
    cap mkdir "${output_figures_path}/compare_incidence_figs"
    cap rmdir "${output_figures_path}/main_figs"
    cap mkdir "${output_figures_path}/main_figs"
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

program create_monthly_plots
    syntax, samp(str)
    foreach var in ${variables} {
        use "${input_data_path}/`var'_predictions2020_start2011_`samp'.dta", clear
        keep if year >= 2011
        foreach val in ${`samp'_compare_vallist} {
            sum `var' if month == 4 & `samp' == `val'
            local max = r(max)
            local min = r(min)
            local graph_min_temp = 0.99*`min'
            local graph_min_temp = max(0, `graph_min_temp')
            local graph_max_temp = `max'
            if "`var'" == "mortality" & "`samp'" == "agegrpcdc" & ("`val'" == "0" | "`val'" == "25" | "`val'" == "45") {
                local units = 0.05
            }
            else {
                local units = 1
            }
            global y_min = `units'*floor(`graph_min_temp'/`units')
            global y_max = `units'*floor(`graph_max_temp'/`units')+`units'
            global y_step = max(`units',`units'*floor((`graph_max_temp'-`graph_min_temp')/(5*`units')))

            sum `var' if (year == 2020 & month == 4 & `samp' == `val')
            local apr_label_pos = r(mean)
            sum `var'_pred_trend if (year == 2020 & month == 4 & `samp' == `val')
            local pred_label_pos = r(mean)
            if "`samp'" == "all" {
                local saving_option "saving(`var'_series_april_`samp'`val'_line, replace)"
                if "`var'" == "emp_rate" {
                    local panel_label "(c)"
                }
                if "`var'" == "mortality" {
                    local panel_label "(a)"
                }
            }
            else {
                local saving_option ""
            }
            twoway (connected `var' year if month == 4 & `samp' == `val', lcolor("193 5 52") mcolor("193 5 52") msize(small) lpattern(solid)) ///
                (connected `var'_pred_trend year if month == 4 & `samp' == `val', lcolor("61 127 186") mcolor("61 127 186") msize(small) lpattern(dash)), ///
                scheme(s1mono) plotregion(style(none)) xtitle("Year") ytitle("") ylabel(${y_min}(${y_step})${y_max}, angle(0)) legend(off) ///
                text(`apr_label_pos' 2020.25 "April", place(e) color("193 5 52")) ///
                text(`pred_label_pos' 2020.25 "April Trend", place(e) color("61 127 186")) ///
                xsc(range(2011 2021.5)) xlabel(2011(1)2020) yscale(range(${y_min} ${y_max})) ///
                subtitle("`panel_label' ${`var'_label}: ${`samp'`val'_label}", size(large) color(black) position(11)) `saving_option'
            graph export "${output_figures_path}/`var'_figs/`var'_series_april_`samp'`val'_line.pdf", replace

            sum `var' if ((month == 2 | month == 3) & `samp' == `val')
            local max = r(max)
            local min = r(min)
            local graph_min_temp = 0.99*`min'
            local graph_min_temp = max(0, `graph_min_temp')
            local graph_max_temp = `max'
            if "`var'" == "mortality" & "`samp'" == "agegrpcdc" & ("`val'" == "0" | "`val'" == "25" | "`val'" == "45") {
                local units = 0.05
            }
            else {
                local units = 1
            }
            global y_min = `units'*floor(`graph_min_temp'/`units')
            global y_max = `units'*floor(`graph_max_temp'/`units')+`units'
            global y_step = max(`units',`units'*floor((`graph_max_temp'-`graph_min_temp')/(5*`units')))

            sum `var' if (year == 2020 & month == 2 & `samp' == `val')
            local feb_label_pos = r(mean)
            sum `var' if (year == 2020 & month == 3 & `samp' == `val')
            local mar_label_pos = r(mean)

            * Manually adjust labels to fit well on graph
            if "`var'" == "emp_rate" {
                local mar_label_pos = `mar_label_pos' - 0.1
            }
            local observed_col = 0.8
            local pred_col = 0.4
            twoway (connected `var' year if month == 2 & `samp' == `val', lcolor(red*`observed_col') mcolor(red*`observed_col') msize(medium) lpattern(solid)) ///
                (line `var'_pred_trend year if month == 2 & `samp' == `val', lcolor(red*`pred_col') mcolor(red*`pred_col') msize(medium) lpattern(dash)) ///
                (connected `var' year if month == 3 & `samp' == `val', lcolor(green*`observed_col') mcolor(green*`observed_col') msize(medium) lpattern(solid)) ///
                (line `var'_pred_trend year if month == 3 & `samp' == `val', lcolor(green*`pred_col') mcolor(green*`pred_col') msize(medium) lpattern(dash)), ///
                scheme(s1mono) plotregion(style(none)) xtitle("Year") ytitle("") ylabel(${y_min}(${y_step})${y_max}, angle(0)) legend(off) ///
                text(`feb_label_pos' 2020.25 "February", place(e) color(red*`observed_col')) ///
                text(`mar_label_pos' 2020.25 "March", place(e) color(green*`observed_col')) ///
                xsc(range(2011 2021.5)) xlabel(2011(1)2020) ///
                yscale(range(${y_min} ${y_max})) subtitle("${`var'_label}: ${`samp'`val'_label}", size(large) color(black) position(11))
            graph export "${output_figures_path}/`var'_figs/`var'_series_bymonth_`samp'`val'_line.pdf", replace
        }
    }
end

program prediction_comparison_plot
    syntax, samp(str) predict_year(int)
    foreach var in ${variables} {
        foreach series_start in ${predict_start_years} {
            use "${input_data_path}/`var'_predictions2020_start`series_start'_`samp'.dta", clear
            keep if year == `predict_year'
            foreach val in ${`samp'_compare_vallist} {
                preserve
                keep if `samp' == `val'
                sum month
                local max_month = r(max)
                keep if month <= `max_month'
                sum `var'
                local max_outcome = r(max)
                local min_outcome = r(min)
                sum `var'_pred_high_trend
                local max_prediction = r(max)
                sum `var'_pred_low_trend
                local min_prediction = r(min)
                local min_temp = 0.9*min(`min_outcome', `min_prediction')
                local min_temp = max(0, `min_temp')
                local max_temp = max(`max_outcome', `max_prediction')
                if "`var'" == "mortality" & "`samp'" == "agegrpcdc" & ("`val'" == "0" | "`val'" == "25" | "`val'" == "45") {
                    local units = 0.05
                }
                else {
                    local units = 1
                }
                global y_min = `units'*floor(`min_temp'/`units')
                global y_max = `units'*floor(`max_temp'/`units')+`units'
                global y_step = max(`units',`units'*floor((`max_temp'-`min_temp')/(5*`units')))
                gen month_l = month - 0.3
                if "`samp'" == "all" {
                    local saving_option "saving(`var'_comparison_`samp'`val'_year`predict_year'_start`series_start', replace)"
                    if "`var'" == "emp_rate" {
                        local panel_label "(d)"
                    }
                    if "`var'" == "mortality" {
                        local panel_label "(b)"
                    }
                }
                else {
                    local saving_option ""
                }
                twoway (bar `var'_pred_trend month_l, barw(0.3) bcolor("61 127 186") blcolor(black)) ///
                    (bar `var' month, barw(0.3) bcolor("193 5 52") blcolor(black)) ///
                    (rcap `var'_pred_low_trend `var'_pred_high_trend month_l, lcolor(black)), scheme(s1mono) ///
                    ytitle("") ylabel(${y_min}(${y_step})${y_max}, angle(0)) yscale(range(${y_min} ${y_max})) ///
                    xtitle("")  xlabel(0.85 "January" 1.85 "February" 2.85 "March" 3.85 "April") ///
                    legend(label(1 "Predicted (Trend since `series_start')") label(2 "Observed") label(3 "95% CI") size(small) rows(1)) ///
                    subtitle("`panel_label' ${`var'_label} `predict_year': ${`samp'`val'_label}", position(11) justification(left) size(large)) plotregion(style(none)) `saving_option'
               restore
            }
        }
    }

    if ("`samp'" == "all" & "`predict_year'" == "2020") {
        graph combine mortality_series_april_all1_line.gph ///
            mortality_comparison_all1_year2020_start2011.gph ///
            emp_rate_series_april_all1_line.gph ///
            emp_rate_comparison_all1_year2020_start2011.gph, ///
            col(2)  graphregion(color(white)) ysize(8) xsize(11) iscale(0.5)
        graph export "${output_figures_path}/main_figs/figure1.pdf", replace
        rm mortality_series_april_all1_line.gph
        rm mortality_comparison_all1_year2020_start2011.gph
        rm emp_rate_series_april_all1_line.gph
        rm emp_rate_comparison_all1_year2020_start2011.gph
    }
end

program overall_heterogeneity_plot
    syntax, predict_year(int) predict_month(int)
    foreach series_start in ${predict_start_years} {
        foreach var in ${variables} {
            clear
            foreach samp in all agegrpcdc {
                append using "${input_data_path}/`var'_predictions`predict_year'_start`series_start'_`samp'.dta", ///
                    keep(year month `var'* `var' `samp')
            }
            keep if (year == `predict_year' & month == `predict_month')
            gen pos = .

            drop if (all == 1 | agegrpcdc == 0)

            * Manually create order for plot
            replace pos = 1 if agegrpcdc == 25
            replace pos = 2 if agegrpcdc == 45
            replace pos = 3 if agegrpcdc == 65
            replace pos = 4 if agegrpcdc == 75
            replace pos = 5 if agegrpcdc == 85
            global label1 "${agegrpcdc25_label}"
            global label2 "${agegrpcdc45_label}"
            global label3 "${agegrpcdc65_label}"
            global label4 "${agegrpcdc75_label}"
            global label5 "${agegrpcdc85_label}"

            gen pos_l = pos - 0.4
            sum `var'
            local max_outcome = r(max)
            local min_outcome = r(min)
            sum `var'_pred_high_trend
            local max_prediction = r(max)
            sum `var'_pred_low_trend
            local min_prediction = r(min)
            local min_temp = 0.9*min(`min_outcome', `min_prediction')
            local min_temp = max(0, `min_temp')
            local max_temp = max(`max_outcome', `max_prediction')
            local units = 2
            global y_min = `units'*floor(`min_temp'/`units')
            global y_max = `units'*floor(`max_temp'/`units')+`units'
            global y_step = max(1,`units'*floor((`max_temp'-`min_temp')/(5*`units')))
            if "`var'" == "mortality" {
                local panel_label "(a)"
            }
            if "`var'" == "emp_rate" {
                local panel_label "(b)"
            }
            twoway (bar `var'_pred_trend pos_l, barw(0.4) bcolor("61 127 186") blcolor(black)) ///
                (bar `var' pos, barw(0.4) bcolor("193 5 52") blcolor(black)) ///
                (rcap `var'_pred_low_trend `var'_pred_high_trend pos_l, lcolor(black)), scheme(s1mono) ///
                ytitle("") ylabel(${y_min}(${y_step})${y_max}, angle(0)) yscale(range(${y_min} ${y_max})) ///
                xtitle("")  xlabel(0.8 "${label1}" 1.8 "${label2}" 2.8 "${label3}" 3.8 "${label4}" 4.8 "${label5}", notick angle(35) labsize(small)) ///
                legend(label(1 "Predicted (Trend since `series_start')") label(2 "Observed") label(3 "95% CI") size(small) rows(1)) ///
                subtitle("`panel_label' ${`var'_label} Heterogeneity: ${month`predict_month'_label} `predict_year'", position(11) justification(left) size(large)) plotregion(style(none)) ///
                saving(`var'_heterogeneity_year`predict_year'_month`predict_month'_start`series_start', replace)
        }

        graph combine mortality_heterogeneity_year`predict_year'_month`predict_month'_start`series_start'.gph ///
            emp_rate_heterogeneity_year`predict_year'_month`predict_month'_start`series_start'.gph, ///
            col(2)  graphregion(color(white)) ysize(4) xsize(11)
        graph export "${output_figures_path}/main_figs/figure4.pdf", replace
        rm mortality_heterogeneity_year`predict_year'_month`predict_month'_start`series_start'.gph
        rm emp_rate_heterogeneity_year`predict_year'_month`predict_month'_start`series_start'.gph
    }
end

program all_states_comparison
    syntax, predict_year(int) predict_month(int)
    foreach series_start in ${predict_start_years} {
        foreach var in ${variables} {
            clear
            use "${input_data_path}/`var'_predictions2020_start`series_start'_statefip.dta", clear
            keep year month `var'* `var' statefip
            drop *_avg
            if "`var'" == "mortality" {
                local compare_var "emp_rate"
            }
            if "`var'" == "emp_rate" {
                local compare_var "mortality"
            }
            merge 1:1 year month statefip using "${input_data_path}/`compare_var'_predictions2020_start`series_start'_statefip.dta", ///
                assert(1 2 3) keep(1 3) keepusing(`compare_var'_excess_trend) nogen
            keep if (year == `predict_year' & month == `predict_month')
            replace emp_rate_excess_trend = -1*emp_rate_excess_trend
            if ("`var'" == "avg_hours" | "`var'" == "emp_rate") {
                rename `var'_excess_low_trend `var'_excess_high_trend_temp
                rename `var'_excess_high_trend `var'_excess_low_trend
                rename `var'_excess_high_trend_temp `var'_excess_high_trend
                foreach measure in `var'_excess_low_trend `var'_excess_high_trend `var'_pct_excess_trend `var'_pct_excess_low_trend `var'_pct_excess_high_trend {
                    replace `measure' = -1*`measure'
                }
            }
            rename statefip statefips
            if ("`var'" == "avg_hours" | "`var'" == "emp_rate") {
                local title "Excess Decline in"
            }
            else {
                local title "Excess"
            }
            sum `var'_excess_trend
            local `var'_excess_max = r(max)
            local `var'_excess_min = r(min)
            local graph_max = 2*floor(``var'_excess_max'/2)

            if "`var'" == "mortality" {
                local graph_min = 2*ceil(``var'_excess_min'/2)
                local graph_min_alt1 = `graph_min' + 0.5
                local graph_max_alt1 = `graph_max' + 0.5
                local graph_min_alt2 = `graph_min' + 1
                local graph_max_alt2 = `graph_max' + 1
                local dotplot_label "Mortality (per 10,000)"
            }
            if "`var'" == "emp_rate" {
                local graph_min = 2*ceil(``var'_excess_min'/2) + 2
                local graph_min_alt1 = `graph_min' - 2
                local graph_max_alt1 = `graph_max' - 2
                local graph_min_alt2 = `graph_min' - 1
                local graph_max_alt2 = `graph_max' - 1
                local dotplot_label "Emp-Pop Ratio"
            }
            local graph_int = (`graph_max'-`graph_min')/4
            local graph_int_alt1 = (`graph_max_alt1'-`graph_min_alt1')/4
            local graph_int_alt2 = (`graph_max_alt2'-`graph_min_alt2')/4

            local max_int1 = `graph_min'
            local max_int2 = `graph_min' + `graph_int'
            local max_int3 = `graph_min' + 2*`graph_int'
            local max_int4 = `graph_min' + 3*`graph_int'
            local max_int5 = `graph_min' + 4*`graph_int'
            local max_int6 = ``var'_excess_max'

            if "`var'" == "mortality" {
                local panel_label "(a)"
                local title_size "small"
            }
            if "`var'" == "emp_rate" {
                local panel_label "(c)"
                local title_size "small"
            }

            * Map of excess
            maptile `var'_excess_trend, geo(state) geoid(statefips) cutvalues(`graph_min'(`graph_int')`graph_max') ///
                legd(1) twopt(title("`panel_label' `title' ${`var'_label}: ${month`predict_month'_label} `predict_year'", size(`title_size') ///
                justification(left)) legend(size(small) textwidth(vhuge)) saving(`var'_map_excess_year`predict_year'_month`predict_month'_start`series_start', replace))

            maptile `var'_excess_trend, geo(state) geoid(statefips) cutvalues(`graph_min'(`graph_int')`graph_max') ///
                legd(1) twopt(title("`title' ${`var'_label}: ${month`predict_month'_label} `predict_year'", size(large) ///
                justification(left)) legend(size(small)))
            graph export "${output_figures_path}/`var'_figs/`var'_map_excess_year`predict_year'_month`predict_month'_start`series_start'.pdf", replace

            * Alternate versions of map of excess
            maptile `var'_excess_trend, geo(state) geoid(statefips) cutvalues(`graph_min_alt1'(`graph_int_alt1')`graph_max_alt1') ///
                legd(1) twopt(title("`title' ${`var'_label}: ${month`predict_month'_label} `predict_year'", size(large) justification(left)) legend(size(small)))
                graph export "${output_figures_path}/`var'_figs/`var'_map_alt1_excess_year`predict_year'_month`predict_month'_start`series_start'.pdf", replace

            maptile `var'_excess_trend, geo(state) geoid(statefips) cutvalues(`graph_min_alt2'(`graph_int_alt2')`graph_max_alt2') ///
                legd(1) twopt(title("`title' ${`var'_label}: ${month`predict_month'_label} `predict_year'", size(large) justification(left)) legend(size(small)))
                graph export "${output_figures_path}/`var'_figs/`var'_map_alt2_excess_year`predict_year'_month`predict_month'_start`series_start'.pdf", replace

            rename statefips statefip

            * Locals for map colors
            local map_color1 "255 255 0"
            local map_color2 "255 243 0"
            local map_color3 "255 206 0"
            local map_color4 "255 150 0"
            local map_color5 "255 79 0"
            local map_color6 "255 0 0"

            local map_intensity1 = 0.1
            local map_intensity2 = 0.35
            local map_intensity3 = 0.639
            local map_intensity4 = 0.957
            local map_intensity5 = 1.298
            local map_intensity6 = 1.65

            * Dotplot of excess
            sort `var'_excess_trend
            gen row = _n
            global numlist "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51"
            local label_lines $numlist
            gen graph_label = ""
            forvalues i = 1/51 {
                sum statefip if row == `i'
                local statefip = r(mean)
                replace graph_label = "${statefip`statefip'_label}" if row == `i'
            }
            forvalues i = 1/51 {
                levelsof graph_label if row == `i'
                label define y_labels `i' `r(levels)', add
            }
            label values row y_labels
            count if (`var'_excess_low_trend > 0)
            local significant = r(N)
            sum `var'_excess_trend, det
            local median = r(p50)

            * Color version to match map
            twoway (dot `var'_excess_trend row if `var'_excess_trend <= `max_int1', ///
                horizontal msymbol(circle) msize(medium) mcolor("`map_color1'*`map_intensity1'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int2' & `var'_excess_trend > `max_int1', ///
                horizontal msymbol(circle) msize(medium) mcolor("`map_color2'*`map_intensity2'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int3' & `var'_excess_trend > `max_int2', ///
                horizontal msymbol(circle) msize(medium) mcolor("`map_color3'*`map_intensity3'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int4' & `var'_excess_trend > `max_int3', ///
                horizontal msymbol(circle) msize(medium) mcolor("`map_color4'*`map_intensity4'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int5' & `var'_excess_trend > `max_int4', ///
                horizontal msymbol(circle) msize(medium) mcolor("`map_color5'*`map_intensity5'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int6' & `var'_excess_trend > `max_int5', ///
                horizontal msymbol(circle) msize(medium) mcolor("`map_color6'*`map_intensity6'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (rcap `var'_excess_low `var'_excess_high row, horizontal lpattern(solid) lwidth(thin) lcolor(gs6)) ///
                , scheme(s1mono) xline(0, lwidth(thin) lpattern(solid)) xline(`median', lwidth(thin) lpattern(dash)) ///
                ytitle("") ylabel(1(1)51, valuelabel angle(0) labsize(vsmall) nogrid) ///
                yline(`label_lines', lwidth(thin) lcolor(gs14)) xtitle("") ///
                legend(pos(6) size(small) symxsize(small) region(lstyle(solid)) cols(1) ///
                order(1 "`title' `dotplot_label'" 7 "95% Confidence Interval")) ///
                ysize(15) xsize(8) ///
                subtitle("(b) `title' ${`var'_label}", position(11) justification(left) size(small)) saving(`var'_main, replace)

            drop row graph_label
            label drop _all
            sort `compare_var'_excess_trend
            gen row = _n
            local label_lines $numlist
            gen graph_label = ""
            forvalues i = 1/51 {
                sum statefip if row == `i'
                local statefip = r(mean)
                replace graph_label = "${statefip`statefip'_label}" if row == `i'
            }
            forvalues i = 1/51 {
                levelsof graph_label if row == `i'
                label define y_labels `i' `r(levels)', add
            }
            label values row y_labels
            sum `var'_excess_trend, det
            local median = r(p50)

            * Color version to match map: no labels
            twoway (dot `var'_excess_trend row if `var'_excess_trend <= `max_int1', ///
                horizontal msymbol(square) msize(medium) mcolor("`map_color1'*`map_intensity1'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int2' & `var'_excess_trend > `max_int1', ///
                horizontal msymbol(square) msize(medium) mcolor("`map_color2'*`map_intensity2'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int3' & `var'_excess_trend > `max_int2', ///
                horizontal msymbol(square) msize(medium) mcolor("`map_color3'*`map_intensity3'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int4' & `var'_excess_trend > `max_int3', ///
                horizontal msymbol(square) msize(medium) mcolor("`map_color4'*`map_intensity4'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int5' & `var'_excess_trend > `max_int4', ///
                horizontal msymbol(square) msize(medium) mcolor("`map_color5'*`map_intensity5'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (dot `var'_excess_trend row if `var'_excess_trend <= `max_int6' & `var'_excess_trend > `max_int5', ///
                horizontal msymbol(square) msize(medium) mcolor("`map_color6'*`map_intensity6'") mlcolor(gray) mlwidth(vthin) ///
                dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
                (rcap `var'_excess_low `var'_excess_high row, horizontal lpattern(solid) lwidth(thin) lcolor(gs6)) ///
                , scheme(s1mono) xline(0, lwidth(thin) lpattern(solid)) xline(`median', lwidth(thin) lpattern(dash)) ///
                ylabel(1(1)51, nolabels nogrid) ytitle("") ///
                yline(`label_lines', lwidth(thin) lcolor(gs14)) xtitle("") ///
                legend(pos(6) size(small) symxsize(small) region(lstyle(solid)) cols(1) ///
                order(1 "`title' `dotplot_label'" 7 "95% Confidence Interval")) ///
                ysize(15) xsize(8) ///
                subtitle("(d) `title' ${`var'_label}", position(11) justification(left) size(small)) saving(`var'_sort_`compare_var', replace)
        }
        foreach var in mortality emp_rate {
            if "`var'" == "mortality" {
                local compare_var "emp_rate"
            }
            if "`var'" == "emp_rate" {
                local compare_var "mortality"
            }
            graph combine `var'_main.gph `compare_var'_sort_`var'.gph, col(2) ///
                ysize(15) xsize(16) graphregion(color(white) margin(zero)) saving(`var'_sort_dotplot_color_excess_year`predict_year'_month`predict_month'_start`series_start'.gph, replace)
            graph export "${output_figures_path}/`var'_figs/`var'_sort_dotplot_color_excess_year`predict_year'_month`predict_month'_start`series_start'.pdf", replace
            rm `var'_main.gph
            rm `compare_var'_sort_`var'.gph
        }

        if "`series_start'" == "2011" {
            graph combine mortality_map_excess_year`predict_year'_month`predict_month'_start`series_start'.gph ///
                emp_rate_map_excess_year`predict_year'_month`predict_month'_start`series_start'.gph, ///
                col(2) xsize(16) ysize(5) fysize(40) graphregion(color(white) margin(zero)) saving(figure2i.gph, replace)

            graph combine figure2i.gph mortality_sort_dotplot_color_excess_year`predict_year'_month`predict_month'_start2011.gph, ///
                col(1) xsize(16) ysize(20) graphregion(color(white))
            graph export "${output_figures_path}/main_figs/figure2.pdf", replace

            rm figure2i.gph
            rm mortality_map_excess_year`predict_year'_month`predict_month'_start`series_start'.gph
            rm emp_rate_map_excess_year`predict_year'_month`predict_month'_start`series_start'.gph
            rm mortality_sort_dotplot_color_excess_year`predict_year'_month`predict_month'_start2011.gph
            rm emp_rate_sort_dotplot_color_excess_year`predict_year'_month`predict_month'_start2011.gph
        }
    }
end

program compare_incidence_graph_age
    syntax, samp(str) predict_year(int) predict_month(int)
    use "${input_data_path}/emp_rate_predictions`predict_year'_start2011_`samp'.dta", clear
    merge 1:1 month year `samp' using "${input_data_path}/mortality_predictions`predict_year'_start2011_`samp'.dta", assert(1 2 3) keep(3) nogen
    keep if (year == `predict_year' & month == `predict_month')
    label_graph_points, samp(`samp')

    replace emp_rate_excess_trend = -1*emp_rate_excess_trend
    sum emp_rate_excess_trend, det
    local median_excess_emp: di %3.2f `r(p50)'
    sum mortality_excess_trend, det
    local median_excess_mort: di %3.2f `r(p50)'

    di "Correlation: "
    corr mortality_excess_trend emp_rate_excess_trend

    twoway (scatter mortality_excess_trend emp_rate_excess_trend if label == 0, msize(small) mcolor(gray) msymbol(o)) ///
        (scatter mortality_excess_trend emp_rate_excess_trend if label == 1, mlabcolor(black) mlabsize(small) mlabposition(8) mlabel(`samp'_code) mcolor(blue) msize(small) msymbol(o)) ///
        , scheme(s1mono) plotregion(style(none)) ///
        xtitle("Excess Decline in Employment") ytitle("Excess Mortality (per 10,000)") ylabel(, angle(0)) ///
        subtitle("Excess Mortality vs. Economic Effects: April 2020", size(medium) position(11)) legend(off)
    graph export "${output_figures_path}/compare_incidence_figs/emp_rate_mortality_month4_year_2020_`samp'_comparison.pdf", replace
end

program compare_incidence_graph
    syntax, samp(str) predict_year(int) predict_month(int)
    use "${input_data_path}/emp_rate_predictions`predict_year'_start2011_`samp'.dta", clear
    merge 1:1 month year `samp' using "${input_data_path}/mortality_predictions`predict_year'_start2011_`samp'.dta", assert(1 2 3) keep(3) nogen
    merge 1:1 month year `samp' using "${input_data_path}/emp_rate2_predictions`predict_year'_start2011_`samp'.dta", assert(1 2 3) keep(3) nogen
    keep if (year == `predict_year' & month == `predict_month')
    merge 1:1 statefip using "${input_data_path}/state_industry_shares2018.dta", assert(1 2 3) keep(1 3) nogen
    label_graph_points, samp(`samp')

    foreach var in emp_rate emp_rate2 {
        replace `var'_excess_trend = -1*`var'_excess_trend
        sum `var'_excess_trend, det
        local median_excess_emp: di %3.2f `r(p50)'
        sum mortality_excess_trend, det
        local median_excess_mort: di %3.2f `r(p50)'

        di "Correlation: "
        corr mortality_excess_trend emp_rate_excess_trend

        twoway (scatter mortality_excess_trend `var'_excess_trend if label == 0, msize(small) mcolor(gray) msymbol(o)) ///
            (scatter mortality_excess_trend `var'_excess_trend if label == 1, mlabcolor(black) mlabsize(small) mlabposition(8) mlabel(`samp'_code) mcolor(blue) msize(small) msymbol(o)) ///
            (lfit mortality_excess_trend `var'_excess_trend, lcolor(black)), scheme(s1mono) plotregion(style(none)) ///
            xtitle("Excess Decline in ${`var'_label}") ytitle("Excess Mortality (per 10,000)") ylabel(, angle(0)) ///
            subtitle("Excess Mortality vs. Economic Effects: April 2020", size(medium) position(11)) legend(off) ///
            xline(`median_excess_emp', lpattern(dash)) yline(`median_excess_mort', lpattern(dash))
        graph export "${output_figures_path}/compare_incidence_figs/`var'_mortality_month4_year_2020_`samp'_comparison.pdf", replace
        if ("`samp'" == "statefip" & "`var'" == "emp_rate") {
            graph export "${output_figures_path}/main_figs/figure3.pdf", replace
        }
    }

    * Industry share
    forvalues industry = 100(100)1800 {
        foreach var in mortality emp_rate {
            reg `var'_excess_trend industry_share`industry', robust
            local slope_`var' = _b[industry_share`industry']
            local se_`var' = _se[industry_share`industry']
            local ci_low_`var' = `slope_`var'' - 1.96*`se_`var''
            local ci_high_`var' = `slope_`var'' + 1.96*`se_`var''
            matrix ind`industry'_`var' = (`slope_`var'', `ci_low_`var'', `ci_high_`var'')
            matrix ind`industry'_row = nullmat(ind`industry'_row), ind`industry'_`var'
        }
        matrix industry_slopes_table = nullmat(industry_slopes_table) \ ind`industry'_row
    }
    matrix_to_txt, saving(${output_tables_path}/industry_slopes_table.txt) ///
        mat(industry_slopes_table) format(%10.3f)  title(<tab:industry_slopes_table>) replace

    * Table to show share in top states
    if "`samp'" == "statefip" {
        gen mortality_excess_wgt = mortality_population*mortality_excess_trend
        gen emp_rate_excess_wgt = emp_rate_population*emp_rate_excess_trend
        sort mortality_excess_wgt
        gen deaths_excess_rank = 52 - _n
        sort emp_rate_excess_wgt
        gen emp_loss_excess_rank = 52 - _n
        sort mortality_excess_trend
        gen mortality_excess_rank = 52 - _n
        sort emp_rate_excess_trend
        gen emp_rate_excess_rank = 52 - _n

        sum mortality_excess_wgt
        local national_excess_mortality = r(sum)
        sum emp_rate_excess_wgt
        local national_missing_emp_rate = r(sum)

        forvalues i = 1/5 {
            egen excess_mortality_top`i' = sum(mortality_excess_wgt) if mortality_excess_rank <= `i'
            egen missing_emp_rate_top`i' = sum(emp_rate_excess_wgt) if emp_rate_excess_rank <= `i'
            egen excess_deaths_top`i' = sum(mortality_excess_wgt) if deaths_excess_rank <= `i'
            egen missing_emp_top`i' = sum(emp_rate_excess_wgt) if emp_loss_excess_rank <= `i'
            sum excess_mortality_top`i'
            local excess_mortality_top`i' = r(mean)
            sum missing_emp_rate_top`i'
            local missing_emp_rate_top`i' = r(mean)
            sum excess_deaths_top`i'
            local excess_deaths_top`i' = r(mean)
            sum missing_emp_top`i'
            local missing_emp_top`i' = r(mean)
        }

        use "${input_data_path}/emp_rate_predictions`predict_year'_start2011_all.dta", clear
        merge 1:1 month year using "${input_data_path}/mortality_predictions`predict_year'_start2011_all.dta", assert(1 2 3) keep(3) nogen
        keep if (year == `predict_year' & month == `predict_month')
        replace emp_rate_excess_trend = -1*emp_rate_excess_trend
        gen mortality_excess_wgt = mortality_population*mortality_excess_trend
        gen emp_rate_excess_wgt = emp_rate_population*emp_rate_excess_trend
        sum mortality_excess_wgt
        local national_excess_mortality = r(sum)
        sum emp_rate_excess_wgt
        local national_missing_emp_rate = r(sum)

        forvalues i = 1/5 {
            local pct_emp_rate_top`i'_natl = 100*`missing_emp_rate_top`i''/`national_missing_emp_rate'
            local pct_mortality_top`i'_natl = 100*`excess_mortality_top`i''/`national_excess_mortality'
            local pct_emp_top`i'_natl = 100*`missing_emp_top`i''/`national_missing_emp_rate'
            local pct_deaths_top`i'_natl = 100*`excess_deaths_top`i''/`national_excess_mortality'
            matrix top_share_emp_rate_natl = nullmat(top_share_emp_rate_natl) \ `pct_emp_rate_top`i'_natl'
            matrix top_share_mortality_natl = nullmat(top_share_mortality_natl) \ `pct_mortality_top`i'_natl'
            matrix top_share_emp_natl = nullmat(top_share_emp_natl) \ `pct_emp_top`i'_natl'
            matrix top_share_deaths_natl = nullmat(top_share_deaths_natl) \ `pct_deaths_top`i'_natl'
        }

        matrix top_share_matrix = (top_share_emp_rate_natl \ top_share_mortality_natl)
        matrix_to_txt, saving(${output_tables_path}/top_share_matrix.txt) ///
            mat(top_share_matrix) format(%10.2f)  title(<tab:top_share_matrix>) replace

        matrix top_share_matrix_pop = (top_share_emp_natl \ top_share_deaths_natl)
        matrix_to_txt, saving(${output_tables_path}/top_share_matrix_pop.txt) ///
            mat(top_share_matrix_pop) format(%10.2f) title(<tab:top_share_matrix_pop>) replace
        clear matrix
    }
end

program compare_incidence_tables
    syntax, predict_year(int) predict_month(int)
    foreach samp in all allage agegrpcdc {
        use "${input_data_path}/emp_rate_predictions`predict_year'_start2011_`samp'.dta", clear
        merge 1:1 month year `samp' using "${input_data_path}/mortality_predictions`predict_year'_start2011_`samp'.dta", assert(1 2 3) keep(3) nogen
        keep if (year == `predict_year' & month == `predict_month')
        save "${temp_data_path}/`samp'_merged_outcomes.dta", replace
    }
    use "${temp_data_path}/allage_merged_outcomes.dta", clear
    append using "${temp_data_path}/agegrpcdc_merged_outcomes.dta"
    append using "${temp_data_path}/all_merged_outcomes.dta"

    rename emp_rate_excess_low_trend emp_rate_excess_high_trendt
    rename emp_rate_excess_high_trend emp_rate_excess_low_trend
    rename emp_rate_excess_high_trendt emp_rate_excess_high_trend
    rename emp_rate_pct_excess_low_trend emp_rate_pct_excess_high_trendt
    rename emp_rate_pct_excess_high_trend emp_rate_pct_excess_low_trend
    rename emp_rate_pct_excess_high_trendt emp_rate_pct_excess_high_trend
    foreach measure in emp_rate_excess_trend emp_rate_excess_low_trend emp_rate_excess_high_trend emp_rate_pct_excess_trend emp_rate_pct_excess_low_trend emp_rate_pct_excess_high_trend {
        replace `measure' = -1*`measure'
    }

    gen jobs_death_ratio = (emp_rate_excess_trend/100)/(mortality_excess_trend/10000)
    gen mortality_displaced = mortality_population*mortality_excess_trend/10000
    replace emp_rate_population = 1000*emp_rate_population
    gen emp_rate_displaced = (emp_rate_population)*(emp_rate_excess_trend/100)

    foreach samp in allage agegrpcdc {
        foreach var in emp_rate mortality {
            foreach val in ${`samp'_compare_vallist} {
                if "`val'" != "0" {
                    foreach stat in `var' `var'_pred_trend `var'_pred_low_trend `var'_pred_high_trend `var'_excess_trend ///
                        `var'_excess_low_trend `var'_excess_high_trend `var'_pct_excess_trend ///
                        `var'_pct_excess_low_trend `var'_pct_excess_high_trend {
                            sum `stat' if `samp' == `val'
                            local table_val = r(mean)
                            matrix `samp'`val'_`var' = nullmat(`samp'`val'_`var'), `table_val'
                    }
                    foreach stat in `var'_displaced `var'_population {
                        sum `stat' if `samp' == `val'
                        local table_val = r(mean)
                        matrix `samp'`val'_`var'2 = nullmat(`samp'`val'_`var'2), `table_val'
                    }
                    matrix `samp'_`var' = nullmat(`samp'_`var') \ `samp'`val'_`var'
                    matrix `samp'_`var'2 = nullmat(`samp'_`var'2) \ `samp'`val'_`var'2
                }
            }
        }
    }

    foreach samp in all allage agegrpcdc {
        foreach val in ${`samp'_compare_vallist} {
            if "`val'" != "0" {
                sum jobs_death_ratio if `samp' == `val'
                local table_val = r(mean)
                matrix jobs_death_table = nullmat(jobs_death_table) \ `table_val'
            }
        }
    }

    matrix prediction_matrix_combined_cdc = allage_emp_rate \ agegrpcdc_emp_rate \ allage_mortality \ agegrpcdc_mortality
    matrix_to_txt, saving(${output_tables_path}/prediction_matrix_combined_cdc.txt) ///
        mat(prediction_matrix_combined_cdc) format(%12.2f)  title(<tab:prediction_matrix_combined_cdc>) replace

    matrix prediction_matrix_count = allage_emp_rate2 \ agegrpcdc_emp_rate2 \ allage_mortality2 \ agegrpcdc_mortality2
    matrix_to_txt, saving(${output_tables_path}/prediction_matrix_count.txt) ///
        mat(prediction_matrix_count) format(%12.2f) title(<tab:prediction_matrix_count>) replace

    matrix_to_txt, saving(${output_tables_path}/jobs_death_table.txt) ///
        mat(jobs_death_table) format(%12.2f) title(<tab:jobs_death_table>) replace

    clear matrix
end

program alternate_mortality_table
    syntax, predict_year(int) predict_month(int)
    use "${input_data_path}/mortality_predictions`predict_year'_start2011_all.dta", clear
    foreach var in mortality0 {
        merge 1:1 month year using "${input_data_path}/`var'_predictions`predict_year'_start2011_all.dta", assert(1 2 3) keep(3) nogen
    }
    keep if year == `predict_year' & month == `predict_month'
    foreach var in mortality mortality0 {
        foreach stat in `var' `var'_pred_trend `var'_pred_low_trend `var'_pred_high_trend `var'_excess_trend ///
            `var'_excess_low_trend `var'_excess_high_trend {
                sum `stat'
                local table_val = r(mean)
                matrix `var'_row = nullmat(`var'_row), `table_val'
        }
        matrix deaths_robustness = nullmat(deaths_robustness) \ `var'_row
    }

    * Add robustness of state correlations
    use "${input_data_path}/mortality_predictions`predict_year'_start2011_statefip.dta", clear
    merge 1:1 month year statefip using "${input_data_path}/mortality0_predictions`predict_year'_start2011_statefip.dta", assert(3) keep(3) nogen
    merge 1:1 month year statefip using "${input_data_path}/emp_rate_predictions`predict_year'_start2011_statefip.dta", assert(1 2 3) keep(3) nogen
    keep if (year == `predict_year' & month == `predict_month')
    gen reported_pct = 100*(mortality0/mortality)
    sum reported_pct
    count if reported_pct < 90
    replace emp_rate_excess_trend = -1*emp_rate_excess_trend
    foreach var in mortality mortality0 {
        reg `var'_excess_trend emp_rate_excess_trend, robust
        local slope = _b[emp_rate_excess_trend]
        local slope_se = _se[emp_rate_excess_trend]
        local slope_high = `slope' + 1.96*`slope_se'
        local slope_low = `slope' - 1.96*`slope_se'

        reg `var'_excess_trend emp_rate_excess_trend if reported_pct >= 90, robust
        local slope_drop = _b[emp_rate_excess_trend]
        local slope_drop_se = _se[emp_rate_excess_trend]
        local slope_drop_high = `slope_drop' + 1.96*`slope_drop_se'
        local slope_drop_low = `slope_drop' - 1.96*`slope_drop_se'

        matrix slope_col = nullmat(slope_col) \ (`slope', `slope_low', `slope_high')
        matrix slope_drop_col = nullmat(slope_drop_col) \ (`slope_drop', `slope_drop_low', `slope_drop_high')
    }

    matrix deaths_robustness = deaths_robustness, slope_col, slope_drop_col
    matrix_to_txt, saving(${output_tables_path}/deaths_robustness.txt) ///
        mat(deaths_robustness) format(%10.3f)  title(<tab:deaths_robustness>) replace
    clear matrix
end

program alternate_economic_table
    syntax, predict_year(int) predict_month(int)
    local alt_vars "emp_rate2 avg_hours unemp_rate iur"
    use "${input_data_path}/emp_rate_predictions`predict_year'_start2011_all.dta", clear
    foreach var in `alt_vars' {
        merge 1:1 month year using "${input_data_path}/`var'_predictions`predict_year'_start2011_all.dta", assert(1 2 3) keep(3) nogen
    }
    keep if year == `predict_year' & month == `predict_month'
    foreach var in emp_rate emp_rate2 avg_hours {
        rename `var'_excess_low_trend `var'_excess_high_trendt
        rename `var'_excess_high_trend `var'_excess_low_trend
        rename `var'_excess_high_trendt `var'_excess_high_trend
        rename `var'_pct_excess_low_trend `var'_pct_excess_high_trendt
        rename `var'_pct_excess_high_trend `var'_pct_excess_low_trend
        rename `var'_pct_excess_high_trendt `var'_pct_excess_high_trend
        foreach measure in `var'_excess_trend `var'_excess_low_trend `var'_excess_high_trend `var'_pct_excess_trend `var'_pct_excess_low_trend `var'_pct_excess_high_trend {
            replace `measure' = -1*`measure'
        }
    }

    foreach var in emp_rate `alt_vars' {
        foreach stat in `var' `var'_pred_trend `var'_pred_low_trend `var'_pred_high_trend `var'_excess_trend ///
            `var'_excess_low_trend `var'_excess_high_trend {
                sum `stat'
                local table_val = r(mean)
                matrix `var'_row = nullmat(`var'_row), `table_val'
        }
        matrix economic_robustness = nullmat(economic_robustness) \ `var'_row
    }

    * Add robustness of state correlations
    use "${input_data_path}/mortality_predictions`predict_year'_start2011_statefip.dta", clear
    foreach var in emp_rate `alt_vars' {
        merge 1:1 month year statefip using "${input_data_path}/`var'_predictions`predict_year'_start2011_statefip.dta", assert(1 2 3) keep(3) nogen
    }
    keep if (year == `predict_year' & month == `predict_month')
    replace emp_rate_excess_trend = -1*emp_rate_excess_trend
    replace emp_rate2_excess_trend = -1*emp_rate2_excess_trend
    replace avg_hours_excess_trend = -1*avg_hours_excess_trend
    foreach var in emp_rate `alt_vars' {
        reg mortality_excess_trend `var'_excess_trend, robust
        local slope = _b[`var'_excess_trend]
        local slope_se = _se[`var'_excess_trend]
        local slope_high = `slope' + 1.96*`slope_se'
        local slope_low = `slope' - 1.96*`slope_se'

        reg mortality_excess_trend `var'_excess_trend if (statefip != 34 & statefip != 36), robust
        local slope_drop = _b[`var'_excess_trend]
        local slope_drop_se = _se[`var'_excess_trend]
        local slope_drop_high = `slope_drop' + 1.96*`slope_drop_se'
        local slope_drop_low = `slope_drop' - 1.96*`slope_drop_se'

        matrix slope_col = nullmat(slope_col) \ (`slope', `slope_low', `slope_high')
        matrix slope_drop_col = nullmat(slope_drop_col) \ (`slope_drop', `slope_drop_low', `slope_drop_high')
    }

    matrix economic_robustness = economic_robustness, slope_col, slope_drop_col
    matrix_to_txt, saving(${output_tables_path}/economic_robustness.txt) ///
        mat(economic_robustness) format(%10.3f)  title(<tab:economic_robustness>) replace
    clear matrix
end

program alternate_specification_table
    syntax, predict_year(int) predict_month(int)
    use "${input_data_path}/emp_rate_predictions`predict_year'_start2011_all.dta", clear
    drop if month > `predict_month' & year == `predict_year'
    merge 1:1 month year using "${input_data_path}/mortality_predictions`predict_year'_start2011_all.dta", assert(3) keep(3) nogen
    keep month year *_excess_low_* *_excess_high_* *_excess_* *_pred_* *_pred_low_* *_pred_high_*
    keep if year == `predict_year' & month == `predict_month'
    switch_excess_emp_rate
    foreach var in mortality emp_rate {
        foreach outcome in pred excess {
            sum `var'_`outcome'_trend
            local mean = r(mean)
            sum `var'_`outcome'_low_trend
            local ci_low = r(mean)
            sum `var'_`outcome'_high_trend
            local ci_high = r(mean)
            matrix `var'_`outcome'_panel = `mean', `ci_low', `ci_high'
        }
    }

    use "${input_data_path}/emp_rate_predictions`predict_year'_start2011_statefip.dta", clear
    drop if month > `predict_month' & year == `predict_year'
    merge 1:1 month year statefip using "${input_data_path}/mortality_predictions`predict_year'_start2011_statefip.dta", assert(3) keep(3) nogen
    keep statefip month year *_excess_low_* *_excess_high_* *_excess_* *_pred_* *_pred_low_* *_pred_high_*
    keep if year == `predict_year' & month == `predict_month'
    switch_excess_emp_rate
    reg mortality_excess_trend emp_rate_excess_trend, robust
    local slope = _b[emp_rate_excess_trend]
    local se = _se[emp_rate_excess_trend]
    local slope_low = `slope' - 1.96*`se'
    local slope_high = `slope' + 1.96*`se'
    matrix slope_panel = `slope', `slope_low', `slope_high'
    matrix baseline_col = mortality_pred_panel \ mortality_excess_panel \ emp_rate_pred_panel \ emp_rate_excess_panel \ slope_panel

    use "${input_data_path}/emp_rate_predictions`predict_year'_start2015_all.dta", clear
    drop if month > `predict_month' & year == `predict_year'
    merge 1:1 month year using "${input_data_path}/mortality_predictions`predict_year'_start2015_all.dta", assert(3) keep(3) nogen
    keep month year *_excess_low_* *_excess_high_* *_excess_* *_pred_* *_pred_low_* *_pred_high_*
    keep if year == `predict_year' & month == `predict_month'
    switch_excess_emp_rate
    foreach var in mortality emp_rate {
        foreach outcome in pred excess {
            foreach method in trend avg {
                sum `var'_`outcome'_`method'
                local mean = r(mean)
                sum `var'_`outcome'_low_`method'
                local ci_low = r(mean)
                sum `var'_`outcome'_high_`method'
                local ci_high = r(mean)
                matrix `var'_`outcome'_`method'_panel = `mean', `ci_low', `ci_high'
            }
        }
    }

    use "${input_data_path}/emp_rate_predictions`predict_year'_start2015_statefip.dta", clear
    drop if month > `predict_month' & year == `predict_year'
    merge 1:1 month year statefip using "${input_data_path}/mortality_predictions`predict_year'_start2015_statefip.dta", assert(3) keep(3) nogen
    keep statefip month year *_excess_low_* *_excess_high_* *_excess_* *_pred_* *_pred_low_* *_pred_high_*
    keep if year == `predict_year' & month == `predict_month'
    switch_excess_emp_rate
    foreach method in trend avg {
        reg mortality_excess_`method' emp_rate_excess_`method', robust
        local slope = _b[emp_rate_excess_`method']
        local se = _se[emp_rate_excess_`method']
        local slope_low = `slope' - 1.96*`se'
        local slope_high = `slope' + 1.96*`se'
        matrix slope_panel_`method' = `slope', `slope_low', `slope_high'

        matrix `method'2015_col = mortality_pred_`method'_panel \ mortality_excess_`method'_panel \ emp_rate_pred_`method'_panel \ emp_rate_excess_`method'_panel \ slope_panel_`method'
    }

    matrix robustness_specification = baseline_col, trend2015_col, avg2015_col
    matrix_to_txt, saving(${output_tables_path}/robustness_specification.txt) ///
        mat(robustness_specification) format(%10.3f)  title(<tab:robustness_specification>) replace
    clear matrix
end

program deaths_emp_table
    syntax, predict_year(int) predict_month(int)
    use "${input_data_path}/employment_predictions`predict_year'_start2011_all.dta", clear
    drop if month > `predict_month' & year == `predict_year'
    merge 1:1 month year using "${input_data_path}/allcause_predictions`predict_year'_start2011_all.dta", assert(3) keep(3) nogen
    keep month year *_excess_low_* *_excess_high_* *_excess_* *_pred_* *_pred_low_* *_pred_high_*
    keep if year == `predict_year' & month == `predict_month'
    foreach var in employment {
        foreach method in trend avg {
            rename `var'_excess_low_`method' `var'_excess_high_`method't
            rename `var'_excess_high_`method' `var'_excess_low_`method'
            rename `var'_excess_high_`method't `var'_excess_high_`method'
            foreach measure in `var'_excess_`method' `var'_excess_low_`method' `var'_excess_high_`method'  {
                replace `measure' = -1*`measure'
            }
        }
    }
    foreach var in allcause employment {
        foreach outcome in pred excess {
            sum `var'_`outcome'_trend
            local mean = r(mean)/1000
            sum `var'_`outcome'_low_trend
            local ci_low = r(mean)/1000
            sum `var'_`outcome'_high_trend
            local ci_high = r(mean)/1000
            matrix `var'_`outcome'_panel = `mean', `ci_low', `ci_high'
        }
    }

    use "${input_data_path}/employment_predictions`predict_year'_start2011_statefip.dta", clear
    drop if month > `predict_month' & year == `predict_year'
    merge 1:1 month year statefip using "${input_data_path}/allcause_predictions`predict_year'_start2011_statefip.dta", assert(3) keep(3) nogen
    keep statefip month year *_excess_low_* *_excess_high_* *_excess_* *_pred_* *_pred_low_* *_pred_high_*
    keep if year == `predict_year' & month == `predict_month'
    foreach var in employment {
        foreach method in trend avg {
            rename `var'_excess_low_`method' `var'_excess_high_`method't
            rename `var'_excess_high_`method' `var'_excess_low_`method'
            rename `var'_excess_high_`method't `var'_excess_high_`method'
            foreach measure in `var'_excess_`method' `var'_excess_low_`method' `var'_excess_high_`method'  {
                replace `measure' = -1*`measure'
            }
        }
    }
    reg allcause_excess_trend employment_excess_trend, robust
    local slope = _b[employment_excess_trend]
    local se = _se[employment_excess_trend]
    local slope_low = `slope' - 1.96*`se'
    local slope_high = `slope' + 1.96*`se'
    matrix slope_alt_panel = `slope', `slope_low', `slope_high'
    matrix levels_trend_table = allcause_pred_panel \ allcause_excess_panel \ employment_pred_panel \ employment_excess_panel \ slope_alt_panel

    matrix_to_txt, saving(${output_tables_path}/levels_trend_table.txt) ///
        mat(levels_trend_table) format(%10.3f)  title(<tab:levels_trend_table>) replace
    clear matrix

    foreach samp in allage agegrpcdc {
        use "${input_data_path}/employment_predictions`predict_year'_start2011_`samp'.dta", clear
        drop if month > `predict_month' & year == `predict_year'
        merge 1:1 month year `samp' using "${input_data_path}/allcause_predictions`predict_year'_start2011_`samp'.dta", assert(1 2 3) keep(3) nogen
        keep if (year == `predict_year' & month == `predict_month')
        save "${temp_data_path}/`samp'_merged_levels.dta", replace
    }
    use "${temp_data_path}/allage_merged_levels.dta", clear
    append using "${temp_data_path}/agegrpcdc_merged_levels.dta"

    rename employment_excess_low_trend employment_excess_high_trendt
    rename employment_excess_high_trend employment_excess_low_trend
    rename employment_excess_high_trendt employment_excess_high_trend
    rename employment_pct_excess_low_trend employment_pct_excess_hight
    rename employment_pct_excess_high_trend employment_pct_excess_low_trend
    rename employment_pct_excess_hight employment_pct_excess_high_trend
    foreach measure in employment_excess_trend employment_excess_low_trend employment_excess_high_trend employment_pct_excess_trend employment_pct_excess_low_trend employment_pct_excess_high_trend {
        replace `measure' = -1*`measure'
    }

    foreach samp in allage agegrpcdc {
        foreach var in employment allcause {
            foreach val in ${`samp'_compare_vallist} {
                if "`val'" != "0" {
                    foreach stat in `var' `var'_pred_trend `var'_pred_low_trend `var'_pred_high_trend `var'_excess_trend ///
                        `var'_excess_low_trend `var'_excess_high_trend {
                            sum `stat' if `samp' == `val'
                            local table_val = r(mean)/1000
                            matrix `samp'`val'_`var' = nullmat(`samp'`val'_`var'), `table_val'
                    }
                    foreach stat in `var'_pct_excess_trend `var'_pct_excess_low_trend `var'_pct_excess_high_trend {
                            sum `stat' if `samp' == `val'
                            local table_val = r(mean)
                            matrix `samp'`val'_`var' = nullmat(`samp'`val'_`var'), `table_val'
                    }
                    matrix `samp'_`var' = nullmat(`samp'_`var') \ `samp'`val'_`var'
                }
            }
        }
    }
    matrix prediction_matrix_levels = allage_employment \ agegrpcdc_employment \ allage_allcause \ agegrpcdc_allcause
    matrix_to_txt, saving(${output_tables_path}/prediction_matrix_levels.txt) ///
        mat(prediction_matrix_levels) format(%12.2f)  title(<tab:prediction_matrix_levels>) replace
end

program switch_excess_emp_rate
    foreach var in emp_rate {
        foreach method in trend avg {
            rename `var'_excess_low_`method' `var'_excess_high_`method't
            rename `var'_excess_high_`method' `var'_excess_low_`method'
            rename `var'_excess_high_`method't `var'_excess_high_`method'
            foreach measure in `var'_excess_`method' `var'_excess_low_`method' `var'_excess_high_`method'  {
                replace `measure' = -1*`measure'
            }
        }
    }
end

program label_graph_points
    syntax, samp(str)
    gen label = 0
    gen `samp'_code = ""
    if "`samp'" == "statefip" {
        replace label = 1 if statefip == 34
        replace label = 1 if statefip == 26
        replace label = 1 if statefip == 36
        replace label = 1 if statefip == 15
        replace label = 1 if statefip == 32
        replace label = 1 if statefip == 56
        replace label = 1 if statefip == 22
        replace label = 1 if statefip == 11
        replace label = 1 if statefip == 17
        replace label = 1 if statefip == 6
        replace label = 1 if statefip == 25
        replace label = 1 if statefip == 37
        replace label = 1 if statefip == 51

        replace statefip_code = "AL" if statefip == 1
        replace statefip_code = "AK" if statefip == 2
        replace statefip_code = "AZ" if statefip == 4
        replace statefip_code = "AR" if statefip == 5
        replace statefip_code = "CA" if statefip == 6
        replace statefip_code = "CO" if statefip == 8
        replace statefip_code = "CT" if statefip == 9
        replace statefip_code = "DE" if statefip == 10
        replace statefip_code = "DC" if statefip == 11
        replace statefip_code = "FL" if statefip == 12
        replace statefip_code = "GA" if statefip == 13
        replace statefip_code = "HI" if statefip == 15
        replace statefip_code = "ID" if statefip == 16
        replace statefip_code = "IL" if statefip == 17
        replace statefip_code = "IN" if statefip == 18
        replace statefip_code = "IA" if statefip == 19
        replace statefip_code = "KS" if statefip == 20
        replace statefip_code = "KY" if statefip == 21
        replace statefip_code = "LA" if statefip == 22
        replace statefip_code = "ME" if statefip == 23
        replace statefip_code = "MD" if statefip == 24
        replace statefip_code = "MA" if statefip == 25
        replace statefip_code = "MI" if statefip == 26
        replace statefip_code = "MN" if statefip == 27
        replace statefip_code = "MS" if statefip == 28
        replace statefip_code = "MO" if statefip == 29
        replace statefip_code = "MT" if statefip == 30
        replace statefip_code = "NE" if statefip == 31
        replace statefip_code = "NV" if statefip == 32
        replace statefip_code = "NH" if statefip == 33
        replace statefip_code = "NJ" if statefip == 34
        replace statefip_code = "NM" if statefip == 35
        replace statefip_code = "NY" if statefip == 36
        replace statefip_code = "NC" if statefip == 37
        replace statefip_code = "ND" if statefip == 38
        replace statefip_code = "OH" if statefip == 39
        replace statefip_code = "OK" if statefip == 40
        replace statefip_code = "OR" if statefip == 41
        replace statefip_code = "PA" if statefip == 42
        replace statefip_code = "RI" if statefip == 44
        replace statefip_code = "SC" if statefip == 45
        replace statefip_code = "SD" if statefip == 46
        replace statefip_code = "TN" if statefip == 47
        replace statefip_code = "TX" if statefip == 48
        replace statefip_code = "UT" if statefip == 49
        replace statefip_code = "VT" if statefip == 50
        replace statefip_code = "VA" if statefip == 51
        replace statefip_code = "WA" if statefip == 53
        replace statefip_code = "WV" if statefip == 54
        replace statefip_code = "WI" if statefip == 55
        replace statefip_code = "WY" if statefip == 56
    }
    if "`samp'" == "agegrpcdc" {
        replace label = 1 if agegrpcdc == 0
        replace agegrpcdc_code = "< 25" if agegrpcdc == 0
        replace label = 1 if agegrpcdc == 25
        replace agegrpcdc_code = "25-44" if agegrpcdc == 25
        replace label = 1 if agegrpcdc == 45
        replace agegrpcdc_code = "45-64" if agegrpcdc == 45
        replace label = 1 if agegrpcdc == 65
        replace agegrpcdc_code = "65-74" if agegrpcdc == 65
        replace label = 1 if agegrpcdc == 75
        replace agegrpcdc_code = "75-84" if agegrpcdc == 75
        replace label = 1 if agegrpcdc == 85
        replace agegrpcdc_code = "> 84" if agegrpcdc == 85
    }
end

program matrix_to_txt
  * Matrix to text program from GSLab
	syntax , Matrix(name) SAVing(str) [ REPlace APPend Title(str) Format(str) NOTe(str) USERownames USEColnames]

	if "`format'"=="" local format "%10.0g"
	local formatn: word count `format'
	local saving: subinstr local saving "." ".", count(local ext)
	if !`ext' local saving "`saving'.txt"
	tempname myfile
	file open `myfile' using "`saving'", write text `append' `replace'
	local nrows=rowsof(`matrix')
	local ncols=colsof(`matrix')
	QuotedFullnames `matrix' row
	QuotedFullnames `matrix' col

	* write title
	if "`title'"!="" {
		file write `myfile' `"`title'"' _n
	}

	* write column names
	if "`usecolnames'"!="" {
		if "`userownames'"!="" file write `myfile' _tab
		foreach colname of local colnames {
			file write `myfile' `"`colname'"' _tab
		}
		file write `myfile' _n
	}

	* write body of table
	forvalues r=1/`nrows' {
		if "`userownames'"!="" {
			local rowname: word `r' of `rownames'
			file write `myfile' `"`rowname'"' _tab
		}
		forvalues c=1/`ncols' {
			if `c'<=`formatn' local fmt: word `c' of `format'
			file write `myfile' `fmt' (`matrix'[`r',`c'])
			if `c'<`ncols' {
				file write `myfile' _tab
			}
		}
		file write `myfile' _n
	}
	if "`note'"!="" {
	file write `myfile' `"`note'"' _n
	}
	file close `myfile'

end

program QuotedFullnames
	args matrix type
	tempname extract
	local one 1
	local i one
	local j one
	if "`type'"=="row" local i k
	if "`type'"=="col" local j k
	local K = `type'sof(`matrix')
	forv k = 1/`K' {
		mat `extract' = `matrix'[``i''..``i'',``j''..``j'']
		local name: `type'names `extract'
		local eq: `type'eq `extract'
		if `"`eq'"'=="_" local eq
		else local eq `"`eq':"'
		local names `"`names'`"`eq'`name'"' "'
	}
	c_local `type'names `"`names'"'
end

* EXECUTE
main
