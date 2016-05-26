/*---------------------------------------------------------------
* NAME: table_HigherMoments.sas
*
* PURPOSE: Creates table containing coskewness, cokurtosis, beta covariance,
*          beta coskewness, and beta cokurtosis.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* dateColumn - Optional. Specifies the date column in the returns data set. [Default= Date]
* outData - Optional. Output table name. [Default= Higher_Moments]
* printTable - Optional. Option to print the data set. {PRINT, NOPRINT} [Default= NOPRINT]
* MODIFIED:
* 7/6/2015 – CJ - Initial Creation
* 10/1/2015 - CJ - Modified to accomodate edits from %CoMoments and replace temporary variable 
*				   names with random names.
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_HigherMoments(returns, 
								dateColumn= DATE,
								outData= Higher_Moments,
								printTable= NOPRINT);

%local BetaCoVar_Matrix BetaCoSkew_Matrix BetaCoKurt_Matrix Skew_Matrix Kurt_Matrix new_names Higher_Moments n_data n;
/*Name temporary data sets used to format table*/
%let BetaCoVar_Matrix= %ranname();
%let BetaCoSkew_Matrix= %ranname();
%let BetaCoKurt_Matrix= %ranname(); 
%let Skew_Matrix= %ranname();
%let Kurt_Matrix= %ranname();
%let new_names= %ranname();
%let Higher_Moments= %ranname();
%let n_data= %ranname();
/* Define n, a dummy variable which will keep the order of variables as they are read in the &returns data set*/
%let n= %ranname();
/*Call macros comoments and BetaCoMoments*/
%BetaCoMoments(&returns, outBetaCoVar= &BetaCoVar_Matrix, outBetaCoSkew= &BetaCoSkew_Matrix, outBetaCoKurt= &BetaCoKurt_Matrix);
%comoments(&returns, outCoSkew= &Skew_Matrix, outCoKurt= &Kurt_Matrix );

data &BetaCoVar_Matrix;
set &BetaCoVar_Matrix;
&n= _n_;
run;

data &Kurt_Matrix;
set &Kurt_Matrix;
&n= _n_;
run;

data &BetaCoSkew_Matrix;
set &BetaCoSkew_Matrix;
&n= _n_;
run;

data &BetaCoKurt_Matrix;
set &BetaCoKurt_Matrix;
&n= _n_;
run;

data &Skew_Matrix;
set &Skew_Matrix;
&n= _n_;
run;

/*Format table*/
data &outData;
set &Skew_Matrix &Kurt_Matrix &BetaCoVar_Matrix &BetaCoSkew_Matrix &BetaCoKurt_Matrix ;
run;

proc sort data= &outData;
by &n;
run;

data &n_data;
set &outData;
keep Names &n;
rename Names= &Higher_moments;
run;

data &outData;
set &outData;
drop &n;
run;

proc transpose data= &outData name= &Higher_moments out= &outData;
by Names notsorted;
run;

data &outData;
set &outData;
&new_names= catx('_', &Higher_moments,"to", Names );
run;

proc sort data= &n_data;
by &Higher_moments;
run;

proc sort data= &outData;
by &Higher_moments;
run;

data &outData;
merge &outData &n_data;
by &Higher_moments;
run;

proc sort data= &outData;
by &n;
run;

data &outData;
set &outData;
drop &n;
run;

proc transpose data= &outData name= names out= &outData;
id &new_names;
run;

data &outData(rename= var= _STAT_);
retain var;
set &outData;
&n= _n_;
if &n=1 then var= 'M3';
if &n=2 then var= 'M4';
if &n=3 then var= 'BetaM2';
if &n=4 then var= 'BetaM3';
if &n=5 then var= 'BetaM4';
drop &n;
drop names;
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outData noobs;
	run;
%end;

proc datasets lib= work nolist;
delete &BetaCoVar_Matrix &BetaCoSkew_Matrix &BetaCoKurt_Matrix &Skew_Matrix &Kurt_Matrix &n &n_data;
run;
quit;
%mend;
