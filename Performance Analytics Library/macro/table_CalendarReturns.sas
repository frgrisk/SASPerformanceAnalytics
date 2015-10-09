/*---------------------------------------------------------------
* NAME: table_CalendarReturns.sas
*
* PURPOSE: Table of Calendar Returns with month as column and year as row with a total value for the year
*		   in the last column.
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* method- required.  Choose to implement geometric or arithmetic chaining. Default= GEOMETRIC.
* dateColumn - Date column in Data Set. Default=DATE.
* outCalendarReturns - output Data Set of calendar_returns.  Default="Calendar_Returns".
* printTable- option to print returns of all or one asset. Options[PRINT, NOPRINT].
* name- option to print single variable, name of the variable to print if printTable= PRINT.

* MODIFIED:
* 7/14/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_CalendarReturns(returns,  
									method= GEOMETRIC,
									dateColumn= Date,
									outCalendarReturns= Calendar_Returns, 
									printTable= NoPrint,
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

		%if %upcase(&method) = GEOMETRIC %then %do;

		cprod[i] = (1+cprod[i])*(1+ret[i])-1;
		%end;

		%if %upcase(&method) = ARITHMETIC %then %do;

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

proc transpose data=&year_month out=&outCalendarReturns;
by year;
var &ret;
id month;
run;

data &outCalendarReturns(drop=i);
format _name_ $32. YEAR 4. JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC TOTAL percent12.4;
set &outCalendarReturns;
array mths[12] JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC;
total = 0;
do i=1 to 12;
TOTAL = (1+TOTAL) * (1+ sum(0,mths[i])) - 1;
end;
run;

proc sort data=&outCalendarReturns;
by _NAME_ YEAR;
run;

data &outCalendarReturns;
set &outCalendarReturns;
if _name_ = 'Date' then delete;
run;

proc datasets lib= work nolist;
delete &year_month;
run;
quit;

%if %upcase(&printTable)= PRINT %then %do;
proc print data= &outCalendarReturns noobs;
		title 'Aggregated Monthly Returns';
 		where _name_= "&name";
run; 
%end;
%mend;