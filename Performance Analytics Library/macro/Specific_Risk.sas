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

%local systematic_risk StdDev;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM);
%put VARS IN Specific_Risk: (&vars);

%let systematic_risk= %ranname();
%let StdDev= %ranname();

%Systematic_Risk(&returns, 
						BM= &BM,
						Rf= &Rf,
						scale= &scale,
						dateColumn= &dateColumn,
						outSR= &systematic_risk);
data &returns;
set &returns;
keep &vars;
run;

%Standard_Deviation(&returns, 
							scale= &scale,
							annualized= TRUE, 
							dateColumn= &dateColumn,
							outStdDev= &StdDev);


proc iml;
use &systematic_risk;
read all var _num_ into a[colname= names];
close &systematic_risk;

use &StdDev;
read all var _num_ into b;
close &StdDev;

c= a#a;
d= b#b;
e= (d-c)##(1/2);

e= e`;
names= names`;

create &outSpecificRisk from e[rowname= names];
append from e[rowname= names];
close &outSpecificRisk;
quit;

proc transpose data= &outSpecificRisk out=&outSpecificRisk name= _STAT_;
id names;
run;

data &outSpecificRisk;
format _STAT_ $32.;
set &outSpecificRisk;
_STAT_= "Spec_Risk";
run; 

proc datasets lib= work nolist;
delete &systematic_risk &StdDev;
run;
quit;
%mend;