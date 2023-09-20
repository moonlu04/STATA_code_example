

***STATA codes example for preprocessing socialeconomic data from LISA database and Total Population Register (RTB)***
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

******************************************************
*****Working with LISA and RTB datafiles *************
****************************************************** 
global workdir "D:/Survival_working/SCB/STATA_files/"

*importing LISA text files into STATA files
foreach name in "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" { 
 import delimited "D:/SCB/SH_Lev_LISA_20`name'.txt", case(preserve) encoding(ISO-8859-2) clear
 save "${workdir}SH_Lev_LISA_20`name'.dta",replace		
}

use "${workdir}SH_Lev_LISA_2018.dta",clear 
rename Sun2000niva_Old Sun2000niva_old
save "${workdir}SH_Lev_LISA_2018.dta",replace 

*renaming variables form LISA datafiles from 2005-2018
foreach name in "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" {
	use "${workdir}SH_Lev_LISA_20`name'.dta",clear 
	gen year= 20`name'
	label variable year "reported year"
	save "${workdir}SH_Lev_LISA_20`name'.dta",replace 
}

*Appending LISA datafiles from year 2005 to 2018
use "${workdir}SH_Lev_LISA_2005.dta",clear
forvalues i=2006/2018 { 
	sort LopNr
	append using "${workdir}SH_Lev_LISA_`i'.dta"
}
sort LopNr year
save "${workdir}SH_Lev_LISA_2005_2018.dta",replace


*importing RTB text files into STATA files
global workdir "D:/Survival_working/SCB/STATA_files/"

foreach name in "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" { 
 import delimited "D:/SCB/SH_Lev_RTB20`name'.txt", case(preserve) encoding(ISO-8859-2) clear
 save "${workdir}SH_Lev_RTB20`name'.dta",replace		
}

*renaming variables form RTB datafiles from 2005-2019
foreach name in "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" {
	use "${workdir}SH_Lev_RTB20`name'.dta",clear 
	gen year= 20`name'
	label variable year "reported year"
	save "${workdir}SH_Lev_RTB20`name'.dta",replace 
}

* Appending RTB datafiles from 2005 to 2019
use "${workdir}SH_Lev_RTB2005.dta",clear
forvalues i=2006/2019 { 
	sort LopNr
	append using "${workdir}SH_Lev_RTB`i'.dta"
}
sort LopNr year
save "${workdir}SH_Lev_RTB_2005_2019", replace

*Extracting LISA status at earliest, at latest, at diagnosis year and mean incomes *
*********************************************************************************
use "${workdir}SH_Lev_LISA_2005_2018", clear

*extracting dia_date2 from Primiary_crc_SCRCR.dta
preserve
use "D:/STATA files/Primiary_crc_SCRCR.dta",clear
keep LopNr dia_date2 op_date
// also keep for operation date 
gen dia_yr=year(dia_date2)
gen op_yr=year(op_date)

tempfile temp
save `temp'
restore

merge m:1 LopNr using `temp'
keep if _merge==3
drop _merge
order dia* op* year, after(LopNr)

*extracting the earliest LISA status
sort LopNr year
by LopNr: egen year_ear = min(year)
order year_ear, after(year)

gen Sun2000niva_old_ear=Sun2000niva_old if year_ear==year
bysort LopNr(year): replace Sun2000niva_old_ear=Sun2000niva_old_ear[1]

gen Sun2000niva_ear=Sun2000niva if year_ear==year
bysort LopNr(year): replace Sun2000niva_ear=Sun2000niva_ear[1]

gen DispInk04_ear=DispInk04 if year_ear==year
bysort LopNr(year): replace DispInk04_ear=DispInk04_ear[1]

gen DispInkFam04_ear=DispInkFam04 if year_ear==year
bysort LopNr(year): replace DispInkFam04_ear=DispInkFam04_ear[1]

*extracting the latest LISA status
sort LopNr year
by LopNr: egen year_late = max(year)
order year_late, after(year_ear)

gen Sun2000niva_old_late=Sun2000niva_old if year_late==year
gsort LopNr -year
by LopNr: replace Sun2000niva_old_late=Sun2000niva_old_late[1]

gen Sun2000niva_late=Sun2000niva if year_late==year
bysort LopNr(Sun2000niva_late): replace Sun2000niva_late=Sun2000niva_late[1]

gen DispInk04_late=DispInk04 if year_late==year
bysort LopNr(DispInk04_late): replace DispInk04_late=DispInk04_late[1]

gen DispInkFam04_late=DispInkFam04 if year_late==year
bysort LopNr(DispInkFam04_late): replace DispInkFam04_late=DispInkFam04_late[1]

*calculating mean incomes (it should be calculated before extraction of LISA status at diagnosis )

bysort LopNr(year): egen DispInk04_mean= mean(DispInk04)
bysort LopNr(year): egen DispInkFam04_mean= mean(DispInkFam04)

gen year1=year
label var year1 "for paper 03"
//IMPORTANT for calculating pre-operative LISA 

*extracting LISA status at diagnosis (IMPORTANT to remember there is no LISA data for 2019)
sort LopNr year
bysort LopNr (year): gen dia_tag= cond(dia_yr>=year,1,.)
replace year=. if dia_tag==.
// this step is important to preserve the obs who have LISA data after diagnosis
by LopNr:egen max_dia_yr =max(year)
// max_dia_yr was created to select LISA status in the latest avaiable year if their diagnosis year is as of 2019
replace dia_tag=. if max_dia_yr!=year
// dia_tag is for sorting in filling missing values by LopNr
order max_dia_yr dia_tag, after(year_late)

gen Sun2000niva_old_dia=Sun2000niva_old if max_dia_yr==year
bysort LopNr(dia_tag): replace Sun2000niva_old_dia=Sun2000niva_old_dia[1]

gen Sun2000niva_dia=Sun2000niva if max_dia_yr==year
bysort LopNr(dia_tag): replace Sun2000niva_dia=Sun2000niva_dia[1]

gen DispInk04_dia=DispInk04 if max_dia_yr==year
bysort LopNr(dia_tag): replace DispInk04_dia=DispInk04_dia[1]

gen DispInkFam04_dia=DispInkFam04 if max_dia_yr==year
bysort LopNr(dia_tag): replace DispInkFam04_dia=DispInkFam04_dia[1]

replace Sun2000niva_old_dia="" if year==.
//Sun2000niva_old_dia is string
foreach var of varlist Sun2000niva_dia DispInk04_dia DispInkFam04_dia {
	replace `var'=. if year==.
}
// this is to keep as missing who had LISA information after diagnosis

**Adding preoperative LISA data for paper 03
**********************************************
*extracting LISA status at operation year (IMPORTANT to remember there is no LISA data for 2019)
sort LopNr year1
bysort LopNr (year1): gen op_tag= cond(op_yr>=year1,1,.)
replace year1=. if op_tag==.
bro LopNr year1 op_yr op_tag
// this step is important to preserve the obs who have LISA data after operation

by LopNr:egen max_op_yr =max(year1)
bro LopNr year1 dia_yr op_yr max_op_yr op_tag
// max_op_yr was created to select LISA status in the latest avaiable year if their operation year is as of 2019

replace op_tag=. if max_op_yr!=year1
// op_tag is for sorting in filling missing values by LopNr
order max_op_yr op_tag, after(dia_tag)

gen Sun2000niva_old_op=Sun2000niva_old if max_op_yr==year1
bysort LopNr(op_tag): replace Sun2000niva_old_op=Sun2000niva_old_op[1]
bro LopNr year1 dia_yr op_yr max_op_yr op_tag Sun2000niva_old Sun2000niva_old_op

gen Sun2000niva_op=Sun2000niva if max_op_yr==year1
bysort LopNr(op_tag): replace Sun2000niva_op=Sun2000niva_op[1]

gen DispInk04_op=DispInk04 if max_op_yr==year1
bysort LopNr(op_tag): replace DispInk04_op=DispInk04_op[1]

gen DispInkFam04_op=DispInkFam04 if max_op_yr==year1
bysort LopNr(op_tag): replace DispInkFam04_op=DispInkFam04_op[1]

replace Sun2000niva_old_op="" if year1==.
//Sun2000niva_old_op is string
foreach var of varlist Sun2000niva_op DispInk04_op DispInkFam04_op {
	replace `var'=. if year1==.
}

order *_ear *_late *_dia *_mean *_op, after (dia_date2)
sort LopNr year
egen tag=tag(LopNr)
keep if tag==1
drop year_ear year_late dia_yr op_yr year  year1 max_dia_yr max_op_yr dia_tag op_tag tag Sun2000niva_old-DispInkFam04

save "D:/SCB/STATA_files/LISA_extract.dta", replace
// pre-op LISA data was added for paper 03

*Extracting RTB status at earliest, at latest, at diagnosis year and mean incomes *
******************************************************************************
use "${workdir}SH_Lev_RTB_2005_2019", clear

*extracting dia_date2 from Primiary_crc_SCRCR.dta
preserve
use "D:/STATA files/Primiary_crc_SCRCR.dta",clear
keep LopNr dia_date2 op_date
// also keep for operation date 
gen dia_yr=year(dia_date2)
gen op_yr=year(op_date)

tempfile temp
save `temp'
restore

merge m:1 LopNr using `temp'
keep if _merge==3
drop _merge
order dia* op* year, after(LopNr)

*extracting the earliest RTB status
sort LopNr year
by LopNr: egen year_ear = min(year)
order year_ear, after(year)

gen Lan_ear=Lan if year_ear==year
bysort LopNr(year): replace Lan_ear=Lan_ear[1]

gen Civil_ear=Civil if year_ear==year
bysort LopNr(year): replace Civil_ear=Civil_ear[1]

gen FamTyp_ear=FamTyp if year_ear==year
bysort LopNr(year): replace FamTyp_ear=FamTyp_ear[1]

gen civilantalar_ear=civilantalar if year_ear==year
bysort LopNr(year): replace civilantalar_ear=civilantalar_ear[1]

*extracting the latest RTB status
sort LopNr year
by LopNr: egen year_late = max(year)
order year_late, after(year_ear)

gen Lan_late=Lan if year_late==year
bysort LopNr(Lan_late): replace Lan_late=Lan_late[1]

gen Civil_late=Civil if year_late==year
gsort LopNr -year
bysort LopNr: replace Civil_late=Civil_late[1]
//Civil is string is gsort is required

gen FamTyp_late=FamTyp if year_late==year
bysort LopNr(FamTyp_late): replace FamTyp_late=FamTyp_late[1]

gen civilantalar_late=civilantalar if year_late==year
bysort LopNr(civilantalar_late): replace civilantalar_late=civilantalar_late[1]


gen year1=year
label var year1 "for paper 03"
//IMPORTANT for calculating pre-operative RTB status

*extracting the RTB status at diagnosis year 
sort LopNr year
bysort LopNr (year): gen dia_tag= cond(dia_yr>=year,1,.)
replace year=. if dia_tag==.
// this step is important to preserve the obs who have RTB data after diagnosis
by LopNr:egen max_dia_yr =max(year)
// max_dia_yr was created to select LISA status in the latest avaiable year if their diagnosis year is as of 2019
replace dia_tag=. if max_dia_yr!=year
// dia_tag is for sorting in filling missing values by LopNr
order max_dia_yr dia_tag, after(year_late)

gen Lan_dia=Lan if max_dia_yr==year
bysort LopNr(dia_tag): replace Lan_dia=Lan_dia[1]

gen Civil_dia=Civil if max_dia_yr==year
bysort LopNr(dia_tag): replace Civil_dia=Civil_dia[1]

gen FamTyp_dia=FamTyp if max_dia_yr==year
bysort LopNr(dia_tag): replace FamTyp_dia=FamTyp_dia[1]

gen civilantalar_dia=civilantalar if max_dia_yr==year
bysort LopNr(dia_tag): replace civilantalar_dia=civilantalar_dia[1]

replace Civil_dia="" if year==.
//Civil is string
foreach var of varlist Lan_dia FamTyp_dia civilantalar_dia {
	replace `var'=. if year==.
}


***extracting the RTB status at operation year for paper 03
******
sort LopNr year1
bysort LopNr (year1): gen op_tag= cond(op_yr>=year1,1,.)
replace year1=. if op_tag==.
// this step is important to preserve the obs who have RTB data after diagnosis
by LopNr:egen max_op_yr =max(year1)

replace op_tag=. if max_op_yr!=year1
// op_tag is for sorting in filling missing values by LopNr
order max_op_yr op_tag, after(dia_tag)

gen Lan_op=Lan if max_op_yr==year1
bysort LopNr(op_tag): replace Lan_op=Lan_op[1]

gen Civil_op=Civil if max_op_yr==year1
bysort LopNr(op_tag): replace Civil_op=Civil_op[1]

gen FamTyp_op=FamTyp if max_op_yr==year1
bysort LopNr(op_tag): replace FamTyp_op=FamTyp_op[1]

gen civilantalar_op=civilantalar if max_op_yr==year1
bysort LopNr(op_tag): replace civilantalar_op=civilantalar_op[1]

replace Civil_op="" if year1==.
//Civil is string
foreach var of varlist Lan_op FamTyp_op civilantalar_op {
	replace `var'=. if year1==.
}


order *_ear *_late *_dia *_op, after (dia_date2)
egen tag=tag(LopNr)
keep if tag==1
drop year_ear year_late dia_yr op_yr year  year1 max_dia_yr max_op_yr dia_tag op_tag tag Lan-civilantalar

save "D:/SCB/STATA_files/RTB_extract.dta", replace
//add RTB data at operation year for paper 03

*Merging extracted LISA and RTB datafiles **
*************************************************
use "${workdir}LISA_extract.dta", clear
sort LopNr dia_date2
merge 1:1 LopNr dia_date2 using "${workdir}RTB_extract.dta"
keep if _merge==3
drop _merge

label variable Sun2000niva_old_ear "Earliest education level_old"
label variable Sun2000niva_ear "Earliest education level_new"
label variable Sun2000niva_old_late "Latest education level_old"
label variable Sun2000niva_late "Latest education level_new"
label variable DispInk04_mean "Mean individual income"
label variable DispInkFam04_mean "Mean family income"

label variable Civil_ear "Earliest marital status"
label variable Civil_late "Latest marital status"
label variable Lan_ear "Earliest county info"
label variable Lan_late "Latest county info"
label variable FamTyp_ear "Earliest family type"
label variable FamTyp_late "Latest family type"
label variable civilantalar_ear "Earliest civilantalar"
label variable civilantalar_late "Latest civilantalar"

label variable Sun2000niva_old_dia "Education level_old at diagnosis yr"
label variable Sun2000niva_dia "Education level_new at diagnosis yr"
label variable DispInk04_dia "Individual income at diagnosis yr"
label variable DispInkFam04_dia "Family income at diagnosis yr"

label variable Civil_dia "Marital status at diagnosis yr"
label variable Lan_dia "County info at diagnosis yr"
label variable FamTyp_dia "Family type at diagnosis yr"
label variable civilantalar_dia "Civilantalar at diagnosis yr"

label variable Sun2000niva_old_op "Education level_old at operation yr"
label variable Sun2000niva_op "Education level_new at operation yr"
label variable DispInk04_op "Individual income at operation yr"
label variable DispInkFam04_op "Family income at operation yr"

label variable Civil_op "Marital status at operation yr"
label variable Lan_op "County info at operation yr"
label variable FamTyp_op "Family type at operation yr"
label variable civilantalar_op "Civilantalar at operation yr"

order op_date *_ear *_late *_dia *_op, after (dia_date2)
order *_mean, after(civilantalar_dia)

save "${workdir}LISA_RTB_extract", replace
// SES status at operation year was added on 16/02/23 for paper 03
