%macro MSquared_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\MSquared_test1_submit.sas";
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
put "tM2 = function(Ra,Rb,Rf=0,scale=NA,geometric=TRUE){";
put "  SR = SharpeRatio.annualized(Ra,Rf=Rf,scale=scale,geometric=geometric)";
put "  sb = StdDev.annualized(Rb,scale=scale)";
put "  rm = Return.annualized(Rb,scale=scale,geometric=geometric)";
put "  if (geometric) {";
put "    # simple returns";
put "    Rf = (1+Rf)^scale - 1";
put "  } else {";
put "    # compound returns";
put "    Rf = Rf * scale";
put "  }";
put "  result = SR[1,]*sb[1,1] + Rf -rm[1,1]";
put "  return(result)";
put "}";
put "returns = data.frame(t(tM2(returns[, 1:4], returns[,5], Rf= 0.01/252, scale=252, geometric=TRUE)))";
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
%MSquared(prices, BM= SPY, Rf= 0.01/252, scale= 252, method = DISCRETE, NET=TRUE, outData= MSquared)


/*If tables have 0 records then delete them.*/
proc sql;
 %local nv;
 select count(*) into :nv TRIMMED from MSquared;
 %if ^&nv %then %do;
 	drop table MSquared;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(MSquared)) %then %do;
/*Error creating the data set, ensure compare fails*/
data MSquared;
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
			 compare=MSquared
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
	%put NOTE: NO ERROR IN TEST MSQUARED_TEST1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST MSQUARED_TEST1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices returns_from_r MSquared;
	quit;
%end;

%mend;
