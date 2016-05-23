/*---------------------------------------------------------------
* NAME: Fama_beta.sas
*
* PURPOSE: Fama beta is a beta used to calculate the loss of diversification.  It is made so that the systematic risk is
* 		   equivalent to the total portfolio risk.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=Date
* outData - Optional. Output Data Set of asset Betas.  Default= fama_beta.
* MODIFIED:
* 7/24/2015 – DP - Initial Creation
* 10/2/2015 - CJ - Replaced PROC SQL statement with %get_number_column_names
*				   Added a scale parameter, allowing for an annualized beta term.
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro fama_beta(returns, 
						BM=, 
						scale= 1, 
						VARDEF = DF, 
						dateColumn= DATE,
						outData= fama_beta);

%local vars StdDev i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM); 
%put VARS IN CoMoments: (&vars);

%let StdDev= %ranname();

%let i= %ranname();

%Standard_Deviation(&returns, 
						annualized= FALSE,
						scale=1, 
						VARDEF = &VARDEF, 
						dateColumn= &dateColumn, 
						outData= &StdDev);

data &outData(drop= &i &BM);
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


