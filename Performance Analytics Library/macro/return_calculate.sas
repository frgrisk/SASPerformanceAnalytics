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
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_calculate(prices,
						method=DISCRETE,
						dateColumn=DATE,
						updateInPlace=TRUE,
						outReturn=returns);

%local lib ds vars;

/***********************************
*Figure out 2 level ds name of PRICES
************************************/
%let lib = %scan(&prices,1,%str(.));
%let ds = %scan(&prices,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;


/*******************************
*Get numeric fields in data set
*******************************/
proc sql noprint;
select name
	into :vars separated by ' '
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

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
	(drop=i);
set &prices;
array vars[*] &vars;
do i=1 to dim(vars);
	%if %upcase(&method) = LOG %then %do;
		vars[i] = log(vars[i]/lag(vars[i]));
	%end;
	%else %if %upcase(&method) = DISCRETE %then %do;
		vars[i] = vars[i]/lag(vars[i]) - 1;
	%end;
	%else %do;
		%put ERROR: Invalid value in METHOD=&method.  Please use LOG, or DISCRETE;
		stop;
	%end;
end;
run;
%mend;
