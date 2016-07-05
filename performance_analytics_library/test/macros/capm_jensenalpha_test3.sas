%macro CAPM_JensenAlpha_test3(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\CAPM_JensenAlpha_test3_submit.sas";
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
put "returns = na.omit(Return.calculate(prices, method='discrete'))";
put "returns = apply.yearly(returns,FUN=Return.cumulative,geometric=TRUE)";
put "returns = CAPM.jensenAlpha(returns[, 1:4], returns[,5], Rf= 0.01)";
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
%return_accumulate(prices,method=DISCRETE,toFreq=YEAR,updateInPlace=TRUE)

%macro Edit_returns(returns, dateColumn=DATE);
%local ret i;
%let ret= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%let i= %ranname();

data prices(drop=&i);
	set prices;
	array vars[*] &ret;
	do &i=1 to dim(vars);
	if _n_=1 then
		vars[&i] = .;
	end;
run;
%mend;

%Edit_returns(prices)
%CAPM_JensenAlpha(prices, BM= SPY, Rf= 0.01, scale= 1, outData= Jensen_Alpha)


/*If tables have 0 records then delete them.*/
proc sql;
 %local nv;
 select count(*) into :nv TRIMMED from Jensen_Alpha;
 %if ^&nv %then %do;
 	drop table Jensen_Alpha;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(Jensen_Alpha)) %then %do;
/*Error creating the data set, ensure compare fails*/
data Jensen_Alpha;
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
			 compare=Jensen_Alpha
			 out=diff(where=(_type_ = "DIF"
			            and (fuzz(IBM) or fuzz(GE) or fuzz(DOW) 
			              or fuzz(GOOGL))
					))
			 noprint;
run;
 
data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST CAPM_JensenAlpha_test3;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST CAPM_JensenAlpha_test3;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns_from_r Jensen_Alpha;
	quit;
%end;

%mend;
