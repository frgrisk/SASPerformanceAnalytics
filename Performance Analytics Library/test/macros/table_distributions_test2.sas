%macro table_distributions_test2(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\table_distributions_test2_submit.sas";
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
put "returns = Return.calculate(prices, method='log')";
put "returns = table.Distributions(returns,scale=252)";
put "names = c('_stat_',names(returns))";
put "stats = data.frame(rownames(returns),returns)";
put "names(stats) = names";
put "endsubmit;";
run;

proc iml;
%include x;

call importdatasetfromr("returns_from_R","stats");
quit;

data prices;
set input.prices;
run;

%return_calculate(prices,updateInPlace=TRUE,method=LOG)
%table_distributions(prices,scale=252)

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from distribution_table;
 %if ^&nv %then %do;
 	drop table distribution_table;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(distribution_table)) %then %do;
/*Error creating the data set, ensure compare fails*/
data distribution_table;
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

data returns_from_r;
	set returns_from_r;
	if _stat_ = "Monthly Std Dev" then
		_stat_ = "Scaled Std Dev";
run;

proc sort data=returns_from_r;
by _stat_;
run;

proc sort data=distribution_table;
by _stat_;
run;

proc compare base=returns_from_r 
			 compare= distribution_table 
			 out=diff(where=(_type_ = "DIF"
			            and (abs(IBM)> 5e-5 or abs(GE)> 5e-5 or abs(DOW)> 5e-5 or abs(GOOGL)> 5e-5 or abs(SPY)> 5e-5)
					))
			 noprint;
	by _stat_;
run;

data diff;
	set diff;
	if _stat_ = "Sample skewness" then do;
		/*SAS is using a different skewness method (Fisher) here*/
		if (abs(IBM) + abs(GE) + abs(DOW) + abs(GOOGL) + abs(SPY)) < 5*(5e-3) then 
			delete;
	end;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST table_distribution_TEST2;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST table_distribution_TEST2;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns_from_r distribution_table;
	quit;
%end;

filename x clear;

%mend;
