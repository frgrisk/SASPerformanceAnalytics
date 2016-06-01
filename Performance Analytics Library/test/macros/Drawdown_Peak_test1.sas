%macro Drawdown_Peak_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\Drawdown_Peak_test1_submit.sas";
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
put "returns = DrawdownPeak(returns[,1]*100)/100";
put "returns = data.frame(returns)";
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
%Drawdown_Peak(prices)

data drawdownPeak;
	set drawdownPeak(keep=ibm firstobs=2);
run;

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from drawdownPeak;
 %if ^&nv %then %do;
 	drop table TreynorRatio;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(drawdownPeak)) %then %do;
/*Error creating the data set, ensure compare fails*/
data drawdownPeak;
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
			 compare=drawdownPeak 
			 out=diff(where=(_type_ = "DIF"
			            and (fuzz(IBM) or fuzz(GE) or fuzz(DOW) 
			              or fuzz(GOOGL) or fuzz(SPY)
					)))
			 noprint;
run;


data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST DRAWDOWN_PEAK_TEST1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST DRAWDOWN_PEAK_TEST1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

/*%if &keep=FALSE %then %do;*/
/*	proc datasets lib=work nolist;*/
/*	delete diff prices drawdownPeak returns_from_r;*/
/*	quit;*/
/*%end;*/

%mend;
