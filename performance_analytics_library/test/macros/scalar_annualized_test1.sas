%macro scalar_annualized_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\scalar_annualized_test1_submit.sas";
%end;

data _null_;
file x;
put "submit /r;";
put "require(PerformanceAnalytics)";
put "prices = as.xts(read.zoo('&dir\\prices.csv',";
put "                         sep=',',";
put "                         header=TRUE";
put "                 )";
put "		)";
put "results = na.omit(Return.calculate(prices[1:101,1], method='discrete'))";
put "scale_4 = apply.daily(results/4,FUN=Return.annualized,geometric=TRUE,scale=4)";
put "scale_12 = apply.daily(results/12,FUN=Return.annualized,geometric=TRUE,scale=12)";
put "scale_52 = apply.daily(results/52,FUN=Return.annualized,geometric=TRUE,scale=52)";
put "scale_252 = apply.daily(results/252,FUN=Return.annualized,geometric=TRUE,scale=252)";
put "results = data.frame(results,scale_4,scale_12,scale_52,scale_252)";
put "colnames(results)<-c('ibm', 'scale_4', 'scale_12', 'scale_52', 'scale_252')";
put "endsubmit;";
run;

proc iml;
%include x;

call importdatasetfromr("results_from_R","results");
quit;

data prices;
set input.prices;
keep ibm;
run;

%return_calculate(prices,updateInPlace=TRUE,method=DISCRETE)

data prices;
	set prices(firstobs=2 obs=101);
run;

data _null_;
	set prices(keep=ibm);
	call symput(('obs'||left(_n_)),trim(put(ibm,12.10)));
run;

%macro scalar_annualized_value(method=DISCRETE, type=VALUE);
%local i;
data annualized_scalar;
	set prices;
	%do i = 1 %to 100;
		if _n_ = &i then do;
		scale_4 = %scalar_annualized(%sysevalf(&&obs&i/4),scale=4,method=&method,type=&type);
		scale_12 = %scalar_annualized(%sysevalf(&&obs&i/12),scale=12,method=&method,type=&type);
		scale_52 = %scalar_annualized(%sysevalf(&&obs&i/52),scale=52,method=&method,type=&type);
		scale_252 = %scalar_annualized(%sysevalf(&&obs&i/252),scale=252,method=&method,type=&type);
		end;
	%end;
run;
%mend;

%scalar_annualized_value(method=DISCRETE,type=VALUE);


/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from annualized_scalar;
 %if ^&nv %then %do;
 	drop table annualized_scalar;
 %end;
 
 select count(*) into :nv TRIMMED from results_from_R;
 %if ^&nv %then %do;
 	drop table results_from_R;
 %end;
quit ;

%if ^%sysfunc(exist(annualized_scalar)) %then %do;
/*Error creating the data set, ensure compare fails*/
data annualized_scalar;
	date = -1;
	randnum = -999;
	scale_4 = randnum;
	scale_12 = randnum;
	scale_52 = randnum;
	scale_252 = randnum;
run;
%end;

%if ^%sysfunc(exist(results_from_R)) %then %do;
/*Error creating the data set, ensure compare fails*/
data results_from_R;
	date = 1;
	randnum = 999;
	scale_4 = randnum;
	scale_12 = randnum;
	scale_52 = randnum;
	scale_252 = randnum;
run;
%end;

proc compare base=results_from_r 
			 compare=annualized_scalar
			 out=diff(where=(_type_ = "DIF"
			            and ibm> 1e-7 or scale_4> 1e-7 or scale_12> 1e-7
			              or scale_52> 1e-7 or scale_252>1e-7))
			 noprint;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST SCALAR_ANNUALIZED_TEST1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST SCALAR_ANNUALIZED_TEST1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete prices diff scalars annualized_scalar results_from_R;
	quit;
%end;

%mend;
