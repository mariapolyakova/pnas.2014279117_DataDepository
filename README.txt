This repository contains code and data to replicate the exhibits in "Initial economic damage from the COVID-19 pandemic in the United States is more widespread across ages and geographies than initial mortality impacts" by Maria Polyakova, Geoffrey Kocks, Victoria Udalova, and Amy Finkelstein.

The code folder contains code that both processes raw data and analyzes the data to produce exhibits for the paper. 

The data folder is empty and the code that processes raw data will deposit intermediate data into this folder.

The raw data folder is empty and you must populate it with publicly available raw data from the CDC, the CPS, the OI Economic Tracker, the NYTimes, the BLS, and the Census.

These are the raw data that must be deposited in ../raw
------------------------------------------------------

-- CDC Deaths (last month of data should be April 2020)
    CDC Excess deaths downloaded from:
    https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm
    Date: 7/1/2020
    File(s): 
        -- Excess_Deaths_Associated_with_COVID-19.csv 

    State level deaths 2015-2020 downloaded from:
    https://data.cdc.gov/NCHS/Weekly-counts-of-death-by-jurisdiction-and-cause-o/u6jv-9ijr/
    Date: 6/10/2020
    File(s):
        -- Weekly_counts_of_death_by_jurisdiction_and_cause_of_death.csv

    Age group deaths 2015-2020 downloaded from: 
    https://data.cdc.gov/NCHS/Weekly-counts-of-deaths-by-jurisdiction-and-age-gr/y5bj-9g5w/
    Date: 7/1/2020
    Files(s):
        -- Weekly_counts_of_deaths_by_jurisdiction_and_age_group.csv

    Race and Hispanic origin deaths 2015-2020 downloaded from: 
    https://data.cdc.gov/NCHS/Weekly-counts-of-deaths-by-jurisdiction-and-race-a/qfhf-uhaa
    Date: 7/29/2020
    Files(s): 
        -- Weekly_counts_of_deaths_by_jurisdiction_and_race_and_Hispanic_origin.csv

    Old data files:
    State level deaths 2014-2018 downloaded from:
    https://data.cdc.gov/NCHS/Weekly-Counts-of-Deaths-by-State-and-Select-Causes/3yf8-kanr
    Date: 6/11/2020
    File(s):
        -- Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2018.csv

    State level deaths 2019-2020 downloaded from: 
    https://data.cdc.gov/NCHS/Weekly-Counts-of-Deaths-by-State-and-Select-Causes/muzy-jte6
    Date: 7/1/2020
    File(s):
        -- Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2019-2020.csv

    State level monthly deaths 2011-2018 downloaded from CDC Wonder Database
    State level monthly influenza and pneumonia deaths have codes J10-J18 in underlying cause.
    Alzheimer's have code G30 in underlying cause 
    Chronic lower respiratory: J40-J47
    Cerebrovascular: I60-I69
    Cancer: C00-C97
    Diabetes: E10-E14
    Heart diseases: I00-I09, I11, I13, I20-I51
    External causes: V01-Y89 
    File(s):
        -- CAUSE_Death_2011-2018.txt (where CAUSE is one of the specific causes of deaths we look at: Alzheimers, Cancer, Diabetes, External_Cause, Heart_Diseases, Mutliple_Cause_of)

-- Census Population Estimate Data
    For the denominator of mortality we use census population estimates.

    https://www.census.gov/newsroom/press-kits/2019/national-state-estimates.html
    
    Census Anual Population Estimates by State 2011-2019 (NST-EST2019-01)
        File: census_annual_pop_estimates_state_2019_ManuallyCleaned.xlsx
    Monthly Population Estimates for the United States: April 1, 2010 to December 1, 2020 (NA-EST2019-01)
        File: census_monthly_pop_estimates_2019_vintage_ManuallyCleaned.xlsx
    Census Population Estimates by sex and age 2011-2019 (NC-EST2019-AGESEX-RES)
        File: nc-est2019-agesex-res.csv


-- CPS data from IPUMS
    download separate datasets for:
    Jan. 2005 through Dec. 2008
    Jan. 2009 through Dec. 2012
    Jan. 2013 through Dec. 2016
    Jan-Dec. 2017
    Jan-Dec. 2018
    Jan-Dec. 2019
    Jan-Apr. 2020

    The following data fields were downloaded when available:
    *Household technical
    *Household geographic
    *Household economic characteristics
    *Person demographics
    *Person work
    *Person education
    *Person earner study 

    File(s):
        -- cps_month1_year1_month2_year2.dta (for data that span multiple years)
        -- cps_month1-month2_year1.dta (for data that span a single year)    

-- BLS Unemployment Statistics 
    Aggregate unemployment statistics from the BLS downloaded May 11, 2020.
    Individual 16 and older.

    Dates: Jan 2005-April 2020
    Adjusted datasets are seasonally adjusted while unadjusted datasets are not.

    Link: https://www.bls.gov/webapps/legacy/cpsatab1.html

    File(s):
        -- X_Adj.xlsx
        -- X_Unadj.xlsx
        where X = Emp, EmpRatio, LaborForce, ParticRate, Population, Unemployment_Level, Unemployment_Rate


-- UI Claims
    State and national nemployment insurance claims January 2011 - April 2020
    Includes:
    * number of new UI claims (not seasonally adjusted)
    * number of continued UI claims (not seasonally adjusted) 
    * insured unemployment rate (not seasonally adjusted) 
    * week ending date (lined up with the reference week for that month's CPS)

    Demographic data by month downloaded here: https://oui.doleta.gov/unemploy/chariu.asp with codebook attached as a PDF

    https://oui.doleta.gov/unemploy/claims.asp

    File(s):
        -- Demographics_UI_Apr2020.csv
        -- National_UI_Jan2011_Apr2020.csv
        -- State_UI_Jan2011_Apr202.csv

-- NYTimes COVID Deaths 
    the file us-states.txt shows COVID cases and deaths by state and day from the New York Times, which aggregates reports from state and local health agencies. 

    See repository here: https://github.com/nytimes/covid-19-data
    Downloaded: 6/15/2020

    Cases: Total number of COVID-19 cases, both confirmed and probable
    Deaths: Total number of COVID-19 deaths, both confirmed and probable

    See the repository for descriptions of geographies and irregularities in counts. Some states only report confirmed cases while others report confirmed and probable cases. 

    File(s):
        -- us-states.txt

-- Opportunity Insights COVID Tracker 
    COVID Economic Variables Manually Entered from Opportunity Insights Tracker
    Link: https://tracktherecovery.org/

    All variables are entered as of 4/15/2020 (based on values in the state-level graphs).

    1) Employment Rates in Small Businesses:
    *Percent change relative to January 2020
    *Derived from Homebase data, which primarily includes food, retail, and services
    *Constructed based on 7 day moving average; divide by mean in January and subtract from 1

    2) Consumer Spending:
    *Percent change relative to January 2020
    *Based on credit and debit card data from Affinity Solutions (data from producer side)
    *Seven day moving average and seasonally adjusted; divide by seasonally adjusted mean in January and subtract from 1

    File(s):
        -- OI_Tracker_Variables_April15.csv


The code folder contains the following Stata .do files
-------------------------------------------------------
-- Code that processes raw data 
--------------------------------
** Note: Please run these files in the order that they appear. You must first download raw data.
    -- derived_cps_employment_measures 
        -- this code takes in raw data from the CPS. It appends files from the CPS from 2005 through 2020. See the construct_cps_measures program for the specific years that this code requires. It then saves monthly and individual level cps data from 2005 through 2020 the ../data folder. 
    -- derived_cdc_excess
        -- this code takes in raw data from CDC Wonder on deaths (multiple cause of deaths) from 2011 through 2018, on excess deaths associated with COVID-19, and weekly deaths by jurisdiction and age group. 
    -- CDC_mortality_damage 
        -- this code takes in raw data from the census on monthly population estimates (nationally and at the state level and by age group). It also takes in raw data on covid deaths from the nytimes. It takes in weekly counts of COVID deaths by state from the CDC. It also takes in data from CDC wonder on deaths (multiple cause of deaths) by age and ovearll from 2011 to 2018 and weekly counts of deahts by jurisdiction and age group. 
        -- this code uses the raw data to construct excess mortality 
    -- CDC_mortality_category_damage
        -- this code is analogous to CDC_mortality_damage, except it looks at specific causes of deaht like heart disease and unnatural causes. It uses raw data from the CDC on these specific causes of death. This code is only needed to later create supplemental exhibits. 
    -- CPS_economic_damage
        -- this code takes in processed raw data from derived_cps_employment_measures. It uses this data to create excess employment measures. 
-- Code that performs analysis
--------------------------------
** Note: These files must be run after the code that processes the raw data completes. They can be run in any order. 
    -- agg_cdc_cps_exhibits.do
        -- This file creates all main exhibits in the paper. 
    -- benchmark_cdc_data.do 
        -- This file creates supplemental exhibits that compare COVID mortality with economic damage and excess mortality. 
            It also produces a state-level exhibit comparing CDC excess mortality and trend excess mortality. 
    -- benchmark_cps_data.do 
        -- Creates supplemental exhibits that correlate various economic measures to evaluate the CPS data quality
    -- cdc_death_categories_exhibits.do
        -- Creates supplemental exhibits that examine mortality by cause of death (e.g., heart disease, unnatural causes, cancer, etc).
