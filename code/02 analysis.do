*******************
/* Test Packages */
*******************

* check if somersd is installed
* if not > ssc install somersd
which somersd

* check if esttab is installed
* if not > ssc install estout
which esttab

* if not installed, will throw an error


***************
/* Load Data */
***************

clear
eststo clear
use "redacted-data/data", clear
set seed 5330
set scheme modern


**************************************
/* Explanation of Key IOS Variables */
**************************************

/*
The *Standard* IOS scale variables are:

ios_discrete_pictures1ios_number
ios_discrt_picts1ios_distance
ios_discrt_picts1ios_overlap


The *Step-Choice* IOS scale variables are:

ios_discrete1ios_number
ios_discrete1ios_distance
ios_discrete1ios_overlap


The *Continuous* IOS scale variables are:

ios_continuous1ios_distance	
ios_continuous1ios_overlap	

We generate the *Continuous* IOS numbers below in lines 549-559.

*/

**************************************************
/* Implementation details reported in Section 3 */
**************************************************

sum seconds_experiment
gen minutes_experiment = seconds_experiment/60

sum minutes_experiment

sum payoff_plus_participation_fee


/* Drop Subject with Continuous Overlap > 1 (see Footnote 2 for an explanation) */

drop if ios_continuous1ios_overlap > 1 & ios_continuous1ios_overlap != .


/* Generate Session Type Variable */

tab task_order

gen session_type = .
	replace session_type = 2 if task_order == 3 
	replace session_type = 2 if task_order == 4
	replace session_type = 1 if task_order == 1 
	replace session_type = 1 if task_order == 2 

label define session_type 	1 "Step-Choice IOS" ///
							2 "Continuous IOS"
							
label values session_type session_type

tab session_type


***********************************
/* Results Reported in Section 4 */
***********************************

/* Converting the proportion of continuous overlap into one-to-seven measure 
(see Footnote 3 for explanations of the specific thresholds) */

gen ios_continuous_overlap_bounded = .
	replace ios_continuous_overlap_bounded = 1 if ios_continuous1ios_overlap < 0.0711687543
	replace ios_continuous_overlap_bounded = 2 if ios_continuous_overlap_bounded == . & ios_continuous1ios_overlap < 0.2144646286 
	replace ios_continuous_overlap_bounded = 3 if ios_continuous_overlap_bounded == . & ios_continuous1ios_overlap < 0.3594493146	
	replace ios_continuous_overlap_bounded = 4 if ios_continuous_overlap_bounded == . & ios_continuous1ios_overlap < 0.5017821132	
	replace ios_continuous_overlap_bounded = 5 if ios_continuous_overlap_bounded == . & ios_continuous1ios_overlap < 0.6441712323		
	replace ios_continuous_overlap_bounded = 6 if ios_continuous_overlap_bounded == . & ios_continuous1ios_overlap < 0.7889021411	
	replace ios_continuous_overlap_bounded = 7 if ios_continuous_overlap_bounded == . & ios_continuous1ios_overlap <= 1

	
/* Figure 3: Average difference between the IOS scores reported with the Continuous
or the Step-Choice IOS scale and the standard IOS scale (with boot-
strapped 95% confidence intervals) */


gen OGIOSNumber_less_NewIOSNumber = .
	replace OGIOSNumber_less_NewIOSNumber = ios_discrete_pictures1ios_number - ios_discrete1ios_number
	replace OGIOSNumber_less_NewIOSNumber = ios_discrete_pictures1ios_number - ios_continuous_overlap_bounded ///
		if OGIOSNumber_less_NewIOSNumber == .


bootstrap _b, reps(1000): mean OGIOSNumber_less_NewIOSNumber if session_type == 2
estat bootstrap, percentile
matrix ci_continuous = e(ci_percentile)

bootstrap _b, reps(1000): mean OGIOSNumber_less_NewIOSNumber if session_type == 1
estat bootstrap, percentile
matrix ci_step_choice = e(ci_percentile)

preserve
		
collapse OGIOSNumber_less_NewIOSNumber, by(session_type)

gen y1 = .
	replace y1 = ci_continuous[1,1] if session_type == 2
	replace y1 = ci_step_choice[1,1] if session_type == 1
gen y2 = .
	replace y2 = ci_continuous[2,1] if session_type == 2
	replace y2 = ci_step_choice[2,1] if session_type == 1
	
twoway (scatter session_type OGIOSNumber_less_NewIOSNumber ) || (rcap y1 y2 session_type, horizontal), ///
	ytitle("") leg(off) ///
	ylabel(2 "Continuous IOS" 1 "Step-Choice IOS") ///
	aspect(0.1) yscale(lstyle(none)) xscale(lstyle(none)) ylabel(, tstyle(major_notick)) ///
	xla(-0.2(0.1)0.3, grid) ysize(1) scale(4)
	
graph save graphs/ios-comparison.gph, replace	   
graph export graphs/ios-comparison.pdf, replace	
	

restore


/* Wilcoxon matched-pairs signed-ranks tests */

* Standard IOS vs Continuous IOS * 

signrank ios_discrete_pictures1ios_number = ios_continuous_overlap_bounded, exact

* Standard IOS vs Step-Choice IOS * 

signrank ios_discrete_pictures1ios_number = ios_discrete1ios_number, exact

* Standard IOS vs Continuous IOS with subject who reported Standard IOS 2 and Continuous IOS 1 removed * 

preserve 

gen emph_pic2_cont1 = 0
	replace emph_pic2_cont1 = 1 if ios_continuous_overlap_bounded == 1 & ios_discrete_pictures1ios_number == 2
	
drop if emph_pic2_cont1 == 1

signrank ios_discrete_pictures1ios_number = ios_continuous_overlap_bounded, exact

restore


/* Somers' D with Confidence Intervals */
* Explanation of Somer's D - https://www.stata-journal.com/sjpdf.html?articlenum=snp15_6 *

* Generating variables showing differences between reported IOS scores* 

gen signdiff = sign(ios_discrete1ios_number - ios_discrete_pictures1ios_number)
	replace signdiff = sign(ios_continuous_overlap_bounded - ios_discrete_pictures1ios_number) ///
	if signdiff == .

gen absdiff = abs(ios_discrete1ios_number - ios_discrete_pictures1ios_number)
	replace absdiff = abs(ios_continuous_overlap_bounded - ios_discrete_pictures1ios_number) ///
	if absdiff == .

* Standard IOS vs Continuous IOS* 

somersd signdiff absdiff if absdiff! = 0 & session_type == 1, transf(z)

* Standard IOS vs Step-Choice IOS* 

somersd signdiff absdiff if absdiff! = 0 & session_type == 2, transf(z)


/* Figure 4: Relation between the IOS scores reported with the standard IOS scale
and those reported with the Continuous IOS scale. */

gen Cat0 = -0.07
gen Cat1 = 0.071168754
gen Cat2 = 0.2144646286
gen Cat3 = 0.3594493146
gen Cat4 = 0.5017821132
gen Cat5 = 0.6441712323
gen Cat6 = 0.7889021411
gen Cat7 = 1.05
gen xValue = .
 
replace xValue = 0.5 in 1
replace xValue = 1 in 2
replace xValue = 2 in 3
replace xValue = 3 in 4
replace xValue = 4 in 5
replace xValue = 5 in 6
replace xValue = 6 in 7
replace xValue = 7 in 8
replace xValue = 7.25 in 9

twoway area Cat7 xValue in 1/9, color(gs15) || ///
area Cat6 xValue in 1/9, base(-0.07) color(white) || ///
area Cat5 xValue in 1/9, base(-0.07) color(gs15) || ///
area Cat4 xValue in 1/9, base(-0.07) color(white) || ///
area Cat3 xValue in 1/9, base(-0.07) color(gs15) || ///
area Cat2 xValue in 1/9, base(-0.07) color(white) || ///
area Cat1 xValue in 1/9, base(-0.07) color(gs15) || ///
scatter ios_continuous1ios_overlap ios_discrete_pictures1ios_number if ios_continuous1ios_overlap <=1, ///
mcolor(dknavy) msize(1pt) jitter(6) ///
xtitle(Standard IOS) xtick(0.5 7.25, noticks) xlabel(1(1)7, nogrid) ///
yaxis(2 1) yscale(alt axis(2)) yscale(alt axis(1)) yscale(lcolor(none)) ///
ytitle(Continuous IOS Overlap, axis(2)) yla(0(0.2)1, axis(2) ang(h) nogrid) ///
ytitle(Continuous IOS Categories, axis(1)) ytick(-0.0715 1.0715, noticks) ///
ylabel(0.000584377 "1" 0.142816691 "2" 0.286956972 "3" 0.430615714 "4" ///
0.572976673 "5" 0.716536687 "6" 0.919451071 "7", axis(1) tposition(inside) nogrid) ///
note("The left {it:y} axis shows the Continuous IOS scale in seven categories while the right {it:y} axis shows the" "Continuous IOS scale between 0 and 1. Jittered.", span size(vsmall)) ///
aspect(1) legend(off) graphregion(color(white)) xsize(5) ysize(5)

graph save graphs/ContIOSOverlapShadedvsOriginalPictorial_Jitter6.gph, replace	   
graph export graphs/ContIOSOverlapShadedvsOriginalPictorial_Jitter6.pdf, replace








/* Table 2: How dissimilarity and respondents' characteristics explain the reported IOS score, ordered logistic regression. */

* Get player age *

generate playerage = 2020 - year(playerbirthdate)
order playerage, after(playerbirthdate)
label variable playerage "Age"

* Port over the 'no' answers to the preceding questions *

replace survey1children_number = 0 if survey1children_number == .
replace survey1ethnicity_choice = "none" if survey1ethnicity_choice == ""
replace survey1religion_denomination = "none" if survey1religion_denomination == "" 

* Bundle the small categories in 'other' *

replace survey1race = "other" if inlist(survey1race, "filipino", "guamanian or chamorro", "other asian", "vietnamese", "japanese")
replace survey1religion_denomination = "other" if inlist(survey1religion_denomination, "buddhist", "hindu", "mormon", "muslim", "orthodox")
replace survey1ethnicity_choice = "other" if inlist(survey1ethnicity_choice, "cuban", "puerto rican")
replace survey1highest_degree = "12th grade no degree and less" if inlist(survey1highest_degree, "12th grade no degree", "elementary or some secondary schooling", "no schooling")
replace survey1marital = "separated or widowed" if inlist(survey1marital, "separated", "widowed")

* Capitalise variables *

foreach var in survey1sex survey1race survey1religion_denomination survey1ethnicity_choice survey1religion_denomination survey1political_party survey1marital survey1social_class survey1work_last_week survey1place_growing_up survey1highest_degree {
	replace `var' = upper(substr(`var', 1, 1)) + lower(substr(`var', 2, .))
}
replace survey1religion_denomination = "Roman Catholic" if survey1religion_denomination == "Roman catholic"


* Turn string vars into numeric *

encode survey1sex, gen(survey1sex_n)
encode survey1ethnicity_choice, gen(survey1ethnicity_choice_n)
encode survey1race, gen(survey1race_n)
encode survey1religion_denomination, gen(survey1religion_denomination_n)
encode survey1political_party, gen(survey1political_party_n)
encode survey1marital, gen(survey1marital_n)
encode survey1social_class, gen(survey1social_class_n)
encode survey1work_last_week, gen(survey1work_last_week_n)
encode survey1place_growing_up, gen(survey1place_growing_up_n)
encode survey1highest_degree, gen(survey1highest_degree_n)

* Show the base levels of the variables (easier to interpret) *

set showbaselevels all

* Create labels for variables *

label variable ios_discrete_pictures1ios_number "IOS score"
label variable match0objective_distance_correct "Dissimilarity"
label variable playerbirthdate "Date of birth"
label variable survey1children_number "Number of children"
label variable survey1household_income "Household income"
label variable survey1people_helpful "People are helpful"
label variable survey1people_take_advntg_of_you "People try to take advantage of you"
label variable survey1people_trustworthy "People are trustworthy"
label variable survey1labor_union "Belong to labour union"
label variable survey1unemployed_10_years "Unemployed in the past 10 years"
label variable survey1affirmative_action "Support affirmative action"
label variable survey1sex_before_marriage "Approve sex before marriage"
label variable survey1death_penalty "Approve death penalty"
label variable survey1same_sex_relations "Approve same-sex relations"

* Ordered logistic regression *

*only distance
ologit ios_discrete_pictures1ios_number ///
	match0objective_distance_correct,  ///
	robust
	
estimates store model1

* personal characteristics without distance
ologit ios_discrete_pictures1ios_number ///
	playerage i.survey1sex_n ib(freq).survey1race_n ib(freq).survey1ethnicity_choice_n ///
	ib(freq).survey1religion_denomination_n ///
	ib(freq).survey1political_party_n ib(freq).survey1marital_n  ///
	 ib(freq).survey1social_class_n ///
	ib(freq).survey1work_last_week_n ///
	ib(freq).survey1place_growing_up_n ib(freq).survey1highest_degree_n ///
	survey1children_number survey1household_income ///
	survey1people_helpful survey1people_take_advntg_of_you survey1people_trustworthy ///
	survey1labor_union survey1unemployed_10_years ///
	survey1affirmative_action survey1sex_before_marriage survey1same_sex_relations survey1death_penalty,  ///
	robust
	
estimates store model2

* personal characteristics with distance
ologit ios_discrete_pictures1ios_number ///
	match0objective_distance_correct ///
	playerage i.survey1sex_n ib(freq).survey1race_n ib(freq).survey1ethnicity_choice_n ///
	ib(freq).survey1religion_denomination_n ///
	ib(freq).survey1political_party_n ib(freq).survey1marital_n  ///
	 ib(freq).survey1social_class_n ///
	ib(freq).survey1work_last_week_n ///
	ib(freq).survey1place_growing_up_n ib(freq).survey1highest_degree_n ///
	survey1children_number survey1household_income ///
	survey1people_helpful survey1people_take_advntg_of_you survey1people_trustworthy ///
	survey1labor_union survey1unemployed_10_years ///
	survey1affirmative_action survey1sex_before_marriage survey1same_sex_relations survey1death_penalty,  ///
	robust
	
estimates store model3
	
* Generate LaTeX code of results *

esttab model1 model2 model3 using tables/ios-explanatory.tex, ///
	fragment nogap booktabs wide ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
	label nonumbers nomtitles nobaselevels eqlabels(none)  ///
	refcat( ///
		2.survey1sex_n "\addlinespace Gender (ref.: female)" ///
		1.survey1race_n "\addlinespace Race (ref.: white)" ///
		1.survey1ethnicity_choice_n "\addlinespace Ethnicity (ref.: none)" ///
		1.survey1religion_denomination_n "\addlinespace Religion (ref.: none)" ///
		2.survey1political_party_n "\addlinespace Political party (ref.: democrat)" ///
		1.survey1marital_n "\addlinespace Marital status (ref.: married)" ///
		1.survey1social_class_n "\addlinespace Social class (ref.: middle class)" ///
		2.survey1work_last_week_n "\addlinespace Work last week (ref.: full time work)" ///
		1.survey1place_growing_up_n "\addlinespace Place growing up (ref.: small town)" ///
		1.survey1highest_degree_n "\addlinespace Highest degree (ref.:  college or some college)", ///
		nolabel ///
	) ///
	varlabels(,blist(cut1 "\midrule " survey1children_number "\addlinespace ")) ///
	stats(N r2_p chi2 p, fmt(0 3) labels(`"Observations"' `"Pseudo \(R^{2}\)"' `"Wald \(\chi^2\)"' `"Prob > \(\chi^2\)"' )) ///
	replace

	
* vif reported in footnote
regress ios_discrete_pictures1ios_number ///
	match0objective_distance_correct ///
	playerage i.survey1sex_n ib(freq).survey1race_n ib(freq).survey1ethnicity_choice_n ///
	ib(freq).survey1religion_denomination_n ///
	ib(freq).survey1political_party_n ib(freq).survey1marital_n  ///
	 ib(freq).survey1social_class_n ///
	ib(freq).survey1work_last_week_n ///
	ib(freq).survey1place_growing_up_n ib(freq).survey1highest_degree_n ///
	survey1children_number survey1household_income ///
	survey1people_helpful survey1people_take_advntg_of_you survey1people_trustworthy ///
	survey1labor_union survey1unemployed_10_years ///
	survey1affirmative_action survey1sex_before_marriage survey1same_sex_relations survey1death_penalty,  ///
	robust

vif


/* Frequency tables reported in Appendix D */

local options cell(b rowpct(fmt(2)) colpct(fmt(2)) pct(fmt(2))) ///
	unstack fragment nogap booktabs nomtitles nonumbers noobs collabels(none) ///
	replace

eststo clear
	
* step-choice vs standard
estpost tabulate ios_discrete_pictures1ios_number ios_discrete1ios_number
esttab . using tables/standard-vs-stepchoice.tex, `options'
* continuous vs standard
estpost tabulate ios_discrete_pictures1ios_number ios_continuous_overlap_bounded
esttab . using tables/standard-vs-continuous.tex, `options'

