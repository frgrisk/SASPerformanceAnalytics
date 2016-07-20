/*---------------------------------------------------------------
* NAME: SkewnessKurtosisRatio.sas
*
* PURPOSE: Calculate skewness-kurtosis ratio
*
* NOTES: Watanabe(2006) suggested using skewness-kurtosis ratio in conjunction with 
*        Sharpe ratio to rank portfolios. Higher rather than lower ratios are preferred.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with skewness-kurtosis ratio.  Default="SKratio".
*
* MODIFIED:
* 7/20/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro SkewnessKurtosisRatio(returns,
							  VARDEF= DF,
							  dateColumn= DATE,
						      outData= SKratio);
							
%local vars i _skew _kurt;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN SkewnessKurtosisRatio: (&vars);

%let _skew= %ranname();
%let _kurt= %ranname();

%let i = %ranname();

proc means data=&returns skewness kurtosis VARDEF=&VARDEF noprint;
	output out=&_skew(keep=&vars) skew=;
	output out=&_kurt(keep=&vars) kurt=;
run;

data &outData (keep= _stat_ &vars);
	format _STAT_ $32.;
	set &_skew &_kurt end=last;

	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= lag(ret[&i])/(ret[&i]+3);
	end;
	_STAT_= 'Skewness-Kurtosis Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &_kurt &_skew;
run;
quit;

%mend;
