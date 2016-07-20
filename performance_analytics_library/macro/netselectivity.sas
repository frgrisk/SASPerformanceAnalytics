/*---------------------------------------------------------------
* NAME: netselectivity.sas
*
* PURPOSE: Calculate net selectivity which is the difference of selectivity and diversification.
*
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
*         Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Kappa.  Default="NetSelectivity".
*
*
* MODIFIED:
* 7/17/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro netselectivity(returns, 
							BM=, 
							Rf= 0, 
							scale= 1,
							method= DISCRETE,
							dateColumn= DATE, 
							outData= NetSelectivity);

%local vars nvars _ret_ann _famabeta _beta _dif_ann _d _Jalpha i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM &Rf); 
%put VARS IN NetSelectivity: (&vars);
%let nvars = %sysfunc(countw(&vars));

%let _ret_ann= %ranname();
%let _dif_ann= %ranname();
%let _famabeta=%ranname();
%let _beta=%ranname();
%let _Jalpha=%ranname();
%let _d=%ranname();
%let i= %ranname();

%return_annualized(&returns, scale=&scale, method=&method, dateColumn=&dateColumn, outData=&_ret_ann);
%fama_beta(&returns, BM=&BM, dateColumn=&dateColumn, outData=&_famabeta);
%capm_alpha_beta(&returns, BM=&BM, Rf=&Rf, dateColumn=&dateColumn, outData=&_beta);
%capm_jensenalpha(&returns, BM=&BM, Rf=&Rf, scale=&scale, method=&method, dateColumn=&dateColumn, outData=&_Jalpha);

data &_dif_ann;
	set &_ret_ann;
	array ret[*] &vars;

	do &i=1 to &nvars;
		ret[&i]=&BM-&Rf;
	end;
	keep _stat_ &vars;
run;

data &_d;
	set &_famabeta(keep=_stat_ &vars) &_beta(firstobs=2) &_dif_ann end=last;
	array ret[*] &vars;

	do &i=1 to &nvars;
		ret[&i]=(LAG2(ret[&i])-LAG(ret[&i]))*ret[&i];
	end;
	if last then output;
	drop &i;
run;

data &outData;
	set &_d &_Jalpha end=last;
	array ret[*] &vars;

	do &i=1 to &nvars;
		ret[&i]=(ret[&i])-LAG(ret[&i]);
	end;
	_STAT_="NetSelectivity";
	if last then output;
	drop &i;
run;

proc datasets lib= work nolist;
delete &_ret_ann &_famabeta &_beta &_dif_ann &_Jalpha &_d;
run;
quit;
%mend;


