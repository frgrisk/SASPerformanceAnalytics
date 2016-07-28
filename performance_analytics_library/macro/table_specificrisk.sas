/*---------------------------------------------------------------
* NAME: table_SpecificRisk.sas
*
* PURPOSE: Table of specific risk, systematic risk, and total risk.
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. [Default=0]
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          [Default=1]
* digits - Optional. Specifies the amount of digits to display in output. Default= 4
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set of specific risk.  Default="table_SpecificRisk".
* printTable - Optional. Option to print output data set.  {PRINT, NOPRINT} [Default= NOPRINT]

* MODIFIED:
* 7/14/2015 – CJ - Initial Creation
* 03/1/2016 - DP - Updated to do calculations here.  specific_risk and systematic_risk now call
*                  this macro. 
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
* 5/26/2016 - QY - Add parameter digits
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_SpecificRisk(returns, 
							BM=, 
							Rf= 0,
							scale= 1,
							digits= 4,
							VARDEF = DF,
							dateColumn= DATE,
							outData= table_SpecificRisk,
							printTable= NOPRINT);

%local vars var n i out_reg out_excess;

/*Add new comment*/

/***********************************
*Get Variables in the RETURNS data set
************************************/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM);
%put VARS IN table_SpecificRisk: (&vars);
%let n=%sysfunc(countw(&vars));

/*data &returns;*/
/*	set &returns(firstobs=2);*/
/*run;*/

/*Calculate excess from benchmark*/
%let out_excess = %ranname();
%return_excess(&returns, 
			 	Rf= &rf, 
			 	dateColumn=&dateColumn,
				outData= &out_excess);


/*Local variables to hold time series of predicted and residual values*/
%do i=1 %to &n;
	%let var=%scan(&vars,&i);
	%local p&var r&var;
	%let p&var=%ranname();
	%let r&var=%ranname();
%end;

/*Regress values on benchmark*/
%let out_reg=%ranname();
proc reg data=&out_excess noprint ;
model &vars  = &bm;
output out=&out_reg 
	pred=
	%do i=1 %to &n;
		%let var=%scan(&vars,&i);
		&&&p&var
	%end;

	RESIDUAL=
	%do i=1 %to &n;
		%let var=%scan(&vars,&i);
		&&&r&var
	%end;
	;
run;
quit;

/*Get the Annualized Vol*/
%Standard_Deviation(&out_reg, 
					scale=&scale, 
					annualized= TRUE, 
					VARDEF= &VARDEF,
					outData= &outData);

/*Transpose the Vol values and create the _STAT_ column*/
data &outData(keep=_stat_ &vars);
	format _STAT_ $32. &vars %eval(&digits + 4).&digits;
	set &outData;

	array tRisk[&n] &vars;
	array sysRisk[&n] 
		%do i=1 %to &n;
			%let var=%scan(&vars,&i);
			&&&p&var
		%end;
	;
	array spRisk[&n] 
		%do i=1 %to &n;
			%let var=%scan(&vars,&i);
			&&&r&var
		%end;
	;

	%let i=%ranname();

	_stat_ = "Total Risk";
	output;
	_stat_ = "Specific Risk";
	do &i=1 to &n;
		tRisk[&i] = spRisk[&i];
	end;
	output;
	_stat_ = "Systematic Risk";
	do &i=1 to &n;
		tRisk[&i] = sysRisk[&i];
	end;
	output;
run;

proc sort data=&outData;
by _stat_;
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outData noobs;
	run;
%end;

proc datasets lib= work nolist;
delete &out_excess &out_reg;
run;
quit;

%mend;

