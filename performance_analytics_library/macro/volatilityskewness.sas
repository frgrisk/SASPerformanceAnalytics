/*---------------------------------------------------------------
* NAME: volatilityskewness.sas
*
* PURPOSE: Calculate volatility skewness or variability skewness.
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. Default=0
* option- Optional. {VOLATILITY, VARIABILITY}.  Choose "VOLATILITY" to calculate the volatility skewness, 
*					 "VARIABILITY" to calculate variability skewness. Default=VOLATILITY
* group - Optional. Specifies to choose full observations or subset observations as 'n' in the divisor. {FULL, SUBSET}
*		  Default=FULL
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. output Data Set with downside risks.  Default="volatilityskewness"
*
* MODIFIED:
* 7/18/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro volatilityskewness(returns,
							MAR= 0,
							option=VOLATILITY,
							group=FULL,
							dateColumn= DATE,
							outData= volatilityskewness);

%local vars nvars _up _down i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &MAR);
%put VARS IN volatilityskewness: (&vars);

%let nvars = %sysfunc(countw(&vars));
%let i=%ranname();
%let _up=%ranname();
%let _down=%ranname();

%if %upcase(&option)=VOLATILITY %then %do;
	%upside_risk(&returns, MAR=&MAR, option=VARIANCE, group=&group, dateColumn=&dateColumn, outData=&_up);
	%downside_risk(&returns, MAR=&MAR, option=VARIANCE, group=&group, dateColumn=&dateColumn, outData=&_down);
%end;
%if %upcase(&option)=VARIABILITY %then %do;
	%upside_risk(&returns, MAR=&MAR, option=RISK, group=&group, dateColumn=&dateColumn, outData=&_up);
	%downside_risk(&returns, MAR=&MAR, option=RISK, group=&group, dateColumn=&dateColumn, outData=&_down);
%end;

data &outData;
	format _STAT_ $32.;
	set &_up &_down end=last;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=lag(vars[&i])/vars[&i];
	end;
	%if %upcase(&option)=VOLATILITY %then %do;
		_STAT_="VolstilitySkewness";
	%end;
	%if %upcase(&option)=VARIABILITY %then %do;
		_STAT_="VariabilitySkewness";
	%end;
	if last then output;
	drop &i;
run;

proc datasets lib = work nolist;
	delete &_up &_down;
run;
quit;
%mend;





