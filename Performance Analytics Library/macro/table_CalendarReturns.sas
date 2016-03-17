/*---------------------------------------------------------------
* NAME: table_CalendarReturns.sas
*
* PURPOSE: Table of Calendar Returns with month as column and year as row with a total value for the year
*		   in the last column.
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=Date.
* outData - Optional. Output Data Set of calendar_returns.  Default="Calendar_Returns".
* printTable - Optional. Option to print returns of all or one asset. {PRINT, NOPRINT}. Default= NOPRINT
* name - Required. Name of the variable to print if printTable= PRINT.

* MODIFIED:
* 7/14/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_CalendarReturns(returns,  
									method= DISCRETE,
									dateColumn= DATE,
									outData= Calendar_Returns, 
									printTable= NOPRINT,
									name=);

%local ret nvar name;


%let ret= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put RET IN Specific_Risk: (&ret);

%let nvar = %sysfunc(countw(&ret));

%let year_month= %ranname();

data &year_month;
set &returns;

year= year(date);
month= month(date);
run;

data &year_month(drop=i);
	set &year_month;
	by year month;
array ret[*] &ret;
array cprod [&nvar] _temporary_;

do i=1 to dim(ret);

	if ret[i] = . then 
		ret[i] = 0;

	if cprod[i]= . then
		cprod[i]= 0;

	if first.month then
			cprod[i] = 0;

		%if %upcase(&method) = DISCRETE %then %do;

		cprod[i] = (1+cprod[i])*(1+ret[i])-1;
		%end;

		%if %upcase(&method) = LOG %then %do;

		cprod[i]= sum(cprod[i], ret[i]); 
		%end;
	if last.month then
	ret[i] = cprod[i];
	end;
	if last.month;
	run;

data &year_month;
set &year_month(rename=(month=month_n));
month = put(date,monname3.);
run;

proc transpose data=&year_month out=&outData;
by year;
var &ret;
id month;
run;

data &outData(drop=i);
format _name_ $32. YEAR 4. JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC TOTAL percent12.4;
set &outData;
array mths[12] JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC;
total = 0;
do i=1 to 12;
TOTAL = (1+TOTAL) * (1+ sum(0,mths[i])) - 1;
end;
run;

proc sort data=&outData;
by _NAME_ YEAR;
run;

data &outData;
set &outData;
if _name_ = 'Date' then delete;
run;

proc datasets lib= work nolist;
delete &year_month;
run;
quit;

%if %upcase(&printTable)= PRINT %then %do;
proc print data= &outData noobs;
		title 'Aggregated Monthly Returns';
 		where _name_= "&name";
run; 
%end;
%mend;
