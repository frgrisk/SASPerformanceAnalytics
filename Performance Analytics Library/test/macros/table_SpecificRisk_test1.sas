%macro table_SpecificRisk_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\table_SpecificRisk_test1_submit.sas";
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
put "returns = na.omit(Return.calculate(prices))";
put "returns = table.SpecificRisk(returns[, 1:4], returns[, 5], Rf= 0.01/252, digits= 8)";
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
%table_SpecificRisk(prices, BM= SPY, Rf= 0.01/252, scale= 252, digits=8)

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from table_SpecificRisk;
 %if ^&nv %then %do;
 	drop table table_SpecificRisk;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(table_SpecificRisk)) %then %do;
/*Error creating the data set, ensure compare fails*/
data table_SpecificRisk;
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
			 compare= table_SpecificRisk 
			 method= absolute
			 criterion= 0.0001
			 outnoequal
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
	%put NOTE: NO ERROR IN TEST table_SpecificRisk_TEST1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST table_SpecificRisk_TEST1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete prices diff returns_from_r table_SpecificRisk;
	quit;
%end;

filename x clear;

%mend;
