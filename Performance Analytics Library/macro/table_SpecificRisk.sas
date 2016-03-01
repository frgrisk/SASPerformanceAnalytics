/*---------------------------------------------------------------
* NAME: table_SpecificRisk.sas
*
* PURPOSE: Table of specific risk, systematic risk, and total risk.
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return. 
* dateColumn - Date column in Data Set. Default=DATE
* outTable - output Data Set of systematic risk.  Default="table_SpecificRisk".
* printTable- option to print output data set.  {PRINT, NOPRINT} [Default= NOPRINT]

* MODIFIED:
* 7/14/2015 – CJ - Initial Creation
* 03/1/2016 - DP - Updated to do calculations here.  specific_risk and systematic_risk now call
*                  this macro. 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_SpecificRisk(returns, 
							BM=, 
							Rf=0,
							scale= 1,
							dateColumn= DATE,
							outTable= table_SpecificRisk,
							printTable= NOPRINT);

%local vars var n i out_reg out_excess;

/***********************************
*Get Variables in the RETURNS data set
************************************/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM);
%put VARS IN Specific_Risk: (&vars);
%let n=%sysfunc(countw(&vars));

/*Calculate excess from benchmark*/
%let out_excess = %ranname();
%return_excess(&returns, 
			 	Rf= &rf, 
			 	dateColumn=&dateColumn,
				outReturn= &out_excess);


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
output out=&out_reg(drop=&dateColumn) 
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
					outStdDev= &outTable);

/*Transpose the Vol values and create the _STAT_ column*/
data &outTable(keep=_stat_ &vars);
	format _STAT_ $32.;
set &outTable;

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
do &i=1 to 4;
	tRisk[&i] = spRisk[&i];
end;
output;
_stat_ = "Systematic Risk";
do &i=1 to 4;
	tRisk[&i] = sysRisk[&i];
end;
output;
run;

proc sort data=&outTable;
by _stat_;
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outTable noobs;
	run;
%end;

proc datasets lib= work nolist;
delete &out_excess &out_reg;
run;
quit;

%mend;

