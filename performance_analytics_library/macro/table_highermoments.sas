/*---------------------------------------------------------------
* NAME: table_HigherMoments.sas
*
* PURPOSE: Create table containing coskewness, cokurtosis, beta covariance,
*          beta coskewness, and beta cokurtosis.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* dateColumn - Optional. Specifies the date column in the returns data set. [Default= Date]
* outData - Optional. Output table name. [Default= Higher_Moments]
* printTable - Optional. Option to print the data set. {PRINT, NOPRINT} [Default= NOPRINT]
*
* MODIFIED:
* 7/6/2015 – CJ - Initial Creation
* 10/1/2015 - CJ - Modified to accomodate edits from %CoMoments and replace temporary variable 
*				   names with random names.
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - Parameter consistency
* 7/14/2016 - QY - Edited output format
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_HigherMoments(returns, 
								dateColumn= DATE,
								outData= Higher_Moments,
								printTable= NOPRINT);

%local BetaCoVar_Matrix BetaCoSkew_Matrix BetaCoKurt_Matrix Skew_Matrix Kurt_Matrix tempsets nvars vars;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN table_HigherMoments: (&vars);

%let nvars = %sysfunc(countw(&vars));

/*Name temporary data sets used to format table*/
%let BetaCoVar_Matrix= %ranname();
%let BetaCoSkew_Matrix= %ranname();
%let BetaCoKurt_Matrix= %ranname(); 
%let Skew_Matrix= %ranname();
%let Kurt_Matrix= %ranname();
%let tempsets= %ranname();
/*Call macros comoments and BetaCoMoments*/
%BetaCoMoments(&returns, outBetaCoVar= &BetaCoVar_Matrix, outBetaCoSkew= &BetaCoSkew_Matrix, outBetaCoKurt= &BetaCoKurt_Matrix);
%comoments(&returns, outCoSkew= &Skew_Matrix, outCoKurt= &Kurt_Matrix );

%macro rearrange(input);
%local j k;

proc transpose data=&input out=&input;
	id names;
run;

%do j=1 %to &nvars;
	data &tempsets&j;
		set &input;
		where _name_="%sysfunc(scan(&vars, &j))";
		%do k=1 %to &nvars;
		rename 
			%sysfunc(scan(&vars, &k))=%sysfunc(scan(&vars, &j))_to_%sysfunc(scan(&vars, &k));
		%end;
		drop _name_;
	run;
%end;

data &input;
%do j=1 %to &nvars;
	set &tempsets&j;
%end;
run;

proc datasets lib= work nolist;
%do j=1 %to &nvars;
	delete &tempsets&j;
%end;
run;
quit;

%mend;

%rearrange(&Skew_Matrix);
%rearrange(&Kurt_Matrix);
%rearrange(&BetaCoVar_Matrix);
%rearrange(&BetaCoSkew_Matrix);
%rearrange(&BetaCoKurt_Matrix);


data &outData;
format _STAT_ $32.; 
	set &Skew_Matrix &Kurt_Matrix &BetaCoVar_Matrix &BetaCoSkew_Matrix &BetaCoKurt_Matrix;
	if _n_=1 then _stat_= 'M3';
	if _n_=2 then _stat_= 'M4';
	if _n_=3 then _stat_= 'BetaM2';
	if _n_=4 then _stat_= 'BetaM3';
	if _n_=5 then _stat_= 'BetaM4';
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outData noobs;
	run;
%end;

proc datasets lib= work nolist;
delete &BetaCoVar_Matrix &BetaCoSkew_Matrix &BetaCoKurt_Matrix &Skew_Matrix &Kurt_Matrix;
run;
quit;
%mend;
