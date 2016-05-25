%macro return_centered_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\return_centered_test_submit.sas";
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
put "returns = Return.centered(returns)";
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
%return_centered(prices)

data centered_returns;
	set centered_returns(firstobs=2);
run;

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from centered_returns;
 %if ^&nv %then %do;
 	drop table centered_returns;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(centered_returns)) %then %do;
/*Error creating the data set, ensure compare fails*/
data centered_returns;
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

proc compare base=returns_from_r 
			 compare=centered_returns(drop=date) 
			 out=diff(where=(_type_ = "DIF"
			            and (fuzz(IBM) or fuzz(GE) or fuzz(DOW) 
			              or fuzz(GOOGL) or fuzz(SPY))
					))
			 noprint;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST RETURN_MEAN_TEST;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST RETURN_MEAN_TEST;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices centered_returns returns_from_r;
	quit;
%end;

%mend;
