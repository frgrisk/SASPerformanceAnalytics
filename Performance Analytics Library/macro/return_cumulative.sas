/*---------------------------------------------------------------
* NAME: return_cumulative.sas
*
* PURPOSE: calculate cumulative returns over a period of time. 
*   Can produce cumulative geometric or arithmetic returns from a returns data set.
*
* NOTES: Calculates  the cumulative simple or compound returns from a 
*        series of returns. 
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns
* method - {GEOMETRIC, ARITHMETIC} -- compound or simple returns.  
           Default=GEOMETRIC
* dateColumn - Date column in Data Set. Default=DATE
* outReturn - output Data Set with  cumulative returns.  
* MODIFIED:
* 5/22/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro return_cumulative(returns,
							method=GEOMETRIC,
							dateColumn=DATE,
							outReturn=cumulative_returns);

%local ret nvar;
/*Find all variable names excluding the date column and risk free variable*/
%let ret= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put RET IN return_cumulative: (&ret);

%let nvar = %sysfunc(countw(&ret));

%let i= %ranname();

data &outReturn(drop=&i);
	set &returns ;
array ret[*] &ret;
array cprod [&nvar] _temporary_;

do &i=1 to dim(ret);

	if ret[&i] = . then 
		ret[&i] = 0;

	if cprod[&i]= . then
		cprod[&i]= 0;

%if %upcase(&method) = GEOMETRIC %then %do;
	cprod[&i]= (1+ret[&i])*(1+cprod[&i])-1;
	ret[&i]= cprod[&i];
%end;

%else %if %upcase(&method) = ARITHMETIC %then %do;
	cprod[&i]= sum(cprod[&i], ret[&i]); 
	ret[&i]= cprod[&i];
%end;

%else %do;
%put ERROR: Invalid value in METHOD=&method.  Please use GEOMETRIC, or ARITHMETIC;
stop;
%end;
end;
run;
%mend;

