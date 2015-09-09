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
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_HigherMoments(returns, 
								dateColumn= Date,
								outHigherMoments= Higher_Moments,
								printTable= NOPRINT);

/*Call macros comoments and BetaCoMoments*/
%BetaCoMoments(&returns);
%comoments(&returns);

data M3;
set M3;
n= _n_;
run;

data M4;
set M4;
n= _n_;
run;

data betaM2;
set betaM2;
n= _n_;
run;

data betaM3;
set betaM3;
n= _n_;
run;

data betaM4;
set betaM4;
n= _n_;
run;



/*Format table*/
data &outHigherMoments;
set M3 M4 betaM2 betaM3 betaM4;
run;

proc sort data= &outHigherMoments;
by n;
run;

data n;
set &outHigherMoments;
keep name n;
rename name= Higher_moments;
run;

data &outHigherMoments;
set &outHigherMoments;
drop n;
run;

proc transpose data= &outHigherMoments name= Higher_moments out= &outHigherMoments;
by name notsorted;
run;

data &outHigherMoments;
set &outHigherMoments;
new_names= catx('_', Higher_moments,"to", name );
run;

proc sort data= n;
by Higher_moments;
run;

proc sort data= &outHigherMoments;
by Higher_moments;
run;

data &outHigherMoments;
merge &outHigherMoments n;
by Higher_moments;
run;

proc sort data= &outHigherMoments;
by n;
run;

data &outHigherMoments;
set &outHigherMoments;
drop n;
run;

proc transpose data= &outHigherMoments name= names out= &outHigherMoments;
id new_names;
run;

data &outHigherMoments;
retain var;
set &outHigherMoments;
n= _n_;
if n=5 then var= 'BetaM4';
if n=1 then var= 'M3';
if n=2 then var= 'M4';
if n=3 then var= 'BetaM2';
if n=4 then var= 'BetaM3';
drop n;
drop names;
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outHigherMoments noobs;
	run;
%end;

proc datasets lib= work nolist;
delete M3 M4 betaM2 betaM3 betaM4 n;
run;
%mend;