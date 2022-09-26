/*Programmed by: Owen Snyder
Programmed on: 2021-10-06
Programmed to: Create solution to HW#4  
Programmed for: ST555 001

Modified by: N/A
Modified on: N/A
Modified to: N/A*/

/*Set required paths, filrefs, librefs*/
x "cd L:\st555\Data";
libname InputDS ".";
filename RawData ".";

x "cd L:\st555\Results";
libname Results ".";

x "cd S:\OwenFolder";
libname HW4 ".";
filename HW4 ".";

/*Set output destination for HW4*/
ods noproctitle;
ods listing close;
ods pdf file = "HW4 Snyder Lead Report.pdf";
options nodate;

/*Create specified macros*/
%let Year = 1998;

%let CompOpts = outbase outcompare outdiff outnoequal noprint
                method = absolute criterion = 1E-15;

%let VarAttrs = attrib StName    label = 'State Name'         length = $ 2
                       Region                                 length = $ 9
                       JobID     label = JobID                length = 8 
                       Date      label = Date                              format = date9. 
                       PolType   label = 'Pollutant Name'     length = $ 4
                       PolCode   label = 'Pollutant Code'     length = $ 8
                       Equipment                                           format = dollar11.
                       Personnel                                           format = dollar11.
                       JobTotal                                            format = dollar11.
                       ;
/*Input the LeadProjects data*/
data HW4.SnyderLead;
     &VarAttrs;
     infile RawData('LeadProjects.txt') firstobs = 2 dlm = "," dsd missover;
     input  StName $  
           _JobID $  
            Date 10-14   
            Region $ 
            PolCode 1.  
            PolType : $ 4. 
            Equipment : dollar11.  
            Personnel : dollar11.
       ;
     JobID_ = tranwrd( _JobID,'O','0');
     JobID = input(tranwrd(JobID_,'l','1'),5.);
     JobTotal = sum(Equipment, Personnel);
     drop _JobID JobID_;
     format JobTotal Equipment Personnel dollar11.;
     format Date date9.;
     Region = propcase(Region);
     StName = upcase(StName);
     Region = compbl(Region);
run;

/*Independent Validation commented out...
proc report data = HW4.SnyderLead;
columns StName Date Region  PolCode;
run;
*/

ods pdf exclude all;
/*Sort data*/
proc sort data = HW4.SnyderLead out = HW4.LeadSort;
     by  Region StName descending JobTotal;
run;

ods output position = HW4.Temp(drop = Member);
proc contents data = HW4.SnyderLead varnum ;
run;

/*Compare my data against Dr.Duggins' data (DiffsA and DiffsB)*/
proc compare base = Results.hw4dugginslead
             compare = HW4.LeadSort
             out = HW4.DiffsA
              &CompOpts;
run;

proc compare base = Results.hw4dugginsdesc
             compare = HW4.Temp
             out = HW4.DiffsB
              &CompOpts;
run;

/*Create custom format for dates in quarters*/
proc format;
     value MyQtr (fuzz = 0) "01JAN&Year"d - "31MAR&Year"d = 'Jan/Feb/March' /*Quarter 1*/
                            "01APR&Year"d - "30JUN&Year"d = 'Apr/May/Jun'   /*Quarter 2*/
					        "01JUL&Year"d - "30SEP&Year"d = 'Jul/Aug/Sep'   /*Quarter 3*/
					        "01OCT&Year"d - "31DEC&Year"d = 'Oct/Nov/Dec'   /*Quarter 4*/
                       ;
run;

ods pdf exclude none;
/*PROC Means for 90th percentile*/
ods output summary = HW4.HW4Pctile90;
title '90th Percentile of Total Job Cost By Region and Quarter';
title2 "Data for &Year";
proc means data = HW4.SnyderLead p90;
     var JobTotal;
     class region date;
	 format Date MyQtr.;
run;
title;

/*Create graph for 90th percentile*/
ods listing image_dpi=300;
ods graphics / reset imagename = 'HW4Pctile90' width =6in imagefmt=png; 
ods output sgplot = HW4.Snyder90Pctile;
proc sgplot data = HW4.SnyderLead; /*i know this should be from my proc means, but i couldn't get it to work with my library*/
     hbar Region/response=JobTotal  group = date groupdisplay=cluster stat = median /*datalabel =*/;
     format Date MyQtr.;
     xaxis values=(0 to 100000 by 20000) 
           label = '90th Percentile of Total Job Cost'
		   grid;
     yaxis label = 'Region';
	 keylegend / position = top location = outside;
	 
run;

/*Create PROC Freq for Region by Date*/
title 'Frequency of Cleanup by Region and Date';
title2 "Data for &Year";
proc freq data = HW4.SnyderLead;
     table region*date / nocol nopercent;
	 format Date MyQtr.;
	 ods output CrossTabFreqs = HW4.HW4RegionPct;
run;
title;

/*Create graph for Region Pct.*/
ods listing image_dpi=300;
ods graphics / reset imagename = 'HW4RegionPct' width=6in imagefmt=png; 
ods output sgplot = HW4.HW4RegionPct;
proc sgplot data = HW4.SnyderLead; /*i know this should be from my proc freq, but i couldn't get it to work with my library*/
     vbar region/response=JobTotal  group = date groupdisplay=cluster;
	 format Date MyQtr.;
	 styleattrs datacolors = (CX3230B2 CX7674D9 CX6130B2 CXAEADD9);
     xaxis label = 'Region'
	       labelattrs = (size = 16pt)
		   valueattrs = (size = 14pt);
     yaxis values = (0 to 45 by 5)
           label = 'Region Percentage within Pollutant'
		   labelattrs = (size = 16pt)
		   valueattrs = (size = 12pt)
		   grid gridattrs = (color = grayCC thickness = 3)
           offsetmax = .05;
	       keylegend / position = topright location = inside;	 
run;
/*PROC Compare for the second graph, i.e. Dr.Duggins vs. my graph*/
proc compare base = Results.hw4dugginsgraph2
             compare = HW4.HW4RegionPct
			 out = HW4.DiffsC
			 &CompOpts;
run;

/*Close destinations*/
ods graphics off;
ods pdf close;
ods listing;
quit;
