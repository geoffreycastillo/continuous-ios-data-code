***************************************
/* Run Python Scripts to Redact Data */
***************************************

/* Before building the data from the raw oTree data we run a number of python scripts
They are all in the folder code/python/
We run them in this order:

- patch-distances.py: 
there was a problem in how the objective distance was computed in the oTree code: 
the objective distance is too large when participant and database are both of no 
religious denomination, or both have no ethnicity.
This python script patches the objective distance and adds _corrected to it
At the same time it also compute the distance on each variable (used in later 
analysis)

- redact.py
Our data has identifiable information (mostly the Mturk ID)
This python script redacts the data in unredacted-data/, saves it in redacted-data/

- statify.py
Stata has the annoying limitation that variable names need to be < 32 char
This python script shortens a few variables names 

They each need to be run once.

The Stata code picks up from there.*/


********************************************
/* Import Data and Additional Information */
********************************************

clear

import delimited "redacted-data/timespent.csv"

generate double statatime = epoch_time * 1000 + mdyhms(1,1,1970,0,0,0)
format statatime %tC

sort participant_code page_index

bysort participant_code: gen seconds_on_page = (statatime - statatime[_n-1])/1000

replace app_name = "d_m" if app_name == "display_matches_narrative"
replace app_name = "ios_sc" if app_name == "ios_discrete"
replace app_name = "ios_pic" if app_name == "ios_discrete_pictures"
replace app_name = "ios_cont" if app_name == "ios_continuous"

gen page_app = page_name + "_" + app_name

drop page_index app_name page_name timeout_happened is_wait_page epoch_time statatime

rename participant_code participantcode

reshape wide seconds_on_page, i(participantcode) j(page_app, string)

save "temp/timespent", replace


clear

import delimited "redacted-data/zip-ip-distance.csv"

drop participantmturk_assignment_id

save "temp/zip-ip-distance", replace

clear


import delimited "redacted-data/data-stata.csv"

save "temp/data", replace

drop if _current_page_name != "End"

merge 1:1 participantcode using "temp/timespent"
drop if _current_page_name != "End"

rename _merge _merge_TimeSpent

merge 1:1 participantcode using "temp/zip-ip-distance"
drop if _current_page_name != "End"

rename _merge _merge_zipIpDistance


save "temp/data", replace


****************************************************************
*** Renaming Variable Names Clipped When Imported into Stata ***
****************************************************************

rename survey1religion_denomination_oth survey1religion_denom_other
rename survey1parental_comparison_stand survey1parental_compar_standards
rename survey1people_take_advantage_of_ survey1people_take_advntg_of_you
rename survey1elementary_secondary_choi survey1elemen_secondary_choices
rename v61 survey1school_incmplt_highschool
rename survey1executive_branch_confiden survey1exec_branch_confidence

rename ios_continuous1match_displayed_n ios_continuous1match_displ_name
rename ios_discrete1match_displayed_nam ios_discrete1match_dsplyd_name

rename ios_discrete_pictures1id_in_grou ios_discrt_picts1id_in_group
rename ios_discrete_pictures1match_disp ios_discrt_picts1match_displayed
rename v167 ios_discrt_picts1match_dsplyd_nm
rename ios_discrete_pictures1ios_distan ios_discrt_picts1ios_distance
rename ios_discrete_pictures1ios_overla ios_discrt_picts1ios_overlap
rename ios_discrete_pictures1id_in_subs ios_discrt_picts1id_in_subs
rename ios_discrete_pictures1round_numb ios_discrt_picts1round_number


label variable import_database1id_in_subsession "import_database.1.id_in_subsession"
label variable survey1religion_denom_other "survey.1.religion_denomination_other"
label variable survey1parental_compar_standards "survey.1.parental_comparison_standards"
label variable survey1exec_branch_confidence "survey.1.executive_branch_confidence"
label variable survey1supreme_court_confidence "survey.1.supreme_court_confidence"
label variable survey1improve_condition_blacks "survey.1.improve_condition_blacks"
label variable survey1improve_condition_abroad "survey.1.improve_condition_abroad"
label variable survey1government_redistribution "survey.1.government_redistribution"
label variable survey1people_take_advntg_of_you "survey.1.people_take_advantage_of_you"



********************************
*** Format Data for Analysis ***
********************************

gen playerbirthdate = date(survey1date, "MDY")
format playerbirthdate %td

order playerbirthdate, after(survey1date)


**********************************
*** Generate Sessions Variable ***
**********************************

gen session = .
	replace session = 1 if session_code == "cqce6pqr"
	replace session = 1 if session_code == "g410nev8"
	replace session = 1 if session_code == "q40of133"
	replace session = 1 if session_code == "g01kvru7"

	replace session = 1 if session_code == "bnwhita6"
	replace session = 1 if session_code == "morw9hf0"
	replace session = 1 if session_code == "pqntdh2k"
	replace session = 1 if session_code == "hap6zgo3"

	
	replace session = 2 if session_code == "7oj5suby"
	replace session = 2 if session_code == "39muniop"
	replace session = 2 if session_code == "l4vvkf1o"
	replace session = 2 if session_code == "ll1e41pw"

	replace session = 2 if session_code == "6m41pf1n"
	replace session = 2 if session_code == "8oh6coid"
	replace session = 2 if session_code == "bw6g695l"
	replace session = 2 if session_code == "c72oerrg"

	replace session = 3 if session_code == "2fdd1yig"
	replace session = 3 if session_code == "l7ptwx1k"
	replace session = 3 if session_code == "q3ldyku1"
	replace session = 3 if session_code == "vku0nlzg"

tab session


gen task_order = .
	replace task_order = 1 if session_code == "cqce6pqr"
	replace task_order = 1 if session_code == "bnwhita6"
	replace task_order = 1 if session_code == "39muniop"
	replace task_order = 1 if session_code == "bw6g695l"
	replace task_order = 1 if session_code == "2fdd1yig"

	replace task_order = 2 if session_code == "g410nev8"
	replace task_order = 2 if session_code == "morw9hf0"
	replace task_order = 2 if session_code == "7oj5suby"
	replace task_order = 2 if session_code == "8oh6coid"
	replace task_order = 2 if session_code == "q3ldyku1"
	
	replace task_order = 3 if session_code == "q40of133"
	replace task_order = 3 if session_code == "pqntdh2k"
	replace task_order = 3 if session_code == "ll1e41pw"
	replace task_order = 3 if session_code == "c72oerrg"
	replace task_order = 3 if session_code == "l7ptwx1k"

	replace task_order = 4 if session_code == "g01kvru7"
	replace task_order = 4 if session_code == "hap6zgo3"
	replace task_order = 4 if session_code == "l4vvkf1o"
	replace task_order = 4 if session_code == "6m41pf1n"
	replace task_order = 4 if session_code == "vku0nlzg"

	
label define task_order 1 "Pictorial IOS, Step Choice IOS" 2 "Step Choice IOS, Pictorial IOS" 3 "Pictorial IOS, Continuous IOS" 4 "Continuous IOS, Pictorial IOS"
label values task_order task_order

****************************************
*** Identifying Suspicious Responses ***
****************************************

gen Suspicious_Responses = .

gen Suspicious_children_first_a = 0
replace Suspicious_children_first_a = 1 if survey1children_first_a < 12
replace Suspicious_children_first_a = 1 if survey1children_first_a > 75
replace Suspicious_children_first_a = 0 if survey1children_first_a == .

replace Suspicious_Responses = Suspicious_children_first_a

gen seconds_experiment_cont = seconds_on_pageFeedback_outro + seconds_on_pageIntro_d_m + seconds_on_pageIntro_filler + seconds_on_pageIntro_ios_cont + seconds_on_pageIntro_ios_pic + seconds_on_pageIntro_survey + seconds_on_pagePart1_survey + seconds_on_pagePart2_survey + seconds_on_pagePart3_survey + seconds_on_pagePart4_survey + seconds_on_pageResult_filler + seconds_on_pageTask_d_m + seconds_on_pageTask_filler + seconds_on_pageTask_ios_cont + seconds_on_pageTask_ios_pic
gen seconds_experiment_sc = seconds_on_pageFeedback_outro + seconds_on_pageIntro_d_m + seconds_on_pageIntro_filler + seconds_on_pageIntro_ios_pic + seconds_on_pageIntro_ios_sc + seconds_on_pageIntro_survey + seconds_on_pagePart1_survey + seconds_on_pagePart2_survey + seconds_on_pagePart3_survey + seconds_on_pagePart4_survey + seconds_on_pageResult_filler + seconds_on_pageTask_d_m + seconds_on_pageTask_filler + seconds_on_pageTask_ios_pic + seconds_on_pageTask_ios_sc

gen seconds_experiment = .
	replace seconds_experiment = seconds_experiment_cont
	replace seconds_experiment = seconds_experiment_sc if seconds_experiment == .

gen Suspicious_experiment_time = 0
replace Suspicious_experiment_time = 1 if seconds_experiment < 180

replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time


gen Suspicious_profession = 0
replace Suspicious_profession = 1 if survey1profession == "1"
replace Suspicious_profession = 1 if survey1profession == "10"
replace Suspicious_profession = 1 if survey1profession == "10 hours"
replace Suspicious_profession = 1 if survey1profession == "45"
replace Suspicious_profession = 1 if survey1profession == "EFFORT"
replace Suspicious_profession = 1 if survey1profession == "GOOD"
replace Suspicious_profession = 1 if survey1profession == "TL"
replace Suspicious_profession = 1 if survey1profession == "na"
replace Suspicious_profession = 1 if survey1profession == "plan"
replace Suspicious_profession = 1 if survey1profession == "work"
replace Suspicious_profession = 1 if survey1profession == "yes"
replace Suspicious_profession = 1 if survey1profession == "You are educating the other person on the subject of you"
replace Suspicious_profession = 1 if survey1profession == "project"

replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time + Suspicious_profession 


gen Suspicious_major_college = 0

replace Suspicious_major_college = 1 if survey1major_college == "12"
replace Suspicious_major_college = 1 if survey1major_college == "15"
replace Suspicious_major_college = 1 if survey1major_college == "college"
replace Suspicious_major_college = 1 if survey1major_college == "fafsevadse"
replace Suspicious_major_college = 1 if survey1major_college == "very good"
replace Suspicious_major_college = 1 if survey1major_college == "well"
replace Suspicious_major_college = 1 if survey1major_college == "Academic"
replace Suspicious_major_college = 1 if survey1major_college == "Acdemic"
replace Suspicious_major_college = 1 if survey1major_college == "There are some risks you might experience from being in this study. One risk is being asked about potentially sensitive subjects. Another risk is the possibility of a breach of confidentiality"
replace Suspicious_major_college = 1 if survey1major_college == "good study"

replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time + Suspicious_profession + Suspicious_major_college


gen Suspicious_major_bachelor = 0

replace Suspicious_major_bachelor = 1 if survey1major_bachelor == "9"
replace Suspicious_major_bachelor = 1 if survey1major_bachelor == "The purpose of the study is to investigate Social Preferences"

replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time + Suspicious_profession + Suspicious_major_college + Suspicious_major_bachelor


gen Suspicious_zip_ip_distance = 0
replace Suspicious_zip_ip_distance = 1 if zip_ip_distance > 200

replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time + Suspicious_profession + Suspicious_major_college + Suspicious_major_bachelor + Suspicious_zip_ip_distance

gen Suspicious_Duplicate_IP = 0
split survey1playerip, parse(.)
sort survey1playerip1 survey1playerip2 survey1playerip3 survey1playerip4
gen First_Three_IP = survey1playerip1 + "." + survey1playerip2 + "." + survey1playerip3
gen First_Four_IP = survey1playerip1 + "." + survey1playerip2 + "." + survey1playerip3 + "." + survey1playerip4

sort First_Three_IP
quietly by First_Three_IP: gen dup = cond(_N==1,0,_n)
quietly by First_Three_IP: gen dup2 = cond(_N==1,0,_N)

replace Suspicious_Duplicate_IP = 1 if dup > 0

gen Suspicious_Duplicate_IP_4 = 0

sort First_Four_IP
quietly by First_Four_IP: gen dup_4 = cond(_N==1,0,_n)
quietly by First_Four_IP: gen dup2_4 = cond(_N==1,0,_N)

replace Suspicious_Duplicate_IP_4 = 1 if dup2_4 > 0

sort dup2_4 First_Four_IP


replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time + Suspicious_profession + Suspicious_major_college + Suspicious_major_bachelor + Suspicious_zip_ip_distance + Suspicious_Duplicate_IP


gen Suspicious_Comment = 0

replace Suspicious_Comment = 1 if outro1comments == "No suspcious comments here"

replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time + Suspicious_profession + Suspicious_major_college + Suspicious_major_bachelor + Suspicious_zip_ip_distance + Suspicious_Duplicate_IP + Suspicious_Comment 


gen Disqualifying_Tweet = 0


*gibberish (5 total)*
replace Disqualifying_Tweet = 1 if narrative1tweet == "favouritecolourilikethissomuchmyfavonemybestieesfavcolorilivethisshapeilovepinkcolorheart"
replace Disqualifying_Tweet = 1 if narrative1tweet == "jkf;lase faiwjf lajwfoi ajliwefj iawje flijea liwjflijwa lifjwa"
replace Disqualifying_Tweet = 1 if narrative1tweet == "a;ljeinalje iawjei aoiwj wiejf oiqj woiejfoiqj wifjqoiw foijqoiwj efjcoiqjoiwjq oij fw3j oiqj23oir oiqj ewf3"
replace Disqualifying_Tweet = 1 if narrative1tweet == "This a a a a a a a a a a a a a a a a a a a a a a a"
replace Disqualifying_Tweet = 1 if narrative1tweet == "None                                              ."

*random (4 total; 7 after session 3)*
replace Disqualifying_Tweet = 1 if narrative1tweet == "The most important thing for me to hear is the fact that my mind is very happy and well refreshed"
replace Disqualifying_Tweet = 1 if narrative1tweet == "I've been a witch for about ten years, though not necessarily very active in my  Wicca is a specific religion, created in the 1960s and practiced around the"
replace Disqualifying_Tweet = 1 if narrative1tweet == "When you are conceived, purposefully or accidentally, you are inheriting genes from both people - dominant genes and recessive genes"
replace Disqualifying_Tweet = 1 if narrative1tweet == "I love my best friend because is always there for me"
replace Disqualifying_Tweet = 1 if narrative1tweet == "HE can let your child pick the first word, for example âcatâ. You then think of a word off the top of your head that is connected like âdogâ â it's an animal. Your child then chooses the next word that they associate with 'dog' - for example, 'bone'. You keep going until you get stuck."
replace Disqualifying_Tweet = 1 if narrative1tweet == "I am like for good feel and honest for all time this man very proud of heart touch and best feel every time."
replace Disqualifying_Tweet = 1 if narrative1tweet == "HE WAS VERY BRILLIANT PERSON.GOOD PERSON.HE WAS THE GREATE SCIENTIST.MOST RESPECTFUL PERSON"

*card text (22 total; 25 after session 3)*
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Mebane, North Carolina, who is 50 years old.  He is white.  He adheres to Protestant beliefs.  He grew up in Pennsylvania in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Brookfield, Connecticut, who is 39 years old.  She is white.  She adheres to Roman Catholic beliefs.  She grew up in New York in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Springfield, Massachusetts, who is 46 years old.  He is white.  He does not belong to a religious denomination.  He grew up in Massachusetts in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Naples, Florida, who is 60 years old.  He is white.  He adheres to Roman Catholic beliefs.  He grew up in Spain."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Onalaska, Washington, who is 21 years old.  She is white.  She adheres to Roman Catholic beliefs.  She grew up in Washington in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Albuquerque, New Mexico, who is 25 years old.  This participant is a woman from Albuquerque, New Mexico, who is 25 years old."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Jefferson City, Missouri, who is 30 years old.  He is white.  He does not belong to a religious denomination.  He grew up in Missouri in the United State"
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Lagrange, Georgia, who is 30 years old.  He is Black or African American."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Stillwater, Oklahoma, who is 31 years old.  She is white.  She adheres to Roman Catholic beliefs.  She grew up in Oklahoma in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Alcoa, Tennessee, who is 70 years old.  She is white.  She adheres to Protestant beliefs."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Kalamazoo, Michigan, who is 26 years old.  He is white.  He does not belong to a religious denomination.  He grew up in Michigan in the United States.This participant is a man from Kalamazoo, Michigan, who"
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Wayland, Michigan, who is 21 years old.  He is white.  He does not belong to a religious denomination.  He grew up in Michigan in the United States"
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Wilmington, Illinois, who is 29 years old.  She is white.  She does not belong to a religious denomination.  She grew up in New Hampshire in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Allen, Texas, who is 21 years old.  She is white.  She adheres to Protestant beliefs.  She grew up in Texas in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Long Beach, California, who is 29 years old.  She is Filipino.  She does not belong to a religious denomination.  She grew up in California in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Franklinton, North Carolina, who is 22 years old."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Elizabethtown, Pennsylvania, who is 48 years old.  He is white."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from New Iberia, Louisiana, who is 45 years old.  She is Black or African American.  She adheres to Roman Catholic beliefs.  She grew up in Louisiana in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from West Yarmouth, Massachusetts,"
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a man from Des Plaines, Illinois, who is 25 years old."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This participant is a woman from Port Orange, Florida, who is 45 years old.  She is white.  She adheres to Protestant beliefs.  She grew up in Georgia in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "That is This participant is a woman from Glendale, Arizona, who is 45 years old.  She is white.  She does not belong to a religious denomination.  She grew up in New York in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "He is white and considers himself to be of Hispanic, Latino, or Spanish origin but not Mexican, Puerto Rican. He grew up in Ohio in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "He is 31 years old.  He is white.  He does not belong to a religious denomination.  He grew up in Michigan in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "good and  best decision  This participant is a man from Mount Vernon, Illinois, who is 39 years old.  He is white.  He does not belong to a religious denomination.  He grew up in Illinois in the United States."


*playing card reference (10 total; 12 after session 3)*
replace Disqualifying_Tweet = 1 if narrative1tweet == "Cards game. interesting rummy. enjoyable game. I really want this game."
replace Disqualifying_Tweet = 1 if narrative1tweet == "A spade is a tool primarily for digging, comprising a blade  typically stunted and less curved than that of a shovel  and a long handle. Early spades were made of riven wood or of animal bones. After the art of metalworking was developed."
replace Disqualifying_Tweet = 1 if narrative1tweet == "hollow muscular organ of vertebrate animals that by its rhythmic contraction acts as a force pump maintaining the circulation of the blood  could feel her heart pounding  b: a structure in an invertebrate animal functionally analogous to the vertebrate heart  c: BREAST, BOSOM  placed his hand on his heart  d: something resembling a heart in shape"
replace Disqualifying_Tweet = 1 if narrative1tweet == "diamond heart  are many other things are includes the cards"
replace Disqualifying_Tweet = 1 if narrative1tweet == "DIAMOND IS THE BIGGEST VALUE OF THE WORLD HOW ONE WILL BRING THER DIAMOND HE IS THE ONE OF THE GREATEST PERSON IN THE WORLD"
replace Disqualifying_Tweet = 1 if narrative1tweet == "When playing Spades, the play of the cards goes clockwise, starting with the ... As a general rule, early on in the play when the opponent on your right leads a suit"
replace Disqualifying_Tweet = 1 if narrative1tweet == "In this all the characters are in the cards symbols."
replace Disqualifying_Tweet = 1 if narrative1tweet == "in this pennsylvie dimand is best beautiful of  demand"
replace Disqualifying_Tweet = 1 if narrative1tweet == "A club is an association of people united by a common interest or goal. A service club, for example, exists for voluntary or charitable activities. There are clubs devoted to hobbies and sports, social activities clubs, political and religious clubs, and so forth."
replace Disqualifying_Tweet = 1 if narrative1tweet == "heart is like not blong is like great position is goood vharacher is liked life"
replace Disqualifying_Tweet = 1 if narrative1tweet == "DIAMOND IS A WORD IS VERY COSTLY ALL OVER THE WORLD. THIS IS PROUD TO HAVE IS VERY COST IN THE WORLD."
replace Disqualifying_Tweet = 1 if narrative1tweet == "this is the gambling spade card it is used to related by the person to the compare the participant to above the mind about the first thing"

*random copy pasted text (23 total; 28 after session 3)*
replace Disqualifying_Tweet = 1 if narrative1tweet == "n order to address the childcare barrier and the gender disparity on the Cityâs Boards and Commissions, Councilwoman Shirley Gonzales today filed a Council Consideration Request to establish free childcare for all board and commissions participants"
replace Disqualifying_Tweet = 1 if narrative1tweet == "50 billion. Given these developments, the FTC hosted a workshop on November 19, 2013 titled. Privacy and Security in a Connected World. Workshop participants discussed benefits and risks associated with the Iot."
replace Disqualifying_Tweet = 1 if narrative1tweet == "He does not belong to a religious denomination.  Many influential men and women played important roles in the formation of the Province that later became known as the Colony of North Carolina. ... against the Crown that led to Independence and the birth of the United States. ... theory that are still currently in force; and made Edenton the significant historic town it is today."
replace Disqualifying_Tweet = 1 if narrative1tweet == "he fax machine beeped and screeched as it transmitted a two-page document to the FBI. I was a low-level reporter for the Los Angeles Times working out of a storefront news bureau on Exposition Boulevard in South L.A., chasing answers to questions that the newspaper should have asked decades earlier about the death of one of its own.    Without the knowledge of my editors and unsure of what I might be dredging up, I faxed a Freedom of Information Act request to the FBI, searching for clues to a momentous but neglected chapter in Los Angeles history: the slaying, by a sheriffâs deputy, of Los Angeles Times columnist and KMEX-TV news director Ruben Salazar."
replace Disqualifying_Tweet = 1 if narrative1tweet == "Arizona (/ËÃ¦rÉªËzoÊnÉ/ (About this soundlisten) ARR-iz-OH-nÉ; Navajo: Hoozdo Hahoodzo;[7] O'odham: AlÄ­ á¹£onak)[8] is a state in the southwestern region of the United States. It is also part of the Western and the Mountain states. It is the 6th largest and the 14th most populous of the 50 states. Its capital and largest city is Phoenix. Arizona shares the Four Corners region with Utah, Colorado, and New Mexico; its other neighboring states are Nevada and California to the west and the Mexican states of Sonora and Baja California to the south and southwest."
replace Disqualifying_Tweet = 1 if narrative1tweet == "Religion and the  Individual:  Belief, Practice,  and Identity"
replace Disqualifying_Tweet = 1 if narrative1tweet == "âShow Us Your Godâ: Marilla Baker Ingalls and the Power of Religious Objects in ... the Study of Religion, he helps teach undergraduate modules on the Introduction ... Not only does this pertain to caricatures of the prophet Muhammad, ... propositional and performative dimensions of lived religion under a"
replace Disqualifying_Tweet = 1 if narrative1tweet == "New York State Of Mind I never thought that I would own a blog. Knew nothing about them. When Richard of Amish Stories decided he wanted to change his blog-he asked me if I would take over Jean our Old Order Mennonite lady that has posts. I said yes, but I didn't know a thing about blogs. One day Richard gave me an e-mail to go to.The passenger who could not read it was charmed with a peculiar sort of faint dimple on its surface (on the rare occasions when he did not overlook it altogether); but to the pilot that was an ITALICIZED passage; indeed, it was more than that, it was a legend of the largest capitals, with a string of shouting exclamation points at the end of it; for it meant that a wreck or a rock was buried ..."
replace Disqualifying_Tweet = 1 if narrative1tweet == "The living entities in this conditioned world are My eternal fragmental parts. Due to conditioned life, they are struggling very hard with the six senses, which include the mind."
replace Disqualifying_Tweet = 1 if narrative1tweet == (`". RAS is an important part of our brain that is used for things like breathing, sleeping, ... In other words, they will be the least creative. ... "You have to get the first third ideas our of your head to make room for the second third ..."',`"""')
replace Disqualifying_Tweet = 1 if narrative1tweet == "The participant of the women is very great of the import in come of the American of the belong in the late is of the sometimes on the very good person of the import is very from on the complete of the a qualification of the very good person"
replace Disqualifying_Tweet = 1 if narrative1tweet == "Bromfield was captivated by Wise and the impression she made upon ... But she was no mere recluse - she was well-known and even liked in Mansfield â but ... Phoebe was the youngest of ten children born to Christian and Julia Wise, ... land that would one day be the site of the Ohio State Reformatory."
replace Disqualifying_Tweet = 1 if narrative1tweet == "In November 2017 the Veterans and Human  Services Levy was renewed for another six  years, and now includes older adults as a  new population that will receive funds from  this property tax. The new name reflects this:  Veterans, Seniors and Human Services Levy.  Services to prevent seniors from falling into  poverty by expanding housing programs,  food programs"
replace Disqualifying_Tweet = 1 if narrative1tweet == "To clarify all reasonable questions students might have relative to the course objectives, as well as your expectations for their performance in class. As students leave the first meeting, they should believe in your competence to teach the course, be able to predict the nature of your instruction, and know what you will require of them.  To give you an understanding of who is taking your course and what their expectations are. THE EXPIREMENT"
replace Disqualifying_Tweet = 1 if narrative1tweet == "Family describes woman stabbed to death in Canandaigua as 'heart of this family' ... The 58-year-old woman was killed Thursday, and Dennis J. Gruttadaro, ... Gruttadaro was taken to Strong Memorial Hospital, where he remained in ... MPNno"
replace Disqualifying_Tweet = 1 if narrative1tweet == "The united states participated to this study willing women to consulate this beliefs authorised  One risk is being asked about potentially sensitive subjects"
replace Disqualifying_Tweet = 1 if narrative1tweet == "There are some risks you might experience from being in this study. One risk is being asked about potentially sensitive subjects. Another risk is the possibility of a breach of confidentiality. We might use your anonymized responses to the survey questions in future studies and it is possible that someone with high levels of technical skill and effort could determine your identity. We think th"
replace Disqualifying_Tweet = 1 if narrative1tweet == "You've probably been a participant in a number of workshops. ... to most participants' needs, and be sure you're neither going over anyone's head nor ... If so, the first thing you have to address may be their hostility or skepticism. ... This type of workshop is more than long enough for participants to get bored or overwhelmed."
replace Disqualifying_Tweet = 1 if narrative1tweet == "attempt by a Virginia church to prevent the state from barring 10 people would seriously undermine"
replace Disqualifying_Tweet = 1 if narrative1tweet == "I had presume they mean the accent from Bogota (the capital and largest city) keep in mind that there is an extreme amount of diversity in how Colombians from different regions speak, more so than, say, Chileans and probably even Mexicans..."
replace Disqualifying_Tweet = 1 if narrative1tweet == "the game from our idea ,the age of the man in floridia"
replace Disqualifying_Tweet = 1 if narrative1tweet == "Paris is a city and county seat of Lamar County, Texas, United States. As of the 2010 census, ... and banking. He was well known by local farmers, who bought aging transport mules from him. ... Three months earlier, the same judge had sentenced a 14-year-old white girl to probation for arson. ... Read Â· Edit Â· View history A century has passed since Scott and Violet Arthur fled Paris, Texas, with ... The photograph of the Arthurs' arrival at Chicago's Polk Street Depot ... burned alive after being accused of killing a 3-year-old white girl. ... I have benefited from that system as well,â said Watters, who grew up ... View Privacy Notice"
replace Disqualifying_Tweet = 1 if narrative1tweet == "First, to mentally process the message, the person to whom you are ... to hold each word and its meaning in mind long enough to combine it ... Tell your participants to whisper the statement to their neighbor only once"
replace Disqualifying_Tweet = 1 if narrative1tweet == "Participation in the discussion forums is critical for maximizing student learning in this course, both because your participation is graded and ... To post your initial response to a discussion board, simply click in reply box located below the question. ... You develop and refine your thoughts through the writing process, plus ..."
replace Disqualifying_Tweet = 1 if narrative1tweet == "I had a school friend who was once in immense depression because of not getting selected in a prestigious college.    One day he called me to meet and I went.    That was the first time in life I saw a grown teenager crying with big tears.    Seeing this I shouted at him and lectured him for more than 2 hours.    He told he will again drop out and promised that he will never give up.    Just after one year he called me to meet again but now this time he scored 220 in JEE Mains and was not stopping from giving all the credit to me.    Just after 7 months again a call came but this time it was not him but his girlfriend:    âAbid talks about nothing but youâ    âAbid told me he has only one true friend whose name is Aditya Mishra!â    âThanks for helping him when he was lostâ    At January,2018 he invited me to his sister's marriage and introduced me to his father ,mother and sister.    All of them praised me and told that he always gives all his credit for cracking the exam to me!    From my perspective I did nothing but motivated at the moment when everyone was cursing him.    From that day on realised something important:    If you don't have time to attend your friend's birthday party then please don't go.    But if he/she is in grave trouble then please go and meet him/her.    That is the moment when no one helps.    You will never know how important role you play in their life.    Since then i helped many people by being available to them not in their parties but miseries.    Now the first thing that comes to my mind when I think about myself is excellent empathetic skills and ability to push people when they are down.    Aditya Mishra    Thanks for Reading    7.6K viewsView 23 Upvoters"
replace Disqualifying_Tweet = 1 if narrative1tweet == "Participation in the discussion forums is critical for maximizing student learning in this course, both because your participation is graded and ... To post your initial response to a discussion board, simply click in reply box located below the question. ... You develop and refine your thoughts through the writing process"
replace Disqualifying_Tweet = 1 if narrative1tweet == "This time period in the life of a person can be referred to as middle age. This time span has been defined as the time between ages 45 and 60. Many changes may occur between young adulthood and this stage. The body may slow down and the middle aged might become more sensitive to diet, substance abuse, stress, and rest. Chronic health problems can become an issue along with disability or disease. Approximately one centimeter of height may be lost per decade.[8] Emotional responses and retrospection vary from person to person. Experiencing a sense of mortality, sadness, or loss is common at this age."
replace Disqualifying_Tweet = 1 if narrative1tweet == "In 1813, Williamson Dunn, Henry Ristine, and Major Ambrose Whitlock, U.S. Army, noted that the site of present-day Crawfordsville was ideal for settlement, surrounded by deciduous forest and potentially arable land, with water provided by a nearby creek, later named Sugar Creek, that was a southern tributary of the Wabash River. They returned a decade later to find at least one cabin had been built in the area. In 1821, William and Jennie Offield had built a cabin on a little creek, later to be known as Offield Creek, four miles southwest of the future site of Crawfordsville."

*comments to experimenters (5 total; 10 after session 3)*
replace Disqualifying_Tweet = 1 if narrative1tweet == "NICE I LIKE IT ITS VERY USEFULL AND I LIKE IT This participant is a woman from Grand Rapids, Michigan, who is 37 years old.  She is white.  She adheres to Orthodox beliefs.  She grew up in Michigan in the United States."
replace Disqualifying_Tweet = 1 if narrative1tweet == "This is very nice the games and very interesting a games. That very likely year man."
replace Disqualifying_Tweet = 1 if narrative1tweet == "NICE TO MEET YOU.I AM EAGER TO MEET YOU IMMEDIATELY."
replace Disqualifying_Tweet = 1 if narrative1tweet == "THIS SURVEY WAS VERY EASY AND SHORT.THIS SURVEY HAS BEEN MOST INTERESTING.I HAVE MORE EXPERIENCE THIS SURVEY"
replace Disqualifying_Tweet = 1 if narrative1tweet == "The survey is very nice and very good. United states is very large city and very good people."
replace Disqualifying_Tweet = 1 if narrative1tweet == "very easy to playing this game with this person and very easy too"
replace Disqualifying_Tweet = 1 if narrative1tweet == "good i like it survey and very nice study survey is experience"
replace Disqualifying_Tweet = 1 if narrative1tweet == "I think this survey is very super and confident and very interesting and this study is very well better and the pink heart very beautiful and perfect of the heart."
replace Disqualifying_Tweet = 1 if narrative1tweet == "it was good but it was lake of time  i really appreciate the person so did well"
replace Disqualifying_Tweet = 1 if narrative1tweet == "I think this study is very well and  very interesting an d very special and very super, this heart beautiful and very nice."

*69 total; 87 after session 3*

tab Disqualifying_Tweet

gen Suspicious_Tweet = 0

*suspicious, but not dropped
replace Suspicious_Tweet = 1 if narrative1tweet == "he belongs to non religious discrimination such that his name is filipino who is about 37 years old"
replace Suspicious_Tweet = 1 if narrative1tweet == "this participant is 37 years old does not belong to a religious denomination."
replace Suspicious_Tweet = 1 if narrative1tweet == "This participant is a woman from Galveston, texas. she is 20 years old. she is white. she does not belongs to religious denomination."
replace Suspicious_Tweet = 1 if narrative1tweet == "California, who is 38 years old.  He is Filipino.He adheres to Roman Catholic beliefs.grew up in California in the United States."
replace Suspicious_Tweet = 1 if narrative1tweet == "This  participant is a man from Bradfordwoods, Pennsylvania, who is 36 years old.  He is white.  He adheres to Hindu beliefs.  He grew up in Pennsylvania in the United States.  and he is spade participants ."
replace Suspicious_Tweet = 1 if narrative1tweet == "This participate is a woman hardy, new, who is 24years old. she is white. she does not belong to a religious denomination, she grew up in Indiana state."

replace Suspicious_Responses = Suspicious_children_first_a + Suspicious_experiment_time + Suspicious_profession + Suspicious_major_college + Suspicious_major_bachelor + Suspicious_zip_ip_distance + Suspicious_Duplicate_IP + Suspicious_Comment + Suspicious_Tweet

gen Disqualifying = 0
	replace Disqualifying = 1 if Disqualifying_Tweet == 1
	replace Disqualifying = 1 if Suspicious_profession == 1
	replace Disqualifying = 1 if Suspicious_major_college == 1
	replace Disqualifying = 1 if Suspicious_major_bachelor == 1
	replace Disqualifying = 1 if Suspicious_Comment == 1
	
tab Disqualifying


******************************************************
*** Removing Suspicious Participants from Database ***
******************************************************

drop if Disqualifying == 1
drop if Suspicious_Responses > 1

save "temp/data", replace

keep participantcode payoff payoff_plus_participation_fee sessioncode cfgparticipation_fee survey1ip survey1lat survey1long survey1sex survey1date playerbirthdate survey1marital survey1children survey1children_number survey1children_first_age survey1language survey1language_other survey1zip survey1ethnicity survey1ethnicity_choice survey1ethnicity_choice_other survey1race survey1race_indian_other survey1race_asian_other survey1race_other survey1religion survey1religion_denomination survey1religion_denom_other survey1home survey1home_other survey1guns survey1place_growing_up survey1highest_degree survey1elemen_secondary_choices survey1school_incmplt_highschool survey1high_school_choices survey1college_choices survey1after_bachelor_choices survey1major_college survey1major_bachelor survey1country_growing_up survey1us_state_grow_up survey1another_country_grow_up survey1us_citizen survey1us_citizen_options survey1work_last_week survey1profession survey1employer survey1work_tasks survey1unemployed_10_years survey1labor_union survey1household_income survey1income_group_placement survey1sixteen_yo_comparison survey1parental_compar_standards survey1social_class survey1financial_satisfaction survey1importance_democracy survey1american_pride survey1political_party survey1other_political_party survey1politcal_views survey1exec_branch_confidence survey1congress_confidence survey1supreme_court_confidence survey1military_confidence survey1police_confidence survey1banks_confidence survey1unions_confidence survey1public_ed_confidence survey1press_confidence survey1improve_condition_blacks survey1improve_condition_abroad survey1protecting_environment survey1government_redistribution survey1income_tax_level survey1death_penalty survey1affirmative_action survey1sex_before_marriage survey1same_sex_relations survey1abortion survey1people_helpful survey1people_take_advntg_of_you survey1people_trustworthy narrative1match_displayed_name narrative1tweet ios_discrete1ios_distance ios_discrete1ios_overlap ios_discrete1ios_number ios_discrt_picts1ios_distance ios_discrt_picts1ios_overlap ios_discrete_pictures1ios_number outro1comments ios_continuous1ios_distance ios_continuous1ios_overlap match0distance_sex match0distance_date match0distance_miles match0distance_ethnicity match0distance_ethnicity_choice match0distance_race match0distance_religion match0distance_religion_denomina match0distance_country_growing_u match0distance_us_state_grow_up match0distance_another_country_g match0objective_distance_correct survey1playerip survey1playerlat survey1playerlong survey1playerzip task_order Suspicious_Responses seconds_experiment survey1playerip1 survey1playerip2 survey1playerip3 survey1playerip4

export delimited using "redacted-data/data", replace
save "redacted-data/data", replace