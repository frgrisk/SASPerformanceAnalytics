%macro table_correlation_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\table_correlation_test1_submit.sas";
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
put "returns = table.Correlation(returns[, 1:4, drop= FALSE], returns[, 5, drop= FALSE])";
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
%table_correlation(prices,returnsCompare= SPY)

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from Correlations;
 %if ^&nv %then %do;
 	drop table Correlations;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(Correlations)) %then %do;
/*Error creating the data set, ensure compare fails*/
data Correlations;
	Correlation = -999;
	pvalue = Correlation;
	Lower_CI = Correlation;
	Upper_CI = Correlation;
run;
%end;

%if ^%sysfunc(exist(returns_from_r)) %then %do;
/*Error creating the data set, ensure compare fails*/
data returns_from_r;
	Correlation = 999;
	p_value = Correlation;
	Lower_CI = Correlation;
	Upper_CI = Correlation;
run;
%end;

data Correlations;
	set Correlations;
run;

data Correlations;
set Correlations;
if Upper_CI= 1 then delete;
run; 

proc compare base=returns_from_r 
			 compare= Correlations 
			 method= absolute
			 out=diff(where=(_type_ = "DIF"
			            and (abs(Correlation)> 1e-4 or abs(p_value)> 1e-4 or abs(Lower_CI)> 1e-4 or abs(Upper_CI)> 1e-4)
					))
			 noprint;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST table_correlation_TEST1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST table_correlation_TEST1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns_from_r correlations;
	quit;
%end;

filename x clear;

%mend;