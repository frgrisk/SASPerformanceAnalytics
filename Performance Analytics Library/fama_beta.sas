/*---------------------------------------------------------------
* NAME: Fama_beta.sas
*
* PURPOSE: Fama beta is a beta used to calculate the loss of diversification.  It is made so that the systematic risk is
* 		   equivalent to the total portfolio risk.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set. 
* dateColumn - Date column in Data Set. Default=DATE
* outBeta - output Data Set of asset Betas.  Default= "alphas_and_betas".
* MODIFIED:
* 7/24/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro fama_beta(returns, 
						BM=, 
						dateColumn= Date,
						outBeta= fama_beta);

/***********************************
*Figure out 2 level ds name of RETURNS
************************************/
%local lib ds vars rename;

%let lib= %scan(&returns, 1, %str(.));
%let ds= %scan(&returns, 2, %str(.));
%if &ds= "" %then %do;
%let ds= &lib;
%let lib= work;
%end;
%put lib:&lib ds:&ds;

%Standard_Deviation(&returns, 
						annualized= FALSE,
						scale=1, 
						dateColumn= &dateColumn, 
						outStdDev= StdDev);

proc sql noprint;
select name
	into :fama separated by ' '
	     from sashelp.vcolumn
	where libname = upcase("work")
	 and memname = upcase("StdDev")
 	and type = "num"
 	and upcase(name) ^= upcase("&dateColumn")
	and upcase(name) ^= upcase("&BM");
quit;

data &outBeta(drop= i &BM);
set StdDev;

array fama[*] &fama;
	do i=1 to dim(fama);
		fama[i]= fama[i]/&BM;
	end;
run;
%mend;


