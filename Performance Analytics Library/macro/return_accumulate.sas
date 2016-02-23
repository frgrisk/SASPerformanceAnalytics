/*---------------------------------------------------------------
* NAME: return_accumulate.sas
*
* PURPOSE: aggregates returns from a low to higher level
*
* NOTES: Accepts periodic returns.  Will calculate daily/monthly/quarterly/yearly
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns
* method - {LOG, DISCRETE} -- compound or simple returns.  
           Default=DISCRETE
* toFreq - {DAY|DAILY, MONTH|MTH|MONTHLY, QUARTER|QTR|QUARTERLY, YEAR|YR|YEARLY}
*		   Default = MONTH
* dateColumn - Date column in Data Set. Default=DATE
* updateInPlace - {TRUE, FALSE} -- update the &returns Data Set in place.
*                 Default=TRUE
* outReturn - output Data Set with returns.  Only used if updateInPlace=FALSE 
*             Default="agg_returns"
*
* MODIFIED:
* 2/23/2016 – DP - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_accumulate(returns,
						method=DISCRETE,
						toFreq=MONTH,
						dateColumn=DATE,
						updateInPlace=TRUE,
						outReturn=agg_returns);

%local vars nv i YR QTR MTH DAY outData byVar;
/*Find all variable names excluding the date column*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN return_calculate: (&vars);
/*Find number of columns in the data set*/
%let nv= %sysfunc(countw(&vars));
/*Define counters for array operations*/
%let i= %ranname();

/*variable names for different frequencies*/
%let YR=%ranname();
%let QTR=%ranname();
%let MTH=%ranname();
%let DAY=%ranname();

%if %upcase(&updateInPlace) = TRUE %then %do;
	%let outData = &returns;
%end;
%else %do;
	%let outData = &outReturn;
%end;

/*Add columns to track frequencies*/
data &outData;
	set &returns;
	&yr = year(&dateColumn);
	&qtr = qtr(&dateColumn);
	&mth = month(&dateColumn);
	&day = day(&dateColumn);
run;

/*Ensure things are sorted properly*/
proc sort data=&outData;
	by &yr &qtr &mth &day;
run;

/*Aggregate returns*/
options minoperator;
data &outData(drop=&yr &qtr &mth &day &i);
	set &outData;

	/*setup arrays*/
	array cvars[&nv] _temporary_;
	array vars[&nv] &vars;


	/*Choose appropriate frequency*/
	%if %upcase(&toFreq) in  YEAR YR YEARLY %then %do;
		by &yr;
		%let byVar = &yr;
	%end;
	%else %if %upcase(&toFreq) in  QUARTER QTR QUARTERLY %then %do;
		by &yr &qtr;
		%let byVar = &qtr;
	%end;
	%else %if %upcase(&toFreq) in  MONTH MTH MONTHLY %then %do;
		by &yr &qtr &mth;
		%let byVar = &mth;
	%end; 
	%else %if %upcase(&toFreq) in  DAY DAILY %then %do;
		by &yr &qtr &mth &day;
		%let byVar = &day;
	%end; 
	%else %do;
		%put ERROR: FREQUENCY toFREQ=&toFreq not understood.;
		%put ERROR: Please use {DAY|DAILY, MONTH|MTH|MONTHLY, QUARTER|QTR|QUARTERLY, YEAR|YR|YEARLY};
		stop;
		run;
		%return;
	%end;

	/*Reset cumulative variables on first byVar*/
	if first.&byVar then do;
		do &i=1 to &nv;
			cvars[&i] = 0;
		end;
	end;

	/*Accumulate returns*/
	do &i=1 to &nv;
		%if %upcase(&method) = DISCRETE %then %do;
			cvars[&i] = sum(cvars[&i],vars[&i],cvars[&i]*vars[&i]);
		%end;
		%else %if %upcase(&method) = LOG %then %do;
			cvars[&i] = sum(cvars[&i],vars[&i]) ;
		%end;
		%else %do;
			%put ERROR: Invalid value in METHOD=&method.  Please use LOG, or DISCRETE;
		%end;
	end;

	/*If on the last byVar Save the accumulated values into the variable and output*/
	if last.&byVar then do;
		do &i=1 to &nv;
			vars[&i] = cvars[&i];
		end;
		output;
	end;
run;

%mend return_accumulate;