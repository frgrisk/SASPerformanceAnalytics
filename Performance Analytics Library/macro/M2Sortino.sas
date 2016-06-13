/*---------------------------------------------------------------
* NAME: M2Sortino.sas
*
* PURPOSE: Calculate the M squared for Sortino. The downside risk is used rather than total risk.
*
* NOTES: In the formula of calculating M2Sortino, the downside risk needs to be annualized based on
*		 the scaler provided by user.
*		 It is optional to choose whether to compound returns with discrete or log method, which is 
*		 not an option in the corresponding R function. In R function, discrete compounding is used.
*		 In addition, the R function defaulted group=FULL and it's not for change.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns and benchmark.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* MAR - Optional. Minimum Acceptable Return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
		  Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* group - Optional. Specifies to choose full observations or subset observations as 'n' in the divisor. {FULL, SUBSET}
*		  Default=FULL
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. output Data Set with Sortino M squared.  Default="M2Sortino"
*
* MODIFIED:
* 6/09/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro M2Sortino(returns,
							BM=, 
							MAR=0,
							scale=1,
							method=DISCRETE,
							group=FULL,
							dateColumn= DATE,
							outData= M2Sortino);

%local vars nvars drisk sratio areturn all i j;

%let vars=%get_number_column_names(_table=&returns,_exclude=&dateColumn);
%put VARS IN M2Sortino: (&vars);

%let nvars = %sysfunc(countw(&vars));
%let drisk = %ranname();
%let sratio = %ranname();
%let areturn = %ranname();
%let all = %ranname();
%let i = %ranname();

%return_annualized(&returns, scale=&scale, method=&method, dateColumn=&dateColumn, outData=&areturn);
%SortinoRatio(&returns, MAR=&MAR, group=&group, dateColumn=&dateColumn, outData=&sratio);
%downside_risk(&returns, MAR=&MAR, option=RISK, group=&group, dateColumn=&dateColumn, outData=&drisk);

data &drisk;
	set &drisk;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i] = vars[&i]*sqrt(&scale);
	end;
run;

data &all;
	set &areturn &sratio &drisk;
	array vars[*] &vars;
	array Mtwo[&nvars] (&nvars*0);

	do &i=1 to &nvars;
		Mtwo[&i] = LAG2(vars[&i])+LAG(vars[&i])*(&BM-vars[&i]);
	end;
	drop &i;
run;

data &outData;
	format _stat_ $32.;
	set &all(keep=Mtwo1-Mtwo&nvars) end=eof;
	rename 
		%do j=1 %to &nvars;
			Mtwo&j = %sysfunc(scan(&vars, &j))
		%end;
		;
	_stat_ = 'M2Sortino';
	if eof;
run;

proc datasets lib= work nolist;
delete &drisk &sratio &areturn &all;
run;
quit;	

%mend;
