%macro Adjusted_SharpeRatio_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\Adjusted_SharpeRatio_test1_submit.sas";
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
put "returns = AdjustedSharpeRatio(returns, Rf= 0.01/252, scale= 252)";
put "returns = data.frame(date=index(returns),returns)";
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
%Adjusted_SharpeRatio(prices,Rf= 0.01/252, scale= 252)


/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from adjusted_SharpeRatio;
 %if ^&nv %then %do;
 	drop table adjusted_SharpeRatio;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(adjusted_SharpeRatio)) %then %do;
/*Error creating the data set, ensure compare fails*/
data adjusted_SharpeRatio;
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

data adjusted_SharpeRatio;
	set adjusted_SharpeRatio end=last;
	if last;
run;

proc compare base=returns_from_r 
			 compare=adjusted_SharpeRatio
			 method= absolute
			 criterion= 0.0001 
			 out=diff(where=(_type_ = "DIF"
			            and (abs(IBM)> 1e-4 or abs(GE)> 1e-4 or abs(DOW)> 1e-4 
			              or abs(GOOGL)> 1e-4 or abs(SPY)>1e-4)
					))
			 noprint;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST Adjusted_SharpeRatio_test1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST Adjusted_SharpeRatio_test1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns_from_r Adjusted_SharpeRatio;
	quit;
%end;

%mend;