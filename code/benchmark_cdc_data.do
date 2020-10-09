**** INITIALIZE DIRECTORIES ***********************

    global external_data_path "../data"
    global temp_data_path "../temp"
    cap mkdir $temp_data_path
    global output_figures_path "../output/figures"
    cap mkdir $output_figures_path
    global output_tables_path "../output/tables"
    cap mkdir $external_data_path
****************************************************

version 15
set more off

program main
    gen_statefip_labels
    compare_excess_deaths
    compare_covid_deaths
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

program compare_excess_deaths
    use "${external_data_path}/excess_outcomes/mortality_predictions2020_start2011_statefip.dta", clear
    keep state statefip mortality_population mortality_excess_trend mortality_excess_*_trend mortality_pred_trend month year
    rename mortality_excess_trend mortality_excess_trend_pred2011
    rename mortality_pred_trend mortality_pred_trend_pred2011
    merge 1:1 statefip month year using "${external_data_path}/excess_outcomes/mortality_predictions2020_start2015_statefip.dta", assert(1 2 3) keep(3) keepusing(mortality_excess_trend mortality_pred_trend mortality) nogen
    rename mortality_excess_trend mortality_excess_trend_pred2015
    rename mortality_pred_trend mortality_pred_trend_pred2015
    merge 1:1 statefip month year using "${external_data_path}/cdc_excess_wgt/cdc_aggregate_excess_deaths2020.dta", assert(1 2 3) keep(3) nogen
    gen excess_cdc_mortality = 10000*excess_cdc_month/mortality_population
    gen pred_cdc_mortality = 10000*expected_cdc_month/mortality_population

    foreach year in 2011 {
        foreach var in excess pred {
            if "`var'" == "excess" {
                local label "Excess"
            }
            if "`var'" == "pred" {
                local label "Predicted"
            }

            sum mortality_`var'_trend_pred`year'
            local min_temp1 = r(min)
            local max_temp1 = r(max)
            sum `var'_cdc_mortality
            local min_temp2 = r(min)
            local max_temp2 = r(max)
            local graph_min = floor(min(`min_temp1', `min_temp2'))
            local graph_max = ceil(max(`max_temp1', `max_temp2'))

            twoway (scatter mortality_`var'_trend_pred`year' `var'_cdc_mortality if month == 4, msize(small)) ///
                (lfit mortality_`var'_trend_pred`year' `var'_cdc_mortality if month == 4, lcolor(red)) ///
                (line `var'_cdc_mortality `var'_cdc_mortality if month == 4, lcolor(black)), ///
                scheme(s1mono) xtitle("CDC Estimates: `label' Mortality April 2020") ylabel(`graph_min'(3)`graph_max', angle(0)) ///
                xlabel(`graph_min'(3)`graph_max') xsc(r(`graph_min' `graph_max')) ysc(r(`graph_min' `graph_max')) legend(label(1 "`label' Mortality") label(2 "Line of Best Fit") label(3 "45 Degree Line")) ///
                subtitle("`label' Mortality April 2020, Trend Since `year' (All States)", size(medium) position(11)) ///
                note("Excess mortality measured per 10,000")
            graph export "${output_figures_path}/scatter_`var'_mortality_pred`year'.pdf", replace

            sum `var'_cdc_mortality, det
            local max_val = r(p75)
            sum mortality_`var'_trend_pred`year' if mortality_`var'_trend_pred`year' < `max_val'
            local min_temp1 = r(min)
            local max_temp1 = r(max)
            sum `var'_cdc_mortality if `var'_cdc_mortality < `max_val'
            local min_temp2 = r(min)
            local max_temp2 = r(max)
            local graph_min = floor(min(`min_temp1', `min_temp2'))
            local graph_max = ceil(max(`max_temp1', `max_temp2'))

            twoway (scatter mortality_`var'_trend_pred`year' `var'_cdc_mortality if month == 4 & `var'_cdc_mortality < `max_val', msize(small)) ///
                (lfit mortality_`var'_trend_pred`year' `var'_cdc_mortality if month == 4 & `var'_cdc_mortality < `max_val', lcolor(red)) ///
                (line `var'_cdc_mortality `var'_cdc_mortality if month == 4 & `var'_cdc_mortality < `max_val', lcolor(black)), ///
                scheme(s1mono) xtitle("CDC Estimates: `label' Mortality April 2020") ylabel(`graph_min'(1)`graph_max', angle(0)) ///
                xlabel(`graph_min'(1)`graph_max') xsc(r(`graph_min' `graph_max')) ysc(r(`graph_min' `graph_max')) legend(label(1 "`label' Mortality") label(2 "Line of Best Fit") label(3 "45 Degree Line")) ///
                subtitle("`label' Mortality April 2020, Trend Since `year' (Low Excess Mort. States)", size(medium) position(11)) ///
                note("`label' mortality measured per 10,000; states in bottom three quartiles")
            graph export "${output_figures_path}/scatter_`var'_mortality_low_pred`year'.pdf", replace
        }
        gen deviation_from_cdc`year' = mortality_excess_trend_pred`year' - excess_cdc_mortality
        rename statefip statefips
        maptile deviation_from_cdc`year' if year == 2020 & month == 4, geo(state) geoid(statefips)  ///
            legd(1) twopt(title("Excess Mortality - CDC Excess Mortality per 10,000: April 2020") legend(size(small)))
        graph export "${output_figures_path}/deviation_cdc_excess_map_pred`year'.pdf", replace
        rename statefips statefip
    }

    * Map of CDC excess deaths
    preserve
    keep if month == 4
    rename statefip statefips
    maptile excess_cdc_mortality, geo(state) geoid(statefips) cutvalues(0(3)12) ///
        legd(1) twopt(title("CDC Excess Mortality in April 2020") legend(size(small)))
        graph export "${output_figures_path}/cdc_excess_mort_map_excess_year2020_month4.pdf", replace
    rename statefips statefip

    * Dotplot of our excess deaths with points for CDC excess deaths
    sort mortality_excess_trend_pred2011
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
    twoway (dot mortality_excess_trend_pred2011 row, horizontal msymbol(circle) msize(small) ///
        dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
        (dot excess_cdc_mortality row, horizontal msymbol(X) msize(medium) mcolor(red) ///
        dcolor(none) dlcolor(none) dsymbol(none) ylabel(1(1)51)) ///
        (rcap mortality_excess_low mortality_excess_high row, horizontal lpattern(solid) lwidth(thin) lcolor(gs6)) ///
        , scheme(s1mono) xline(0, lwidth(thin) lpattern(dash)) ytitle("") ///
        ylabel(1(1)51, valuelabel angle(0) labsize(small) nogrid) ///
        yline(`label_lines', lwidth(thin) lcolor(gs14)) xtitle("") ///
        legend(pos(6) size(small) symxsize(small) region(lstyle(solid)) cols(1) ///
        order(1 "Excess Mortality - Trend Since 2011" 2 "CDC Excess Mortality" 3 "95% Confidence Interval")) ///
        ysize(15) xsize(8) ///
        subtitle("CDC Excess Mortality vs. Trend Excess Mortality: April 2020", position(11) justification(left) size(small))
    graph export "${output_figures_path}/cdc_excess_dotplot_excess_year2020_month4.pdf", replace
    drop row graph_label
    label drop _all
    restore
end

program compare_covid_deaths
    use "${external_data_path}/excess_outcomes/mortality_predictions2020_start2011_statefip.dta", clear
    keep year month statefip state mortality_excess_trend covid_mortality mortality_pred_trend mortality_excess_low_trend mortality_excess_high_trend mortality_impute0 mortality mortality_population
    merge 1:1 state year month using "${external_data_path}/excess_outcomes/emp_rate_predictions2020_start2011_statefip.dta", assert(2 3) keep(3) keepusing(emp_rate_excess_trend) nogen
    keep if year == 2020 & month == 4
    replace emp_rate_excess_trend = -1*emp_rate_excess_trend

    gen incomplete_data = (mortality_impute0/mortality)*100 < 90
    gen noncov_mort_excess = mortality_excess_trend - covid_mortality
    gen noncov_mort_excess_high_trend = mortality_excess_high_trend - covid_mortality
    gen noncov_mort_excess_low_trend = mortality_excess_low_trend - covid_mortality
    gen significant_neg_mort = ((mortality_excess_high_trend - covid_mortality) < 0)
    list state if significant_neg_mort == 1 & incomplete_data == 0

    label_states

    count if incomplete_data == 1
    local missing_num = r(N)

    * Table of COVID deaths vs. excess deaths
    gen covid_deaths = covid_mortality*mortality_population/10000
    gen excess_deaths = mortality_excess_trend*mortality_population/10000
    sum covid_deaths, det
    local natl_covid_deaths = r(sum)
    sum excess_deaths, det
    local natl_excess_deaths = r(sum)
    local natl_covid_pct = 100*(`natl_covid_deaths'/`natl_excess_deaths')
    matrix covid_excess_deaths = (`natl_covid_deaths', `natl_excess_deaths', `natl_covid_pct')

    gen covid_compare_label = 0
    foreach statefip in 36 34 25 11 26 {
        sum covid_deaths if statefip == `statefip'
        local covid_deaths`statefip' = r(mean)
        sum excess_deaths if statefip == `statefip'
        local excess_deaths`statefip' = r(mean)
        local covid_pct`statefip' = 100*(`covid_deaths`statefip''/`excess_deaths`statefip'')
        matrix covid_excess_deaths = nullmat(covid_excess_deaths) \ (`covid_deaths`statefip'', `excess_deaths`statefip'', `covid_pct`statefip'')
        replace covid_compare_label = 1 if statefip == `statefip'
    }

    matrix_to_txt, saving(${output_tables_path}/covid_excess_deaths.txt) ///
        mat(covid_excess_deaths) format(%10.2f)  title(<tab:covid_excess_deaths>) replace

    * Scatter excess deaths vs. COVID deaths by state
    twoway (scatter covid_mortality mortality_excess_trend if incomplete_data == 0 & covid_compare_label == 0, mcolor(gray) msize(small)) ///
        (scatter covid_mortality mortality_excess_trend if incomplete_data == 0 & covid_compare_label == 1, mlabcolor(black) mlabsize(small) mlabposition(8) mlabel(statefip_code) mcolor(blue) msize(small) msymbol(o)) ///
        (lfit covid_mortality mortality_excess_trend, lcolor(red)) ///
        (line mortality_excess_trend mortality_excess_trend if incomplete_data == 0, lcolor(black)), ///
        scheme(s1mono) xtitle("Excess Mortality") ytitle("") ylabel(-1(5)14, angle(0)) ///
        xlabel(-1(5)14) xsc(r(-1 14)) ysc(r(-1 14)) legend(off) ///
        subtitle("COVID-19 Mortality (per 10,000) April 2020, All States", size(medium) position(11))
    graph export "${output_figures_path}/covid_mort_excess_mort_april2020.pdf", replace

    * COVID deaths only vs. economic damage by state scatter w slope
    reg covid_mortality emp_rate_excess_trend, r
    local slope = _b[emp_rate_excess_trend]
    local se = _se[emp_rate_excess_trend]
    twoway (scatter covid_mortality emp_rate_excess_trend if incomplete_data == 0 & label == 0, mcolor(gray) msize(small) msymbol(o)) ///
        (scatter covid_mortality emp_rate_excess_trend if incomplete_data == 0 & label == 1, mlabcolor(black) mlabsize(small) mlabposition(8) mlabel(statefip_code) mcolor(blue) msize(small) msymbol(o)) ///
        (lfit covid_mortality emp_rate_excess_trend if incomplete_data == 0, lcolor(red)), ///
        scheme(s1mono) xtitle("Excess Decline in Employment-Population Ratio") ytitle("") ylabel(, angle(0)) ///
        subtitle("COVID-19 Mortality (per 10,000)", size(medium) position(11)) ///
        note("Note: Omits `missing_num' states with < 90% of est. deaths recorded") ///
        legend(on order(- "Slope = `: di %6.3f `slope''" ///
        "            (`: di %6.3f `se'')") ///
        pos(2) ring(0) region(lp(solid)))
    graph export "${output_figures_path}/covid_mort_excess_economic_april2020.pdf", replace

    * Non-COVID excess deaths only vs. economic damage by state scatter w slope
    reg noncov_mort_excess emp_rate_excess_trend, r
    local slope = _b[emp_rate_excess_trend]
    local se = _se[emp_rate_excess_trend]
    twoway (scatter noncov_mort_excess emp_rate_excess_trend if incomplete_data == 0 & label == 0, mcolor(gray) msize(small)) ///
        (scatter noncov_mort_excess emp_rate_excess_trend if incomplete_data == 0 & label == 1, mlabcolor(black) mlabsize(small) mlabposition(8) mlabel(statefip_code) mcolor(blue) msize(small) msymbol(o)) ///
        (lfit noncov_mort_excess emp_rate_excess_trend if incomplete_dat == 0, lcolor(red)), ///
        scheme(s1mono) xtitle("Excess Decline in Employment-Population Ratio") ytitle("") ylabel(, angle(0)) ///
        subtitle("Non-COVID Excess Mortality (per 10,000)", size(medium) position(11)) ///
        note("Note: Omits `missing_num' states with < 90% of est. deaths recorded") ///
        legend(on order(- "Slope = `: di %6.3f `slope''" ///
        "            (`: di %6.3f `se'')") ///
        pos(2) ring(0) region(lp(solid)))
    graph export "${output_figures_path}/noncov_mort_excess_economic_april2020.pdf", replace
end

program label_states
    gen label = 0
    local samp "statefip"
    gen `samp'_code = ""
    replace label = 1 if statefip == 34
    replace label = 1 if statefip == 26
    replace label = 1 if statefip == 36
    replace label = 1 if statefip == 15
    replace label = 1 if statefip == 32
    replace label = 1 if statefip == 22
    replace label = 1 if statefip == 11
    replace label = 1 if statefip == 17
    replace label = 1 if statefip == 6
    replace label = 1 if statefip == 25
    replace label = 1 if statefip == 37
    replace label = 1 if statefip == 2

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
end

* EXECUTE
main
