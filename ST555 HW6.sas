/*Programmed by: Owen Snyder
Programmed on: 2021-10-15
Programmed to: Create solution to HW#6  
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
libname HW6 ".";
filename HW6 ".";

/* Set required options and outputs*/
ods listing close;
ods pdf file = "HW6 Snyder IPUMS Report.pdf" dpi = 300;
ods graphics on;
options nodate;

/*Create macro variable for validations*/
%let CompOpts = outbase outcompare outdiff outnoequal noprint
                method = absolute criterion = 1E-15;

/*Read in Cities data set*/
data HW6.Cities;
  infile RawData("Cities.txt") dlm = '09'x  dsd   firstobs = 2;
  input _City : $ 40. CityPop : comma6. ;
  _City = tranwrd(_City, '/','-');
run;

/*Read in States data set*/
data HW6.States; 
  infile RawData("States.txt") dlm = '09'x  /*dsd*/   firstobs = 2;
  input Serial State $ 20.  _City : $ 40. ;
run;

/*Read in Contract data set*/
data HW6.Contract;
  infile RawData("Contract.txt") dlm = '09'x   firstobs = 2; 
  input Serial Metro CountyFIPS : $ 3.  MortPay : dollar6. (HHI  HomeVal) ( : comma10.);
run;

/*Read in Mortgaged data set*/
data HW6.Mortgaged;
  infile RawData("Mortgaged.txt") dlm = '09'x   firstobs = 2 missover;
  input Serial Metro CountyFIPS : $ 3.  MortPay : dollar6. (HHI  HomeVal) (: comma10.);
run;

/*Sort City data set by city variable*/
proc sort data = HW6.Cities;
  by _City;
run;

/*Sort States data set by city variable*/
proc sort data = HW6.States;
  by _City;
run;

/*Match-Merge Cities and States data sets*/
data HW6.MatchMergeCS;
  merge HW6.Cities 
        HW6.States;
  by _City;
run;

/*Concatenate the Renters, FreeClear, Contract, and Mortgaged data sets*/
data HW6.Concat;
  set InputDS.Renters (rename = (FIPS = CountyFIPS) in = Renters)
      InputDS.FreeClear (in = FC)
	  HW6.Contract (in = Cntrc)
	  HW6.Mortgaged (in = Mort);
  length Ownership $ 6
         MortStat  $ 45;
  if renters then do; 
  Ownership = 'Rented';
  MortStat = 'N/A';
end;
  else do;
  Ownership = 'Owned';
end;
  if FC then MortStat = 'No, owned free and clear';
  if Cntrc then MortStat = 'Yes, contract to purchase';
  if Mort then MortStat = 'Yes, mortgaged/ deed of trust or similar debt';
run;

/*Sort the Match-Merge Cities and States data set by Serial*/ 
proc sort data = HW6.MatchMergeCS;
  by Serial;
run;

/*Sort the concatenated data set by Serial*/
proc sort data = HW6.Concat;
  by Serial;
run;

/*Use PROC FORMAT to derive the variable, MetroDesc*/
proc format /*library = HW6*/;
  value MetroDesc
                  0 = 'Indeterminable'
			      1 = 'Not in a Metro Area'
			      2 = 'In Central/Principal City'
			      3 = 'Not in Central/Principal City'
			      4 = 'Central/Principal Indeterminable'
			      ;
run;

/*Merge the Match-Merge Cities and States data set w/ the Concatenated data set*/
data HW6.HW6SnyderIpums2005;
  attrib Serial                                         label = 'Household Serial Number'
         CountyFIPS  length = $ 3                       label = 'County FIPS Code'
	     Metro                                          label = 'Metro Status Code'
	     MetroDesc   length = $ 32                      label = 'Metro Status Description'
	     CityPop                   format = comma6.     label = 'City Population (in 100s)'
	     MortPay                   format = dollar6.    label = 'Monthly Mortgage Payment'
	     HHI                       format = dollar10.   label = 'Household Income'
	     HomeVal                   format = dollar10.   label = 'Home Value'
         State       length = $ 20                      label = 'State, District, or Territory'
	     City        length = $ 40                      label = 'City Name'
         MortStat    length = $ 45                      label = 'Mortgage Status'
         Ownership   length = $ 6                       label = 'Ownership Status'
  ;
  merge HW6.MatchMergeCS (rename = (_City = City))
        HW6.Concat;
  by Serial;
  MetroDesc = put(Metro, MetroDesc.);
  if HomeVal eq 9999999 then HomeVal = .R;
  if HomeVal eq . then HomeVal = .M;
run;

ods pdf exclude all;
/*PROC CONTENTS to set up comparison*/
ods output position = HW6.HW6SnyderIpums2005DESC(drop = Member);
proc contents data = HW6.HW6SnyderIpums2005 varnum;
run;

/*Validate Dr.Duggins' cleaned and combined data set against mine*/
proc compare base = Results.hw6dugginsipums2005
             compare = HW6.HW6SnyderIpums2005
             out = HW6.HW6SnyderIPUMScomp
             &CompOpts;
run;

/*Validate the descriptor portion of Dr. Duggins' set against mine*/
proc compare base = Results.hw6dugginsdesc
             compare = HW6.HW6SnyderIpums2005DESC
             out = HW6.HW6SnyderipumsDESCCompared
             &CompOpts;
run;

ods pdf exclude none;
/*ods listing;*/
title 'Listing of Households in NC with Incomes Over $500,000';
proc report data = HW6.HW6SnyderIpums2005 nowd;
  columns City Metro MortStat HHI HomeVal;
  where HHI gt 500000 and State = 'North Carolina';
run;
title;

ods trace on;
ods pdf startpage = never;
proc univariate data = HW6.HW6SnyderIpums2005;
  var CityPop MortPay HHI HomeVal;
  ods select Univariate.CityPop.BasicMeasures
             Univariate.CityPop.Quantiles
             Univariate.CityPop.Histogram.Histogram
             Univariate.MortPay.Quantiles
		     Univariate.HHI.BasicMeasures
             Univariate.HHI.ExtremeObs
             Univariate.HomeVal.BasicMeasures
		     Univariate.HomeVal.ExtremeObs
		     Univariate.HomeVal.MissingValues
		     ;
  histogram CityPop / kernel(c = 0.79);
run;
ods trace off;

ods pdf startpage = now;
/*Create required graph via PROC SGPLOT*/
ods listing image_dpi = 300;
ods graphics / reset width = 5.5in; 
title 'Distribution of City Population';
title2 '(For Households in a Recognized City)';
footnote j = left 'Recognized cities have a non-zero value for City Population.';
proc sgplot data = HW6.HW6SnyderIpums2005 (where = (City ne 'Not in identifiable city (or size group)'));
  histogram CityPop / scale = proportion;
  xaxis label = 'City Population (in 100s)';
  yaxis display = (nolabel) valuesformat = percent6.;
  density CityPop / type = kernel lineattrs = (color = CXFF0000 thickness = 2); 
  keylegend / location = inside position = topright;
run;
title;
footnote;

ods listing image_dpi = 300;
ods graphics / reset width = 5.5in; 
/*Create required graph via PROC SGPANEL*/
title 'Distribution of Household Income Stratified by Mortgage Status';
footnote 'Kernel estimate parameters were determined automatically.';
proc sgpanel data = HW6.HW6SnyderIpums2005 noautolegend;
  panelby MortStat / novarname; 
  histogram HHI /  scale = proportion;
  density HHI / type = kernel lineattrs = (color = CXFF0000);
  rowaxis display = (nolabel) valuesformat = percent6.;
  colaxis label = 'Household Income' valuesformat = comma9.;
run;
title;
footnote;

/*Close destinations*/
ods pdf close;
ods listing;
quit;
