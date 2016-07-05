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
* prices - Required.  Data Set containing prices
* method - Optional. Compound or simple returns.  {LOG, DISCRETE} 
           Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* updateInPlace - Optional. Update the &prices Data Set in place. {TRUE, FALSE}
*                 Default=TRUE
* outData - Optional. Output Data Set with returns.  Only used if updateInPlace=FALSE 
*             Default="returns"
*
* MODIFIED:
* 5/5/2015 – DP - Initial Creation
* 10/2/2015 - CJ - Replaced PROC SQL with %get_number_column_names
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_calculate(prices,
						method= DISCRETE,
						dateColumn= DATE,
						updateInPlace= TRUE,
						outData= returns);

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
		&outData
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
