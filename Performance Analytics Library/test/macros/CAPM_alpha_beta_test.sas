%macro CAPM_alpha_beta_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\CAPM_alpha_beta_test_submit.sas";
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
put "alpha = CAPM.alpha(returns[, 1:4, drop= FALSE], returns [,5, drop= FALSE], Rf= 0.01/252)";
put "beta = CAPM.beta(returns[, 1:4, drop= FALSE], returns [,5, drop= FALSE], Rf= 0.01/252)";
put "df <-rbind(alpha, beta)";
put "names(df)= c('IBM','GE','DOW','GOOGL')";
put "endsubmit;";
run;

proc iml;
%include x;

call importdatasetfromr("returns_from_R","df");
quit;

data prices;
set input.prices;
run;

%return_calculate(prices,updateInPlace=TRUE,method=DISCRETE)
%CAPM_alpha_beta(prices, Rf= 0.01/252, BM= SPY)


/*If tables have 0 records then delete them.*/
proc sql;
 %local nv;
 select count(*) into :nv TRIMMED from alphas_and_betas;
 %if ^&nv %then %do;
 	drop table alphas_and_betas;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(alphas_and_betas)) %then %do;
/*Error creating the data set, ensure compare fails*/
data alphas_and_betas;
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
			 compare=alphas_and_betas 
			 method=absolute
			 out=diff(where=(_type_ = "DIF"
			            and (abs(IBM) > 1e-5 or abs(GE) > 1e-5
			              or abs(DOW) > 1e-5 or abs(GOOGL) > 1e-5)
			 		))
			noprint
			 ;
run;


proc print data= diff;
run; 
data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST CAPM_alpha_beta_test;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST CAPM_alpha_beta_test;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns_from_r alphas_and_betas;
	quit;
%end;

%mend;
