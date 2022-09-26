/*Programmed by: Owen Snyder
Programmed on: 2021-10-18
Programmed to: Create solution to HW#5  
Programmed for: ST555 001

Modified by: N/A
Modified on: N/A
Modified to: N/A*/

/*Set required paths, filerefs, librefs*/
x "cd L:\st555\Data";
libname InputDS ".";
filename RawData ".";

x "cd L:\st555\Results";
libname Results ".";

x "cd S:\OwenFolder";
/*libname HW4 ".";*/
libname HW5 ".";
filename HW5 ".";

/*Set options*/
options nobyline;
ods noproctitle;
options fmtsearch = (InputDS);
options fmtsearch = (HW5);  /*Did not set to HW4 b/c i made a small change to the HW4 MyQtr 
                            format but the TA will still have last weeks copy of the format*/

/*Set up outputs*/
ods listing;
ods pdf file = "HW5 Snyder Projects Graphs.pdf" startpage = never;
ods graphics on;

/*Create macro for Variable Attributes and Compare Options*/
%let VarAttrs = attrib 
                       StName    length = $ 2                    label = "State Name"
                       Region    length = $ 9
                       JobID                                     label = ""
                       Date                   format = date9.
                       PolType   length = $ 4                    label = "Pollutant Name"
                       PolCode   length = $ 8                    label = "Pollutant Code"
                       Equipment
                       Personnel
                       JobTotal               format = dollar11.
;

%let CompOpts = outbase outcompare outdiff outnoequal noprint
                method = absolute criterion = 1E-9;

/*Data step for O3 Projects*/
data HW5.O3Projects;
  infile RawData("O3Projects.txt") dsd firstobs = 2 missover;
  if _N_ = 191 then do;
  input StName : $ 2. 
       JobID $  
       Date 10-14   
       Region $   
       PolType : $ 4. 
       Equipment : dollar11.  
       Personnel : dollar11.
       ;
  end;
  else do; 
  input StName : $ 2. 
       JobID $  
       Date 10-14   
       Region $ 
       PolCode $ 1.  
       PolType : $ 4. 
       Equipment : dollar11.  
       Personnel : dollar11.
       ;
end;
run;

/*Data step for CO Projects*/
data HW5.COProjects1;
  infile RawData("COProjects.txt") dsd firstobs=2 missover;
  input StName : $ 2.
      JobID  $ 
	  Date 10-14
	  Region $
	  Equipment : dollar11. 
      Personnel : dollar11.
;
run;

/*Data step for SO2 Projects*/
data HW5.SO2Projects;
  infile RawData("SO2Projects.txt") dsd firstobs=2 missover;
  input StName : $ 2.
      JobID $
	  Date 10-14
	  Region $ 
	  Equipment : dollar11.  
      Personnel : dollar11.
;
run;

/*Data step for TSP Projects*/
data HW5.TSPProjects;
  infile RawData("TSPProjects.txt") dsd firstobs=2 missover;
  if _N_ = 571 then do;
  input StName : $ 2.
      JobID  $
	  Region $ 
	  Equipment : dollar11.  
      Personnel : dollar11.
;
end;
  else do;
  input StName : $ 2.
      JobID  $
	  Date 10-14
	  Region $ 
	  Equipment : dollar11.  
      Personnel : dollar11.
;
end;
run;

/*Concatenation of all five Projects with cleaning*/
data HW5.HW5SnyderProjects(label = Cleaned and Combined EPA Projects Data);
  &VarAttrs;
  set HW5.O3Projects
    HW5.COProjects1 (in = CO)
	HW5.SO2Projects (in = SO2)
	HW5.TSPProjects (in = TSP)
	HW5.LeadProjects (in = LeadProjects rename = (JobID = _JobID)) /*see above about HW4 libref*/
	;
  if LeadProjects then JobID = put(_JobID, 5.);
  if CO then do; 
   PolType = "CO";
   PolCode = "3";
   end;
  if SO2 then do;
   PolType = "SO2";
   PolCode = "4";
   end;
  if TSP then do;
   PolType = "TSP";
   PolCode = "1";
   end;
  JobTotal = sum(equipment, personnel);
  Region = propcase(Region);
  StName = upcase(StName);
  JobID = tranwrd(JobID,'O','0');
  JobID = tranwrd(JobID,'l','1'); 
  drop _JobID;
run; 

ods pdf exclude all;
/*PROC SORT to sort data based on required sort information*/
proc sort data = HW5.HW5SnyderProjects out = HW5.HW5Sorted;
  by PolCode Region descending JobTotal descending Date JobID;
run;

ods output position = HW5.hw5snyderdesc(drop = Member);
proc contents data = HW5.HW5SnyderProjects varnum;
run;

/*Validate Dr.Duggins' cleaned and combined data set against mine*/
proc compare base = Results.hw5dugginsprojects
             compare = HW5.HW5Sorted
             out = HW5.HW5SnyderProjectsCompared
             &CompOpts;
run;

/*Validate the descriptor portion of Dr. Duggins' set against mine*/
proc compare base = Results.hw5dugginsprojectsdesc
             compare = HW5.hw5snyderdesc
             out = HW5.HW5SnyderProjectsdescCompared
             &CompOpts;
run;

ods output summary = hw5.stats2575;
/*PROC MEANS to create a data set that includes the 25th and 75th Percentiles*/
proc means data = HW5.HW5Sorted p25 p75;
  class region date;
  var jobtotal;
  by PolCode;
  id PolCode;
  format date MyQtr.;
run;

/*PROC SGPLOT to create the required Bar Charts*/
ods pdf exclude none;
ods listing image_dpi = 300;
ods graphics / reset imagename = 'HW5SnyderPctPlot' width =6in imagefmt=png;
ods output sgplot = HW5.HW5SnyderPctPlot;
title '25th and 75th Percentiles of Total Job Cost';
title2 'By Region and Controlling for Pollutant = #byval1';
title3 h = 8pt 'Excluding Records where Region or Pollutant Code were Unknown (Missing)';
footnote j = left 'Bars are labeled with the number of jobs contributing to each bar';
proc sgplot data = HW5.stats2575;
  vbar Region  / response = JobTotal_p75  
      group = Date groupdisplay = cluster 
      datalabel = nobs datalabelattrs = (size = 7pt)
      name = 'vbarGraph1'
      outlineattrs = (color = CX000000)
      grouporder = ascending;  
      styleattrs datacolors = (CX00FF00 CXFF8000 CXB090D0 CXFF0055);
  vbar Region / response = JobTotal_p25 
      group = Date groupdisplay = cluster
      name = 'vbarGraph2'
	  fillattrs = (color = CX4F4F4F)
      outlineattrs = (color = CX000000)
      grouporder = ascending;
  keylegend 'vbarGraph1' / location = outside position = top  opaque;
  yaxis grid gridattrs = (thickness = 3 color = gray88)
        label = "";
  xaxis display = (NoLabel); 
  by PolCode;
  where PolCode not in (' ');
  format JobTotal_p75 JobTotal_p25 dollar6.;
  /*format PolCode $PolMap.;  Calling the format from InputDS did not work?*/
run;
title;
footnote;

/*Close destinations*/
ods graphics off;
ods listing;
ods pdf close;
quit;
