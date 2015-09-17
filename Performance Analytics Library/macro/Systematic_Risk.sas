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
						Rf=, 
						scale= 1, 
						dateColumn= DATE,
						outSR= Risk_systematic);

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


%CAPM_alpha_beta(&returns, 
						BM= &BM, 
						Rf= &Rf, 
						dateColumn= &dateColumn,
						outBeta= alphas_and_betas);



%Standard_Deviation(&returns, 
						scale= &scale, 
						annualized= TRUE,
						dateColumn= &dateColumn, 
						outStdDev= annualized_StdDev);

data betas;
set alphas_and_betas;
if alphas_and_betas= 'alphas' then delete;
run;

data market_risk;
set annualized_StdDev;
keep &BM;
run;

proc iml;
use betas;
read all var _num_ into a[colname= names];
close betas;

use market_risk;
read all var _num_ into b;
close market_risk;

c= a#b;

c= c`;
names= names`;

create &outSR from c[rowname= names];
append from c[rowname= names];
close &outSR;
quit;

proc transpose data= &outSR out=&outSR name= stat;
id names;
run;

data &outSR;
set &outSR;
stat= "Sys_Risk";
run; 

proc datasets lib= work nolist;
delete annualized_StdDev market_risk alphas_and_betas betas;
run;
quit;

%mend;
