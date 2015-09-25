/*---------------------------------------------------------------
* NAME: table_SpecificRisk.sas
*
* PURPOSE: Table of specific risk, systematic risk, and total risk.
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return. 
* dateColumn - Date column in Data Set. Default=DATE
* outTable - output Data Set of systematic risk.  Default="table_SpecificRisk".
* printTable- option to print output data set.  {PRINT, NOPRINT} [Default= NOPRINT]

* MODIFIED:
* 7/14/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_SpecificRisk(returns, 
							BM=, 
							Rf=0,
							scale= 1,
							dateColumn= DATE,
							outTable= table_SpecificRisk,
							printTable= NOPRINT);

%local lib ds vars;

/***********************************
*Figure out 2 level ds name of PRICES
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;

%Specific_Risk(&returns, 
						BM= &BM, 
						Rf= &Rf, 
						scale= &scale,
						dateColumn= &dateColumn, 
						outSpecificRisk= specific_risk);

%Systematic_Risk(&returns,
						BM=&BM, 
						Rf=&Rf, 
						scale= &scale, 
						dateColumn= &dateColumn,
						outSR= systematic_risk);

proc sql noprint;
select name
	into :vars separated by ' '
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn")
	  and upcase(name) ^= upcase("&BM")
	  and upcase(name) ^= upcase("&Rf");
quit;

data vars_returns;
set &returns;
keep &vars;
run;

%Standard_Deviation(vars_returns, 
							scale= &scale,
							annualized= TRUE,
							dateColumn= &dateColumn,
							outStdDev= total_risk);

data total_risk;
set total_risk;
stat= 'Tot_Risk';
run;

data &outTable;
set specific_risk systematic_risk total_risk;
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outTable noobs;
	run;
%end;

proc datasets lib= work nolist;
delete vars_returns systematic_risk specific_risk total_risk;
run;
quit;

%mend;

