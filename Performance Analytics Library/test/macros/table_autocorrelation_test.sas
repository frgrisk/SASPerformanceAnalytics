%macro table_autocorrelation_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\table_autocorrelation_test_submit.sas";
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
put "returns = t(table.Autocorrelation(returns, digits=6))";
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
%table_autocorrelation(prices, nlag= 6, digits= 6)

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from AutoCorrelations;
 %if ^&nv %then %do;
 	drop table AutoCorrelations;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(AutoCorrelations)) %then %do;
/*Error creating the data set, ensure compare fails*/
data AutoCorrelations;
	lag1 = -999;
	lag2 = lag1;
	lag3 = lag1;
	lag4 = lag1;
	lag5 = lag1;
	lag6 = lag1;
	p_value= lag1;
run;
%end;

%if ^%sysfunc(exist(returns_from_r)) %then %do;
/*Error creating the data set, ensure compare fails*/
data returns_from_r;
	rho1 = 999;
	rho2 = rho1;
	rho3 = rho1;
	rho4 = rho1;
	rho5 = rho1;
	rho6 = rho1;
	Q_6__p_value= rho1;
run;
%end; 

proc compare base= AutoCorrelations 
			 compare= returns_from_r
			 method= absolute
			 out=diff(where=(_type_ = "DIF"
			            and (abs(lag1)> 1e-4 or abs(lag2)> 1e-4 or abs(lag3)> 1e-4 or abs(lag4)> 1e-4 or abs(lag5)> 1e-4 or abs(lag6)> 1e-4 or abs(p_value)> 1e-4)
					))
			 noprint;
			 var lag1 lag2 lag3 lag4 lag5 lag6 P_Value;
			 with rho1 rho2 rho3 rho4 rho5 rho6 Q_6__p_value;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST table_autocorrelation_TEST;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST table_autocorrelation_TEST;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns_from_r AutoCorrelations;
	quit;
%end;

filename x clear;

%mend;
