%macro table_stats_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\table_stats_test_submit.sas";
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
put "returns = (Return.calculate(prices, method='discrete'))";
put "returns = table.Stats(returns,digits=8)";
put "names = c('_stat_',names(returns))";
put "stats = data.frame(rownames(returns),returns)";
put "names(stats) = names";
put "endsubmit;";
run;

proc iml;
%include x;

call importdatasetfromr("stats_from_R","stats");
quit;

data prices;
set input.prices;
run;
%return_calculate(prices);
%table_stats(prices,digits=8);

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from Stats;
 %if ^&nv %then %do;
 	drop table AutoCorrelations;
 %end;
 
 select count(*) into :nv TRIMMED from stats_from_R;
 %if ^&nv %then %do;
 	drop table stats_from_R;
 %end;
quit ;

%if ^%sysfunc(exist(Stats)) %then %do;
/*Error creating the data set, ensure compare fails*/
data Stats;
	_nobs_ = -999;
	_nmiss_ = _nobs_;
	 _min_= _nobs_;
	_q1_ = _nobs_;
	_median_ = _nobs_;
	geoMean = _nobs_;
	_q3_= _nobs_
	_max_ = _nobs_
	Std_Err = _nobs_
	LCLM = _nobs_
	UCLM = _nobs_
	_vari_ = _nobs_
	_std_ = _nobs_
	_skew_ = _nobs_
	_kurt_ = _nobs_;
run;
%end;

%if ^%sysfunc(exist(stats_from_R)) %then %do;
/*Error creating the data set, ensure compare fails*/
data stats_from_R;
	Observations = 999;
	NAs = Observations;
	Minimum = Observations;
	Quartile_1 = Observations;
	Median = Observations;
	Arithmetic_Mean = Observations;
	Geometric_Mean = Observations;
	Quartile_3 = Observations;
	Maximum = Observations;
	SE_Mean = Observations;
	LCL_Mean__0_95_ = Observations;
	UCL_Mean__0_95_ = Observations;
	Variance = Observations;
	Stdev= Observations;
	Skewness = Observations;
	Kurtosis = Observations;
run;
%end; 

proc sort data=stats;
by _stat_;
run;

proc sort data=stats_from_r;
by _stat_;
run;

proc compare base=stats compare=stats_from_r out=diff noprint;
var _numeric_;
by _stat_;
run;

data diff;
set diff;
format _numeric_ e8.;
/*R uses a different method for Skew and Kurtosis*/
if _STAT_ in ("Skewness", "Kurtosis") then do;
	if (abs(IBM) + abs(GE) + abs(DOW) + abs(GOOGL) + abs(SPY)) < 5*(5e-2) then 
		delete;
end;
else if (abs(IBM)<5e-9 
	and abs(GE) <5e-9 
	and abs(DOW)<5e-9 
	and abs(GOOGL) <5e-9 
	and abs(SPY)<5e-9   ) then 
		delete;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST table_stats_TEST;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST table_stats_TEST;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices stats stats_from_r;
/*	returns_from_r Stats;*/
	quit;
%end;

filename x clear;

%mend;
