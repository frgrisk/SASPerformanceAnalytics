%macro table_HigherMoments_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\table_HigherMoments_test_submit.sas";
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
put "returns = Return.calculate(prices, method='discrete')";
put "returns = table.HigherMoments(returns, returns, digits= 10)";
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
%table_HigherMoments(prices)

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from Higher_Moments;
 %if ^&nv %then %do;
 	drop table Higher_Moments;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(Higher_Moments)) %then %do;
/*Error creating the data set, ensure compare fails*/
data Higher_Moments;
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
	IBM = 999;
	GE = IBM;
	DOW = IBM;
	GOOGL = IBM;
	SPY = IBM;
run;
%end;

proc compare base=returns_from_r 
			 compare= Higher_Moments
			 method= absolute
			 criterion= 0.01
			 out=diff(where=(_type_ = "DIF"
			            and (abs(IBM_to_IBM)> 1e-7 or abs(IBM_to_GE)> 1e-3 or abs(IBM_to_DOW)> 1e-3 or abs(IBM_to_GOOGL)> 1e-3 or abs(IBM_to_SPY)> 1e-3 or
							 abs(GE_to_IBM)> 1e-1 or abs(GE_to_GE)> 1e-3 or abs(GE_to_DOW)> 1e-3 or abs(GE_to_GOOGL)> 1e-3 or abs(GE_to_SPY)> 1e1 or
							 abs(DOW_to_IBM)> 1e1 or abs(DOW_to_GE)> 1e-3 or abs(DOW_to_DOW)> 1e-3 or abs(DOW_to_GOOGL)> 1e-3 or abs(DOW_to_SPY)> 1e1 or
							 abs(GOOGL_to_IBM)> 1e1 or abs(GOOGL_to_GE)> 1e-3 or abs(GOOGL_to_DOW)> 1e-3 or abs(GOOGL_to_GOOGL)> 1e-3 or abs(GOOGL_to_SPY)> 1e-3 or
							 abs(SPY_to_IBM)> 1e1 or abs(SPY_to_GE)> 1e-3 or abs(SPY_to_DOW)> 1e-3 or abs(SPY_to_GOOGL)> 1e-3 or abs(SPY_to_SPY)> 1e-3)
					))
			 noprint;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST table_HigherMoments_TEST;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST table_HigherMoments_TEST;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete prices diff Higher_Moments returns_from_r;
	quit;
%end;

filename x clear;

%mend;
