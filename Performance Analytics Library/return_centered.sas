/*---------------------------------------------------------------
* NAME: return_centered.sas
*
* PURPOSE: calculate centered returns.
*
* NOTES: The n-th centered moment is calculated as moment^n(R)= E[(r-E(R))^n];
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns
* dateColumn - Date column in Data Set. Default=DATE
* outCentered - output Data Set with centered returns.  Only used if updateInPlace=FALSE 
*             Default="centered_returns"
*
* MODIFIED:
* 7/8/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_centered(returns, 
						dateColumn=DATE,
						outCentered=centered_returns);

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

proc iml;
use &returns;
read all var {&vars} into a[colname= names];
close &returns;

MeanA= mean(a);
Centered= a-MeanA;

Centered= Centered`;
names= names`;

create cent_ret from Centered[rowname= names];
append from Centered[rowname= names];
close cent_ret;
quit;

proc transpose data= cent_ret out= cent_ret;
id names;
run;

data DateColumn;
set &returns;
keep &dateColumn;
run;
data DateColumn;
set DateColumn;
n=_n_;
run;

data &outCentered;
set cent_ret;
n=_n_;
run;

data &outCentered;
retain &dateColumn;
merge &outCentered DateColumn;
by n;
drop _name_;
drop n;
run;

proc datasets lib= work nolist;
delete cent_ret DateColumn;
run;
%mend;
