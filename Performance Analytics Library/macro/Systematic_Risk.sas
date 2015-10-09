/*---------------------------------------------------------------
* NAME: Systematic_Risk.sas
*
* PURPOSE: Systematic risk as defined by Bacon(2008) is the product of beta by market risk.
*
* NOTES: This is not the same definition as the one given by Michael Jensen. Market risk is the standard deviation of
the benchmark. The systematic risk is annualized.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set. 
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* Scale- number of periods in a year (daily scale= 252, monthly scale= 12, quarterly scale= 4).
* dateColumn - Date column in Data Set. Default=DATE
* outSR - output Data Set of systematic risk.  Default="Risk_systematic".

* MODIFIED:
* 7/14/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Systematic_Risk(returns,
						BM=, 
						Rf=0, 
						scale= 1, 
						dateColumn= DATE,
						outSR= Risk_systematic);

%local CAPMvars ann_StdDev betas market_risk ;

%let CAPMvars= %ranname();
%let ann_StdDev= %ranname();
%let betas= %ranname();
%let market_risk= %ranname();


%CAPM_alpha_beta(&returns, 
						BM= &BM, 
						Rf= &Rf, 
						dateColumn= &dateColumn,
						outBeta= &CAPMvars);



%Standard_Deviation(&returns, 
						scale= &scale, 
						annualized= TRUE,
						dateColumn= &dateColumn, 
						outStdDev= &ann_StdDev);

data &betas;
set &CAPMvars;
if _STAT_= 'alphas' then delete;
run;

data &market_risk;
set &ann_StdDev;
keep &BM;
run;

proc iml;
use &betas;
read all var _num_ into a[colname= names];
close &betas;

use &market_risk;
read all var _num_ into b;
close &market_risk;

c= a#b;

c= c`;
names= names`;

create &outSR from c[rowname= names];
append from c[rowname= names];
close &outSR;
quit;

proc transpose data= &outSR out=&outSR name= _STAT_;
id names;
run;

data &outSR;
set &outSR;
_STAT_= "Sys_Risk";
run; 

proc datasets lib= work nolist;
delete &ann_StdDev &market_risk &CAPMvars &betas;
run;
quit;

%mend;
