%macro return_excess_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\return_excess_test_submit.sas";
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
put "returns= Return.excess(returns, .04/12)";
put "returns = data.frame(date=index(returns),returns)";
put "names(returns) = c('date','IBM','GE','DOW','GOOGL','SPY')";
put "endsubmit;";
run;

proc iml;
%include x;

call importDataSetFromR("returns_from_R","returns");
quit;

data prices;
set input.prices;
run;
%return_calculate(prices, updateInPlace=TRUE, method= DISCRETE)
%return_excess(prices, Rf= .04/12)

proc compare base=returns_from_r 
			 compare=risk_premium
			 method=absolute
			 criterion=1e-6 
			 outnoequal
			 out=diff(where=(_type_ = "DIF"
			            and (IBM or GE or DOW or GOOGL or SPY)
					))
			 noprint;
by date;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST RETURN_EXCESS_TEST;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST RETURN_EXCESS_TEST;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns returns_from_r risk_premium;
	quit;
%end;

filename x clear;

%mend;
