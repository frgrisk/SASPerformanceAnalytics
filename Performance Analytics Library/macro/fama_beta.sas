/*---------------------------------------------------------------
* NAME: Fama_beta.sas
*
* PURPOSE: Fama beta is a beta used to calculate the loss of diversification.  It is made so that the systematic risk is
* 		   equivalent to the total portfolio risk.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set. 
* Scale- Optional. the number of periods in a year (ie daily scale= 252, monthly scale= 12, quarterly scale= 4). 
* dateColumn - Date column in Data Set. Default=DATE
* outBeta - output Data Set of asset Betas.  Default= "alphas_and_betas".
* MODIFIED:
* 7/24/2015 – DP - Initial Creation
* 10/2/2015 - CJ - Replaced PROC SQL statement with %get_number_column_names
*				   Added a scale parameter, allowing for an annualized beta term.
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro fama_beta(returns, 
						BM=, 
						scale=1, 
						dateColumn= Date,
						outBeta= fama_beta);

%local vars StdDev i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM); 
%put VARS IN CoMoments: (&vars);

%let StdDev= %ranname();

%let i= %ranname();

%Standard_Deviation(&returns, 
						annualized= FALSE,
						scale=1, 
						dateColumn= &dateColumn, 
						outStdDev= &StdDev);

data &outBeta(drop= &i &BM);
retain _STAT_;
set &StdDev;

array vars[*] &vars;
	do &i=1 to dim(vars);
		vars[&i]= vars[&i]/&BM;
	end;

_STAT_= 'Fama_Beta';
run;

proc datasets lib= work nolist;
delete &StdDev;
run;
quit;
%mend;


