/*Programmed by: Owen Snyder
Programmed on: 2021-09-22
Programmed to: Create solution to HW#3  
Programmed for: ST555 001

Modified by: N/A
Modified on: N/A
Modified to: N/A*/

/*Set required paths, filrefs, librefs*/
x "cd L:\st555\Data\BookData\ClinicalTrialCaseStudy";
filename RawData ".";

x "cd L:\st555\Results";
libname Results ".";

x "cd S:\OwenFolder";
libname HW3 ".";
filename HW3 ".";

/*Set output destinations*/
ods listing close;
ods pdf file = "HW3 Snyder 3 Month Clinical Report.pdf" style = printer; 
ods rtf file = "HW3 Snyder 3 Month Clinical Report.rtf" style = Sapphire;
ods powerpoint file = "HW3 Snyder 3 Month Clinical Report.pptx" style = powerpointdark;
ods noproctitle;
options nodate;

/*Create required macros*/
%let VarAttrs = Subj   label = 'Subject Number' length = 8
                sfReas label = 'Screen Failure Reason' length = $ 50
                sfStatus label = 'Screen Failure Status (0 = Failed)' length = $ 1
                BioSex label = 'Biological Sex' length = $ 1
                VisitDate label = 'Visit Date' length = $ 10
                failDate label = 'Failure Notification Date' length = $ 10
                sbp label = 'Systolic Blood Pressure' length = 8
                dbp label = 'Diastolic Blood Pressure' length = 8
                bpUnits label = 'Units (BP)' length = $ 5
                pulse label = 'Pulse' length = 8
                pulseUnits label = 'Units (Pulse)' length = $ 9
                position label = 'Position' length = $ 9
                temp     label = 'Temperature' length = 8 format = 5.1 
                tempUnits label = 'Units (Temp)' length = $ 1
                weight label = 'Weight' length = 8
                weightUnits label = 'Units (Weight)' length = $ 2
                pain label = 'Pain Score' length = 8 
; 

%let CompOpts = method = absolute criterion =  1E-10; 

%let ValSort = by DESCENDING sfStatus sfReas DESCENDING VisitDate DESCENDING failDate Subj;

%let FtNote = Prepared by &sysUserID on &sysDate;
/*%let Visit =  3 Month Visit*/


/*footnote j=left h=10pt &FtNote; Realized this gave a warning last minute...Commenting out of code.*/

/*Input the three raw data files*/
data HW3.SITE1;
   attrib &VarAttrs;  
   infile RawData("Site 1, 3 Month Visit.txt") dlm = '09'x dsd;
   input Subj   sfReas $   sfStatus  $   BioSex  $   VisitDate  $  failDate  $  sbp  dbp  bpUnits  $  pulse  pulseUnits  $
      position  $  temp  tempUnits  $ weight  weightUnits  $  pain  ;
run;

data HW3.SITE2;
   attrib &VarAttrs;  
   infile RawData("Site 2, 3 Month Visit.csv") dlm = ',' dsd;
   input Subj   sfReas $   sfStatus  $   BioSex  $   VisitDate  $  failDate  $  sbp  dbp  bpUnits  $  pulse  pulseUnits  $
      position  $  temp  tempUnits  $ weight  weightUnits  $  pain  ;
   putlog _all_ ;
run;

data HW3.SITE3;
   attrib &VarAttrs;
   infile RawData("Site 3, 3 Month Visit.dat") dlm = '  ' dsd;
   input Subj 1-7   sfReas $ 8-58   sfStatus  $ 59-61   BioSex  $ 62  VisitDate  $ 63-72 failDate  $ 73-82  sbp 83-85  dbp 86-88  bpUnits  $ 89-94  pulse 95-97  pulseUnits  $ 98-107
      position  $ 108-120  temp 121-123  tempUnits  $ 124 weight 125-127  weightUnits  $ 128-131  pain 132  ;
   putlog Pulse = ;
run;

ods powerpoint exclude all;
/*Sort the three data files with provided sort information in DugginsRTF*/
proc sort data = HW3.SITE1;
   &ValSort;
run;

proc sort data = HW3.SITE2;
   &ValSort;
run;

proc sort data = HW3.SITE3;
   &ValSort;
run;

/*Create three PROC Contents for each data set*/
proc contents data = HW3.SITE1 varnum;
   title 'Variable-level Attributes and Sort Information: Site 1 at 3 Month Visit';
   ods exclude enginehost;
   ods exclude attributes;
run;
title;

proc contents data = HW3.SITE2 varnum;
   title 'Variable-level Attributes and Sort Information: Site 2 at 3 Month Visit';
   ods exclude enginehost;
   ods exclude attributes;
run;
title;

proc contents data = HW3.SITE3 varnum;
   title 'Variable-level Attributes and Sort Information: Site 3 at 3 Month Visit';
   ods exclude enginehost;
   ods exclude attributes;
run;
title;

ods powerpoint exclude none;
/*Create a PROC Means for patients at Site 1 with given statistics*/
proc means data = HW3.SITE1 nonobs n mean stddev median qrange maxdec = 1 ;
   title 'Selected Summary Statistics on Measurements';
   title2 'for Patients from Site 1 at 3 Month Visit';
   footnote2 j=left h=10pt 'Statistic and SAS keyword: Sample size (n), Mean (mean), Standard Deviation (stddev), Median (median), IQR (qrange)';
   class pain;
   var weight temp pulse dbp sbp;
run; 
title;
footnote;

ods exclude all;
/*Create three PROC Compares to validate my data sets with Dr. Duggins' data sets*/
proc compare base = Results.hw3dugginssite1   compare = HW3.SITE1
   out = HW3.Compare1 &CompOpts;
run;

proc compare base = Results.hw3dugginssite2   compare = HW3.SITE2
   out = HW3.Compare2 &CompOpts;
run;

proc compare base = Results.hw3dugginssite3   compare = HW3.SITE3
   out = HW3.Compare3 &CompOpts;
run;

/*Create a format for sbp and dbp from footnote information and create a library for it*/
proc format fmtlib library = HW3;
   value
        sbp 
           low - 129  = 'Acceptable'
           130 - high = 'High' 
 ;
   value 
        dbp 
           low - 79 = 'Acceptable'
           80 - high = 'High'
      
 ;
run; 


ods exclude none;
ods pdf columns = 2;
/*Create a PROC Freq for Site 2 with tables*/
proc freq data = HW3.SITE2;
   title 'Frequency Analysis of Positions and Pain Measurements by Blood Pressure Status';
   title2 'for Patients from Site 2 at 3 Month Visit';
   footnote2 j=left h=10pt 'Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80';
   options fmtsearch = (HW3); 
   format sbp sbp. dbp dbp. ;
   table Position;
   table pain*dbp*sbp / norow nocol; /*pain=0 not showing up*/
   weight pain;
run;
title;
footnote;

ods pdf columns = 1; /*set columns back to 1 for PROC Print*/

/*Print required data from given footnote for patients from Site 3*/
proc print data = HW3.SITE3 (where = ((sfstatus) eq '0')) noobs;
   title 'Selected Listing of Patients with a Screen Failure and Hypertension';
   title2 'for patients from Site 3 at 3 Month Visit';
   footnote2 j=left h=10pt 'Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80';
   footnote3 j=left h=10pt 'Only patients with a screen failure are included.';
   ods powerpoint exclude all;
   options fmtsearch = (HW3); 
   format sbp dbp;
   var Subj pain VisitDate sfStatus sfReas failDate
       BioSex sbp dbp bpUnits weight weightUnits; 
   attrib &VarAttrs;
run;
title;
footnote;

/*Close destinations*/
ods pdf close;
ods rtf close;
ods powerpoint close;
ods listing;

quit;
