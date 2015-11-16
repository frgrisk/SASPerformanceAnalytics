/*---------------------------------------------------------------
* NAME: table_HigherMoments.sas
*
* PURPOSE: Creates table containing coskewness, cokurtosis, beta covariance,
*          beta coskewness, and beta cokurtosis.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* dateColumn- specifies the format of the date column in the returns data set. [Default= Date]
* outHigherMoments- Output table [Default= Higher_Moments]
* printTable- option to print the data set. {PRINT, NOPRINT} [Default= PRINT]
* MODIFIED:
* 7/6/2015 – CJ - Initial Creation
* 10/1/2015 - CJ - Modified to accomodate edits from %CoMoments and replace temporary variable 
*				   names with random names.
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_HigherMoments(returns, 
								dateColumn= Date,
								outHigherMoments= Higher_Moments,
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
data &outHigherMoments;
set &Skew_Matrix &Kurt_Matrix &BetaCoVar_Matrix &BetaCoSkew_Matrix &BetaCoKurt_Matrix ;
run;

proc sort data= &outHigherMoments;
by &n;
run;

data &n_data;
set &outHigherMoments;
keep Names &n;
rename Names= &Higher_moments;
run;

data &outHigherMoments;
set &outHigherMoments;
drop &n;
run;

proc transpose data= &outHigherMoments name= &Higher_moments out= &outHigherMoments;
by Names notsorted;
run;

data &outHigherMoments;
set &outHigherMoments;
&new_names= catx('_', &Higher_moments,"to", Names );
run;

proc sort data= &n_data;
by &Higher_moments;
run;

proc sort data= &outHigherMoments;
by &Higher_moments;
run;

data &outHigherMoments;
merge &outHigherMoments &n_data;
by &Higher_moments;
run;

proc sort data= &outHigherMoments;
by &n;
run;

data &outHigherMoments;
set &outHigherMoments;
drop &n;
run;

proc transpose data= &outHigherMoments name= names out= &outHigherMoments;
id &new_names;
run;

data &outHigherMoments(rename= var= _STAT_);
retain var;
set &outHigherMoments;
&n= _n_;
if &n=5 then var= 'BetaM4';
if &n=1 then var= 'M3';
if &n=2 then var= 'M4';
if &n=3 then var= 'BetaM2';
if &n=4 then var= 'BetaM3';
drop &n;
drop names;
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outHigherMoments noobs;
	run;
%end;

proc datasets lib= work nolist;
delete &BetaCoVar_Matrix &BetaCoSkew_Matrix &BetaCoKurt_Matrix &Skew_Matrix &Kurt_Matrix &n &n_data;
run;
quit;
%mend;