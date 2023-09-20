
***STATA codes example for calculating weighted Charlson's Comorbidity Index using data from the National Patient Register***
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

*******************************************************************************
***Working with the patient registers for Charlson's comorbidity index (CCI)***
*******************************************************************************
** CCI calculation was based on Ludvigsson et al. paper: "Adaptation of the Charlson Comorbidity Index for Register-Based Research in Sweden"
** DOI: 10.2147/CLEP.S282475

global workdir "D:/Survival_working/SoS/28421_2020_Lev/STATA files/"

**Working OV outpatient register
use "${workdir}t_t_s_r_par_ov_28421_2020.dta", clear

// codebook DIA21-DIA30
// there was no data from DIA21-DIA30, so they are dropped 

keep LopNr hdia INDATUMA DIA1-DIA20 FODDAT
gen newid =_n
// the new unique newid was created to reshape long form 
rename hdia DIA0
// DIA0 or 0 is main specific diagnosis
compress
// compress data because reshape takes time for large dataset 
* changing wide to long data form
reshape long DIA, i (newid) j(dia_num)
// be patient. this reshape my take time
tab DIA, missing

*remove space in DIA as some cells had many space
gen dia= strrtrim(DIA)
gen test= regexm(dia,"^([A-Z]|[0-9])")
tab test, missing
// this was done to remove missing cells and troublesome cells 
keep if test==1 
drop test DIA newid

gen register="ov"
order dia_num, after(dia)
gen indatuma=date(INDATUMA,"YMD")
format %tdCCYY-NN-DD indatuma
label variable indatuma "INDATUMA:besöksdatum"
order indatuma, before(dia)
drop INDATUMA
label variable dia "diagnosis"
label variable dia_num "diagnosis number: 0 is main diagnosis"
label variable register "ov or sv"

save "${workdir}ov_extract.dta", replace

**Working SV hospital register

use "${workdir}t_t_s_r_par_sv_28421_2020.dta", clear
// codebook DIA1-DIA30
// there was ICD data in DIA1-DIA30. So no need to drop 

keep LopNr hdia INDATUMA DIA1-DIA30 FODDAT
gen newid =_n
// the new unique newid was created to reshape long form 
rename hdia DIA0
// DIA0 or 0 is main specific diagnosis
compress
// compress data because reshape takes time for large dataset 
* changing wide to long data form
reshape long DIA, i (newid) j(dia_num)
// be patient. this reshape my take time
tab DIA, missing

*remove space in DIA as some cells had many space
gen dia= strrtrim(DIA)
gen test= regexm(dia,"^([A-Z]|[0-9])")
tab test, missing
// this was done to remove missing cells and troublesome cells 
keep if test==1 
drop test DIA newid

gen register="sv"
order dia_num, after(dia)
gen indatuma=date(INDATUMA,"YMD")
format %tdCCYY-NN-DD indatuma
label variable indatuma "INDATUMA:besöksdatum"
order indatuma, before(dia)
drop INDATUMA
label variable dia "diagnosis"
label variable dia_num "diagnosis number: 0 is main diagnosis"
label variable register "ov or sv"

save "${workdir}sv_extract.dta", replace

**Appending ov_extract with sv_extract*
use "${workdir}ov_extract.dta", clear
append using "${workdir}sv_extract.dta"
sort LopNr


*Adding diagnosis date from SCRCR register
preserve
use "${workdir}Primiary_crc_SCRCR.dta",clear
keep LopNr dia_date2 op_date
tempfile temp
save `temp'
restore

merge m:1 LopNr using `temp'
order dia_date2 op_date, after(indatuma)
keep if _merge==3
drop _merge

save "${workdir}ov_sv_extract.dta", replace
*******************************************
**calculating CCI during the study period or before diagnosis**
*******************************************
use "${workdir}ov_sv_extract.dta", clear

codebook indatuma
bro if indatuma < date("20050101","YMD")
drop if indatuma < date("20050101","YMD")
//68 obs whose indatuma is out of the study period are removed
drop if indatuma==. 
//droping 130 obs whose indatuma is missing or incomplete

*CCI before diagnosis
bro if indatuma >= dia_date2
drop if indatuma >= dia_date2
// selecting comorbidities before CRC diagnosis

/*CCI within 5 year time before diagnosis

codebook indatuma
drop if indatuma >= dia_date2
// selecting comorbidities before CRC diagnosis

bro if (dia_date2-indatuma)>(365.25*5)
drop if (dia_date2-indatuma)>(365.25*5)
// selecting comorbidities 0-5 yr before CRC diagnosis

*/

/*CCI within 10 year time before diagnosis

codebook indatuma
drop if indatuma >= dia_date2
// selecting comorbidities before CRC diagnosis

bro if (dia_date2-indatuma)>(365.25*10)
drop if (dia_date2-indatuma)>(365.25*10)
// selecting comorbidities 0-10 yr before CRC diagnosis

*/

/* Preoperative CCI for paper 03

*CCI before operation
codebook indatuma
bro if indatuma >= op_date
drop if indatuma >= op_date
// selecting comorbidities before operation

*/

/*CCI within 0-5 year time before operation for paper 03
********************************************************
codebook indatuma
bro if indatuma >= op_date
drop if indatuma >= op_date
// selecting comorbidities before operation

bro if (op_date-indatuma)>(365.25*5)
drop if (op_date-indatuma)>(365.25*5)

// selecting comorbidities 0-5 yr before operation

*CCI within 0-10 year time before operation for paper 03
*******************************************************
codebook indatuma
bro if indatuma >= op_date
drop if indatuma >= op_date
// selecting comorbidities before operation

bro if (op_date-indatuma)>(365.25*10)
drop if (op_date-indatuma)>(365.25*10)

// selecting comorbidities 0-10 yr before operation

*/

by LopNr dia, sort: gen dup_dia=cond(_N==1,0,_n)
// identifying duplicates in groups 0 and 1 are uniques , 2=2 duplicates 
label variable dup_dia "duplicated diagnosis"
drop if dup_dia>1
//droping duplicated ICD codes
tab dup_dia, missing
drop dup_dia
// 0 and 1 are uniqued dia (2 and above are duplicates )
sort LopNr indatuma dia

*Checking CRC cases (C18,C19,C20),at current data format, and non-melanoma skin cancer (C440-C449)
gen crc_nms=cond(regexm(dia,"^(C18|C19|C20)"),1, cond(regexm(dia,"^C44"),2,0))
tab crc_nms,missing
keep if crc_nms==0
//droping CRC and non-melanoma skin cancer diagnosis
drop crc_nms


**Charlson comorbidity index // with updated ICD codes
*************************************
*1.Myocardial infarction
gen ch1=cond(regexm(dia,"^(I21|I22|I252)"),1,0)
//subtypes are also included. So, $ is not included
*2.Congestive heart failure
gen ch2=cond(regexm(dia,"^(I11|I110|I13|I130|I132|I255|I42|I420|I426|I427|I428|I429|I43.*|I50.*)$"),1,0)
*3.Peripheral vascular disease
gen ch3=cond(regexm(dia,"^(I70|I71|I731|I738|I739|I771|I790|I792|K55)"),1,0)
*4.Cerbrovascular disease
gen ch4=cond(regexm(dia,"^(G45|I60|I61|I62|I63|I64|I67|I69)"),1,0)
//subtypes are also included. So, $ is not included
*5.Chronic obstructive pulmonary disease
gen ch5=cond(regexm(dia,"^(J43|J44)$"),1,0)
*6.Chronic other pulmonary disease
gen ch6=cond(regexm(dia,"^(J41|J42|J45.*|J46|J47|J60|J61|J62|J63|J64|J65|J66|J67|J68|J684|J69|J70)$"),1,0)
*7.Rheumatic disease
gen ch7=cond(regexm(dia,"^(M05|M06.*|M123|M070|M071|M072|M073|M08|M13.*|M30|M313|M314|M315|M316|M32|M33|M34|M35|M350.*|M351|M353|M45|M46)$"),1,0)
*8.Dementia 
gen ch8=cond(regexm(dia,"^(F00|F01|F02|F03|F051|G30|G311|G319)$"),1,0)
*9.Hemiplegia
gen ch9=cond(regexm(dia,"^(G114|G80|G81|G82|G830|G831|G832|G833|G838)$"),1,0)
*10.Diabetes_without_chronic_complication
gen ch10=cond(regexm(dia,"^(E100|E101|E110|E111|E120|E121|E130|E131|E140|E141)"),1,0)
//subtypes are also included eg.E100A,E100C,E100D.So, $ is not included
*11.Diabetes_with_chronic_complication
gen ch11=cond(regexm(dia,"^(E102|E103|E104|E105|E107|E112|E113|E114|E115|E116|E117|E122|E123|E124|E125|E126|E127|E132|E133|E134|E135|E136|E137|E142|E143|E144|E145|E146|E147)"),1,0)
//subtypes are also included eg.E102A,E102B,E102C,E102X.So, $ is not included
*12.Moderate/severe kidney disease
gen ch12=cond(regexm(dia,"^(I12|I120|I131|N032|N033|N034|N035|N036|N037|N052|N053|N054|N055|N056|N057|N11|N18|N19|N250|Q611|Q612|Q613|Q614|Z49|Z940|Z992)$"),1,0)
*13.Mild liver disease
gen ch13=cond(regexm(dia,"^(B15|B16|B17|B18|B19|K703|K709|K73|K746|K754)$"),1,0)
*14.Liver special
gen ch14=cond(regexm(dia,"^(R18)$"),1,0)
*15.Moderate/severe liver disease
gen ch15=cond(regexm(dia,"^(I850|I859|I982|I983)$"),1,0)
*16.Peptic ulcer disease
gen ch16=cond(regexm(dia,"^(K25|K26|K27|K28)$"),1,0)
*17.Malignancy
gen ch17=cond(regexm(dia,"^(C00|C01|C02|C03|C04|C05|C06|C07|C08|C09|C10|C11|C12|C13|C14|C15|C16|C17|C18|C19|C20|C21|C22|C23|C24|C25|C26|C27|C28|C29|C30|C31|C32|C33|C34|C35|C36|C37|C38|C39|C40|C41|C42|C43|C44|C45|C46|C47|C48|C49|C50|C51|C52|C53|C54|C55|C56|C57|C58|C59|C60|C61|C62|C63|C64|C65|C66|C67|C68|C69|C70|C71|C72|C73|C74|C75|C76|C77|C78|C79|C80|C81|C82|C83|C84|C85|C86|C88|C89|C90|C91|C92|C93|C94|C95|C96|C97)$"),1,0)
*18.Metastatic cancer
gen ch18=cond(regexm(dia,"^(C77|C78|C79|C80)$"),1,0)
*19.AIDS
gen ch19=cond(regexm(dia,"^(B20|B21|B22|B23|B24|F024|O987|R75|Z114|Z219|Z711)$"),1,0)

* Drop patients with 0 comorbidities (not necessary, just to speed up process)
******************************************************************************
egen rmax = rowmax(ch1-ch19)
tab rmax, missing
drop if rmax == 0
// dropping 14,122 observations with no comorbidities
drop rmax

* Set 0/1 per disease on patient level
**************************************
forvalues i=1/19{
egen ch = max(ch`i' & ch`i' < .), by(LopNr)
replace ch`i' = ch
drop ch
}
//"egen ch = max(ch`i' & ch`i' < .), by(group)" is take max number and put 0 if the values are missing


* Keep first observation per patient
bys LopNr: keep if _n == 1
* Set correct liver disease
 quietly replace ch15=1  if ch13>0 & ch14>0
 quietly replace ch13=0 if ch15>0
* Set correct diabetes disease
 quietly replace ch10=0  if ch11>0
* Set correct cancer disease
 quietly replace ch17=0  if ch18>0
 
* Give names to variables
************************* 
label var ch1 "AMI (Acute Myocardial)"
label var ch2 "CHF (Congestive Heart)"
label var ch3 "PVD (Peripheral Vascular)"
label var ch4 "CEVD (Cerebrovascular"
label var ch5 "COPD (Chronic Obstructive Pulmonary)"
label var ch6 "CP (Chronic Other Pulmonary)"
label var ch7 "Rheumatoid Disease"
label var ch8 "Dementia"
label var ch9 "HP/PAPL (Hemiplegia or Paraplegia)"
label var ch10 "Diabetes"
label var ch11 "Diabetes + Complications"
label var ch12 "RD (Renal)"
label var ch13 "Mild LD (Liver)"
label var ch15 "Moderate/Severe LD (Liver)"
label var ch16 "PUD (Peptic Ulcer)"
label var ch17 "Cancer"
label var ch18 "Metastatic Cancer"
label var ch19 "AIDS"
***************************** 
* Assign weights per disease
*****************************
 quietly replace ch9=2  if ch9>0
 quietly replace ch11=2 if ch11>0
 quietly replace ch12=2 if ch12>0
 quietly replace ch15=3 if ch15>0
 quietly replace ch17=2 if ch17>0
 quietly replace ch18=6 if ch18>0
 quietly replace ch19=6 if ch19>0
*******************
* Compute Charlson Commobidity Index
******************* 
 drop ch14
 egen cci_dia = rsum(ch1-ch19)
label variable cci_dia "charlson index b4 diagnosis in study period"


/*
**For cci_05yr
rename cci_dia cci_5
label variable cci_5 "charlson index 5yr before diagnosis"
tab cci_5, missing

save "${workdir}cci_05yr.dta", replace

*/

/*
**For cci_10yr
rename cci_dia cci_10
label variable cci_10 "charlson index 10yr before diagnosis"
tab cci_10, missing

save "${workdir}cci_10yr.dta", replace

*/

/*
**For cci_op (preoperative CCI)
rename cci_dia cci_op
label variable cci_op "CCI before operation"
tab cci_op, missing

save "${workdir}cci_op.dta", replace
// CCI is preoperative for paper 03
*/

/*
**For cci_op_5 (preoperative CCI within 0-5 yr)
rename cci_dia cci_op_5
label variable cci_op_5 "CCI 0-5 yrs before operation"
tab cci_op_5, missing

save "${workdir}cci_op_05yr.dta", replace
// CCI is preoperative witin 0-5 yr for paper 03
*/

/*
**For cci_op_10 (preoperative CCI within 0-10 yr)
rename cci_dia cci_op_10
label variable cci_op_10 "CCI 0-10 yrs before operation"
tab cci_op_10, missing

save "${workdir}cci_op_10yr.dta", replace
// CCI is preoperative witin 0-10 yr for paper 03
*/


tab cci_dia, missing
save "${workdir}cci_b4_dia_t.dta", replace
// this is prediagnostic CCI for paper 02
