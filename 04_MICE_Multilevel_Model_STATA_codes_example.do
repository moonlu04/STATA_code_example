*******************************************************************************************************************************************************************************
****STATA code example for multiple imputation of missing data, logistic regression with multi-level mixed-effects model, non-linearity test using restricted cubic splines****
*******************************************************************************************************************************************************************************

*****Multiple Imputation by Chain Equation with 10 imputed datasets*****
************************************************************************ 

***Saving imputed data for colon and rectum seperately to save time***
*********************************************************************
global workdir  "C:/Data_working/"
use "${workdir}anti_complication_all_stage_master_20230316.dta", clear


*Colon imputed dataset
**********************
preserve	
keep if tum_main1==1

mdesc stage_miss tum_main_miss asa bmi A2_blodn1

mi set mlong
mi misstable summarize stage_miss tum_main_miss asa bmi A2_blodn1
mi misstable patterns stage_miss tum_main_miss asa bmi A2_blodn1

mi register imputed stage_miss tum_main_miss asa bmi A2_blodn1

mi impute chained (ologit) asa stage_miss (mlogit) tum_main_miss (regress) bmi A2_blodn1 = inf_sur_komp anti_op0_5 kon alder_vid_dia birth_place edu_dia county_dia  cci_op_5 dia_yr A2_precyt2 A2_prestral2 A2_optyp1 A2_optyp2 A2_lapa2 de_stoma anas A0_opsjhkod2, add (10) rseed (12345)

save "${workdir}anti_complication_all_stage_master_colon_mi_20230316.dta", replace
// saving imputed dataset for colon : use this file to save time for imputation
restore


*Rectum imputed dataset
***********************
preserve	
keep if tum_main1==2

mdesc stage_miss tum_main_miss asa bmi A2_blodn1

mi set mlong
mi misstable summarize stage_miss asa bmi A2_blodn1
mi misstable patterns stage_miss asa bmi A2_blodn1

mi register imputed stage_miss asa bmi A2_blodn1

mi impute chained (ologit) asa stage_miss (regress) bmi A2_blodn1 = inf_sur_komp anti_op0_5 kon alder_vid_dia birth_place edu_dia county_dia cci_op_5 dia_yr A2_precyt2 A2_prestral2  A2_optyp2 A2_lapa2 de_stoma anas A0_opsjhkod2 tum_height, add (10) rseed (12345)

save "${workdir}anti_complication_all_stage_master_rectum_mi_20230316.dta", replace
// saving imputed dataset for rectum : use this file to save time for imputation

restore
///////////////////////////////////////////////////////////////////


*****Multilevel mixed-effect model****
**************************************
*************************************
global workdir  "C:/Data_working/"

*Colon: Inf_surgical complications (multiple imputation)
********************************************************

**use colon imputed dataset for analysis 
use "${workdir}anti_complication_all_stage_master_colon_mi_20230316.dta", clear

preserve	

local covariate1 i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.tum_main_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp1 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1

mi estimate, cmdok or post:melogit inf_sur_komp i.anti_op0_5 `covariate1', || A0_opsjhkod2:
eststo
esttab, b(2) ci(2) label eform nodepvar nogaps wide one
eststo clear

*p-trend
mi estimate, cmdok or :melogit inf_sur_komp anti_op0_5 `covariate1', || A0_opsjhkod2:

*using binary yes/no
mi estimate, cmdok or :melogit inf_sur_komp anti_op0_5_bi `covariate1', || A0_opsjhkod2:


*Interaction by sex 
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.tum_main_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp1 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1, || A0_opsjhkod2:

*Interaction by age
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##c.alder_vid_dia i.kon  i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.tum_main_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp1 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1, || A0_opsjhkod2:

*Interaction by leadtime
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##c.dia_op_month c.alder_vid_dia i.kon  i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.tum_main_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp1 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1, || A0_opsjhkod2:

*Interaction by calendar_year of diagnosis
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##c.dia_yr c.alder_vid_dia i.kon  i.birth_place i.edu_dia i.county_dia cci_op_5 i.stage_miss i.tum_main_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp1 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1, || A0_opsjhkod2:

restore


*Rectum: Inf_surgical complications (multiple imputation)
***********************************************************

**use rectum imputed dataset for analysis 
use "${workdir}anti_complication_all_stage_master_rectum_mi_20230316.dta", clear

preserve	

local covariate2 i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1 i.tum_height


mi estimate, cmdok or post:melogit inf_sur_komp i.anti_op0_5 `covariate2', || A0_opsjhkod2:
eststo
esttab, b(2) ci(2) label eform nodepvar nogaps wide parentheses one
eststo clear

*p-trend
mi estimate, cmdok or :melogit inf_sur_komp anti_op0_5 `covariate2', || A0_opsjhkod2:

*binary yes/no
mi estimate, cmdok or :melogit inf_sur_komp anti_op0_5_bi `covariate2', || A0_opsjhkod2:


*interaction by sex
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1 i.tum_height, || A0_opsjhkod2:

*interaction by age
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##c.alder_vid_dia i.kon i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1 i.tum_height, || A0_opsjhkod2:

*interaction by leadtime
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##c.dia_op_month alder_vid_dia i.kon i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1 i.tum_height, || A0_opsjhkod2:

*interaction by calendar_year of diagnosis
mi estimate, cmdok or :melogit inf_sur_komp i.anti_op0_5_bi##c.dia_yr alder_vid_dia i.kon i.birth_place i.edu_dia i.county_dia cci_op_5 i.stage_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1 i.tum_height, || A0_opsjhkod2:

restore

/////////////////////////////////////


***Non-linearity test : inf-related surgical complications***
*************************************************************
*cubic spline using mkspline (reading)
* use http://nicolaorsini.altervista.org/data/pa_luts, clear
// stata journal data example

**colon

global workdir  "C:/Data_working/"
use "${workdir}anti_complication_all_stage_master_20230316.dta", clear

preserve	
keep if tum_main1==1

summarize sum_forpddd_op0_5,detail
mkspline antisp = sum_forpddd_op0_5, cubic knots(0 11.25 30 91.05) displayknots
// 4 knot points at 25% 50% 75% 95% of the data

mat knots = r(knots)
melogit inf_sur_komp antisp* i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.tum_main_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp1 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1, || A0_opsjhkod2:


testparm antisp2 antisp3

xbrcspline antisp , values(0 (10) 200) ref(0) eform matknots(knots) generate(pa or lb ub)

twoway (line lb ub pa, sort lc(black black) lp(- -))(line or pa, sort lc(black) lp(l)) if inrange(pa,0,200), legend(off) scheme(s1mono) xlabel(0(20)200) xmtick(0(10)200) ylabel(.8(.2)1.6, angle(horiz) format(%2.1fc)) yline(1,lstyle(grid)) ytitle("Odds ratio with 95% CI")xtitle("antibiotics use (days)")

drop pa-ub

restore

**Rectum
preserve	
keep if tum_main1==2

summarize sum_forpddd_op0_5,detail
mkspline antisp = sum_forpddd_op0_5, cubic knots(0 10 24.67 75) displayknots
// 4 knot points at 25% 50% 75% 95% of the data

mat knots = r(knots)
melogit inf_sur_komp antisp* i.kon alder_vid_dia i.birth_place i.edu_dia i.county_dia cci_op_5 dia_yr i.stage_miss i.A2_precyt2 i.A2_prestral2 i.A2_optyp2 i.A2_lapa2 i.de_stoma anas i.asa bmi A2_blodn1 i.tum_height, || A0_opsjhkod2:

test antisp2 antisp3

xbrcspline antisp , values(0 (10) 200) ref(0) eform matknots(knots) generate(pa or lb ub)

twoway (line lb ub pa, sort lc(black black) lp(- -))(line or pa, sort lc(black) lp(l)) if inrange(pa,0,200), legend(off) scheme(s1mono) xlabel(0(20)200) xmtick(0(10)200) ylabel(.8(.2)1.6, angle(horiz) format(%2.1fc)) yline(1,lstyle(grid)) ytitle("Odds ratio with 95% CI")xtitle("antibiotics use (days)")

drop pa-ub

restore

