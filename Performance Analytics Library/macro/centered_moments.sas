/*---------------------------------------------------------------
* NAME: centered_moments.sas
*
* PURPOSE: calculate centered returns.
*
* NOTES: The n-th centered moment is calculated as moment^n(R)= E[(r-E(R))^n];
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns
* dateColumn - Date column in Data Set. Default=DATE
* outCenteredVar- output data set for centered variance. [Default= centered_Var]
* outCenteredSkew- output data set for centered skewness. [Default= centered_Skew]
* outCenteredKurt- output data set for centered kurtosis. [Default= centered_Kurt]
*
* MODIFIED:
* 7/8/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro centered_moments(returns,  
						dateColumn=Date,
						outCenteredVar=centered_Var,
						outCenteredSkew= centered_Skew,
						outCenteredKurt= centered_Kurt);

%local lib ds vars;

/***********************************
*Figure out 2 level ds name of PRICES
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;

proc sql noprint;
select name
	into :vars separated by ' '
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

%return_centered(&returns);

proc iml;
use centered_returns;
read all var {&vars} into cm[colname= names];
close &returns;

CVar= mean(cm#cm);
CSkew= mean(cm#cm#cm);
CKurt= mean(cm#cm#cm#cm);

CVar= CVar`;
names= names`;

create cent_var from CVar[rowname= names];
append from CVar[rowname= names];
close cent_var;

CSkew= CSkew`;
names= names`;

create cent_skew from CSkew[rowname= names];
append from CSkew[rowname= names];
close cent_skew;

CKurt= CKurt`;
names= names`;

create cent_kurt from CKurt[rowname= names];
append from CKurt[rowname= names];
close cent_kurt;
quit;

proc transpose data= cent_var out= cent_var;
id names;
run;

data &outCenteredVar;
set cent_var;
n= _n_;
if n= 1 then _name_= 'Var';
drop n;
run;

proc transpose data= cent_skew out= cent_skew;
id names;
run;

data &outCenteredSkew;
set cent_skew;
n= _n_;
if n= 1 then _name_= 'Skew';
drop n;
run;

proc transpose data= cent_kurt out= cent_kurt;
id names;
run;

data &outCenteredKurt;
set cent_kurt;
n= _n_;
if n= 1 then _name_= 'Kurt';
drop n;
run;

proc datasets lib= work nolist;
delete cent_var cent_skew cent_kurt centered_returns;
run;
%mend;