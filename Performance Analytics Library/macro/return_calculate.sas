/*---------------------------------------------------------------
* NAME: return_calculate.sas
*
* PURPOSE: calculate simple or compound returns from prices
*
* NOTES: Calculates either the simple or compound returns from a 
*        series of prices.  Option to update the table in place
*        or create new output;
*
* MACRO OPTIONS:
* prices - required.  Data Set containing prices
* method - {LOG, DISCRETE} -- compound or simple returns.  
           Default=DISCRETE
* dateColumn - Date column in Data Set. Default=DATE
* updateInPlace - {TRUE, FALSE} -- update the &prices Data Set in place.
*                 Default=TRUE
* outReturn - output Data Set with returns.  Only used if updateInPlace=FALSE 
*             Default="returns"
*
* MODIFIED:
* 5/5/2015 – DP - Initial Creation
* 10/2/2015 - CJ - Replaced PROC SQL with %get_number_column_names
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_calculate(prices,
						method=DISCRETE,
						dateColumn=DATE,
						updateInPlace=TRUE,
						outReturn=returns);

%local vars nv i;
/*Find all variable names excluding the date column and risk free variable*/
%let vars= %get_number_column_names(_table= &prices, _exclude= &dateColumn); 
%put VARS IN return_calculate: (&vars);
/*Find number of columns in the data set*/
%let nv= %sysfunc(countw(&vars));
/*Define counters for array operations*/
%let i= %ranname();

/*****************
* Calculate Return
*****************/
data 
	%if %upcase(&updateInPlace) = TRUE %then %do;
		&prices
	%end;
	%else %do;
		&outReturn
	%end;
	(drop=&i);
set &prices;
array vars[*] &vars;
do &i=1 to &nv;
	%if %upcase(&method) = LOG %then %do;
		vars[&i] = log(vars[&i]/lag(vars[&i]));
	%end;
	%else %if %upcase(&method) = DISCRETE %then %do;
		vars[&i] = vars[&i]/lag(vars[&i]) - 1;
	%end;
	%else %do;
		%put ERROR: Invalid value in METHOD=&method.  Please use LOG, or DISCRETE;
		stop;
	%end;
end;
run;
%mend;
