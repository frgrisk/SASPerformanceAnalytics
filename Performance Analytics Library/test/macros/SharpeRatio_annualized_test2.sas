%macro SharpeRatio_annualized_test2(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
filename x "&dir\sharpe_ratio_annualized_test2_submit.sas";
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
put "returns= SharpeRatio.annualized(returns, Rf = .01/4, scale = 4, geometric = FALSE)";
put "returns = data.frame(date=index(returns),returns)";
put "names(returns) = c('date','IBM','GE','DOW','GOOGL','SPY')";
put "endsubmit;";
run;

proc iml;
%include x;

call importDataSetFromR("Sharpe_from_R","returns");
quit;

data prices;
set input.prices;
run;

%return_calculate(prices,updateInPlace=TRUE,method=LOG)
%SharpeRatio_annualized(prices, Rf= 0.01/4, scale= 4, method= LOG, outData= Sharpe_Ratio)

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from Sharpe_Ratio;
 %if ^&nv %then %do;
 	drop table Sharpe_Ratio;
 %end;
 
 select count(*) into :nv TRIMMED from Sharpe_from_r;
 %if ^&nv %then %do;
 	drop table Sharpe_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(Sharpe_ratio)) %then %do;

/*Error creating the data set, ensure compare fails*/
data Sharpe_Ratio;
	date = -1;
	IBM = -999;
	GE = IBM;
	DOW = IBM;
	GOOGL = IBM;
	SPY = IBM;
run;
%end;

%if ^%sysfunc(exist(Sharpe_from_r)) %then %do;
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

data Sharpe_Ratio;
	set Sharpe_Ratio end=last;
	if last;
run;

proc compare base=Sharpe_from_r 
			 compare=Sharpe_Ratio 
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
	%put NOTE: NO ERROR IN TEST SharpeRatio_annualized_test2;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST SharpeRatio_annualized_test2;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices _meanRet _tempRP _tempStd Sharpe_from_R Sharpe_Ratio;
	quit;
%end;

%mend;
