/*---------------------------------------------------------------
* NAME: Specific_Risk.sas
*
* PURPOSE: Specific risk is the standard deviation of the error term in the regression equation.
*
* NOTES: This is not the same definition as the one given by Michael Jensen. Market risk is the standard deviation of
the benchmark. The systematic risk is annualized.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* Scale- required.  Number of periods per year used in the calculation. Default= 1.
* dateColumn - Date column in Data Set. Default=DATE
* outSpecificRisk - output Data Set of systematic risk.  Default="Risk_specific".

* MODIFIED:
* 7/14/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Specific_Risk(returns, 
							BM=, 
							Rf=0,
							scale= 1,
							dateColumn= DATE,
							outSpecificRisk= Risk_specific);

%local lib ds;

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

%Systematic_Risk(&returns, 
						BM= &BM,
						Rf= &Rf,
						scale= &scale,
						dateColumn= &dateColumn,
						outSR= systematic_risk);

data vars_returns;
set &returns;
keep &vars;
run;

%Standard_Deviation(vars_returns, 
							scale= &scale,
							annualized= TRUE, 
							dateColumn= &dateColumn,
							outStdDev= new_StdDev);

proc iml;
use systematic_risk;
read all var _num_ into a[colname= names];
close systematic risk;

use new_StdDev;
read all var _num_ into b;
close new_StdDev;

c= a#a;
d= b#b;
e= (d-c)##(1/2);

e= e`;
names= names`;

create &outSpecificRisk from e[rowname= names];
append from e[rowname= names];
close &outSpecificRisk;
quit;

proc transpose data= &outSpecificRisk out=&outSpecificRisk name= stat;
id names;
run;

data &outSpecificRisk;
set &outSpecificRisk;
stat= "SpecRisk";
run; 

proc datasets lib= work nolist;
delete systematic_risk new_StdDev vars_returns;
run;
%mend;