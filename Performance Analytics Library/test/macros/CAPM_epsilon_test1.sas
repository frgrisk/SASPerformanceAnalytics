%macro CAPM_epsilon_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\CAPM_epsilon_test1_submit.sas";
%end;

data _null_;
file x;
put "submit /r;";
put "require(PerformanceAnalytics)";
put "prices = as.xts(read.zoo('&dir\\prices.csv',";
put "                 sep=',',";
put "                 header=TRUE";
put "                 )";
put "		)";
put "returns = na.omit(Return.calculate(prices, method='discrete'))";
put "returns = CAPM.epsilon(returns[, 1:4, drop= FALSE], returns[, 5, drop= FALSE], Rf= 0.01/252)";
put "endsubmit;";
run;

proc iml;
%include x;

call importdatasetfromr("returns_from_R","returns");
quit;

data prices;
set input.prices;
run;

%return_calculate(prices,updateInPlace=TRUE,method=DISCRETE)
%CAPM_epsilon(prices, BM= SPY, Rf= 0.01/252, scale= 252)

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from epsilon;
 %if ^&nv %then %do;
 	drop table epsilon;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(epsilon)) %then %do;
/*Error creating the data set, ensure compare fails*/
data epsilon;
	date = -1;
	IBM = -999;
	GE = IBM;
	DOW = IBM;
	GOOGL = IBM;
	SPY = IBM;
run;
%end;

%if ^%sysfunc(exist(returns_from_r)) %then %do;
/*Error creating the data set, ensure compare fails*/
data returns_from_r;
	date = 1;
	IBM = 999;
	GE = IBM;
	DOW = IBM;
	GOOGL = IBM;
	SPY = IBM;
run;
%end;

data epsilon;
	set epsilon;
run;

proc compare base=returns_from_r 
			 compare= epsilon 
			 method= absolute
			 out=diff(where=(_type_ = "DIF"
			            and (abs(IBM)> 1e-4 or abs(GE)> 1e-4 or abs(DOW)> 1e-4 or abs(GOOGL)> 1e-4)
					))
			 noprint;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST CAPM_epsilon_TEST1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST CAPM_epsilon_TEST1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices epsilon returns_from_r;
	quit;
%end;

filename x clear;

%mend;
