
************************************************************************************************************************
***STATA Code Example for Kaplan-Meier survival curve, Proportional-Hazard assumption tests and Cox regression models***
************************************************************************************************************************
global workdir "C:STATA files\"
use "${workdir}antibiotic_survival_1-3stage_20220915.dta",clear

******************************************
***KM survival curves and log-rank tests 
******************************************
***Antibiotics(5-category) and overall survival 
*declare survival set data 
stset sv_year, failure(outcome_all)
**1yr-washout
sts graph, by (anti_1)  ylabel(0(.20)1)
// K-M curve
sts test anti_1
// log-rank test


***Antibiotics(5-category) and CRC-related survival 
*declare survival set data 
stset sv_year, failure(outcome_crc)
**1yr-washout
sts graph, by (anti_1)  ylabel(0.5(.10)1)
// K-M curve
sts test anti_1
// log-rank test


**************************************
***Cox proportional-hazard models*****
**************************************

***Propotional Hazard assumption tests for adjusted model 2 (preferred model): Overall and CRC specific model***

stset sv_year, failure(outcome_all)
*Schoenfeld residual
quietly stcox i.anti_1 kon alder_vid_dia birth_place edu_dia county_dia civil_dia income_dia fh_crc2_grp cci_dia stage tum_main calendar_yr ,schoenfeld(sch*) scaledsch(sca*) 
stphtest, detail
drop sch* sca*

stset sv_year, failure(outcome_crc)
*Schoenfeld residual
quietly stcox i.anti_1 kon alder_vid_dia birth_place edu_dia county_dia civil_dia income_dia fh_crc2_grp cci_dia stage tum_main calendar_yr ,schoenfeld(sch*) scaledsch(sca*) 
stphtest, detail
drop sch* sca*

quietly stcox anti_1 kon alder_vid_dia birth_place edu_dia county_dia civil_dia income_dia fh_crc2_grp cci_dia stage tum_main calendar_yr ,schoenfeld(sch*) scaledsch(sca*) 
stphtest, plot(anti_1) msym(oh)
stphtest, plot(alder_vid_dia) msym(oh)
stphtest, plot(cci_dia) msym(oh)
stphtest, plot(stage) msym(oh)
stphtest, plot(tum_main) msym(oh)
*Log-log plot : 
stphplot, by(anti_1) plot1(msym(oh)) plot2(msym(th))
drop sch* sca*

****Stratifed Cox regression model****

**Adjusted model 2: adjusted for gender, age as continuous, birth country, education, county, marital status, income, family history, prediagnostic CCI as continuous, calander period and stratified by CCI (bicategory), tumor sites,stage, ear_onset, family history (preferred model)

**Using bicategory
tab anti_1_bi outcome_all, row
tab anti_1_bi outcome_crc, row
*overall survival: 1yr-washout
stset sv_year, failure(outcome_all)
eststo: stcox i.anti_1_bi i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia i.civil_dia i.income_dia i.fh_crc2_grp cci_dia dia_yr, strata (cci_dia_bi tum_main stage ear_onset fh_crc2_grp)
*crc-specific survival: 1yr-washout
stset sv_year, failure(outcome_crc)
eststo: stcox i.anti_1_bi i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia i.civil_dia i.income_dia i.fh_crc2_grp cci_dia dia_yr, strata (cci_dia_bi tum_main stage ear_onset fh_crc2_grp)
esttab, b(2) ci(2) label eform nodepvar nogaps wide brackets one
eststo clear

**Using 5-categories
tab anti_1 outcome_all, row
tab anti_1 outcome_crc, row
*overall survival: 1yr-washout
stset sv_year, failure(outcome_all)
eststo: stcox i.anti_1 i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia i.civil_dia i.income_dia i.fh_crc2_grp cci_dia dia_yr, strata(cci_dia_bi tum_main stage ear_onset fh_crc2_grp)
*crc-specific survival: 1yr-washout
stset sv_year, failure(outcome_crc)
eststo: stcox i.anti_1 i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia i.civil_dia i.income_dia i.fh_crc2_grp cci_dia dia_yr, strata(cci_dia_bi tum_main stage ear_onset fh_crc2_grp)
esttab, b(2) ci(2) label eform nodepvar nogaps wide brackets one
eststo clear

*goodness of fit test for the adjusted model 2 in Overall survival: Cox-snell residuals
stset sv_year, failure(outcome_all)
quietly stcox i.(anti_1 kon birth_place edu_dia county_dia civil_dia income_dia fh_crc2_grp) cci_dia alder_vid_dia dia_yr , strata( cci_dia_bi tum_main stage ear_onset fh_crc2_grp) nohr mgale(mg)
predict cs, csnell

stset cs, failure(outcome_all)
sts generate H = na
line H cs cs, sort xlab(0 1 to 5) ylab(0 1 to 5)
drop mg
drop cs H

*goodness of fit test for the adjusted model 2 in CRC-specific survival: Cox-snell residuals
stset sv_year, failure(outcome_crc)
quietly stcox i.(anti_1 kon birth_place edu_dia county_dia civil_dia income_dia fh_crc2_grp) cci_dia alder_vid_dia dia_yr , strata( cci_dia_bi tum_main stage ear_onset fh_crc2_grp) nohr mgale(mg)
predict cs, csnell

stset cs, failure(outcome_crc)
sts generate H = na
line H cs cs, sort xlab(0 1 to 3) ylab(0 1 to 3)
drop mg
drop cs H
