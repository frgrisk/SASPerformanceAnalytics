%macro table_CalendarReturns_test1(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\table_CalendarReturns_test1_submit.sas";
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
put "returns = na.omit(Return.calculate(prices))";
put "m = apply.monthly(returns,FUN=function(x) {";
put " y = exp(colSums(log(x + 1)))-1";
put "} )";
put "m= table.CalendarReturns(m[,'SPY'],digits=4, geometric=TRUE)";
put "m= m/100";
put "endsubmit;";
run;

proc iml;
%include x;

call importdatasetfromr("returns_from_R","m");
quit;

data prices;
set input.prices;
run;

%return_calculate(prices,updateInPlace=TRUE,method=DISCRETE)
%table_CalendarReturns(prices, method= GEOMETRIC, printTable= NOPRINT)

data Calendar_Returns;
set Calendar_Returns;
where _name_= 'SPY';
if Jan= . then delete;
format JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC TOTAL best12.;
run;

/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from Calendar_Returns;
 %if ^&nv %then %do;
 	drop table Calendar_Returns;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(Calendar_Returns)) %then %do;
/*Error creating the data set, ensure compare fails*/
data Calendar_Returns;
	JAN = -999;
	FEB = JAN;
	MAR = JAN;
	APR = JAN;
	MAY = JAN;
	JUN= JAN;
	JUL= JAN;
	AUG= JAN;
	SEP= JAN;
	OCT= JAN;
	NOV= JAN;
	DEC= JAN;
run;
%end;

%if ^%sysfunc(exist(returns_from_r)) %then %do;
/*Error creating the data set, ensure compare fails*/
data returns_from_r;
	JAN = 999;
	FEB = JAN;
	MAR = JAN;
	APR = JAN;
	MAY = JAN;
	JUN= JAN;
	JUL= JAN;
	AUG= JAN;
	SEP= JAN;
	OCT= JAN;
	NOV= JAN;
	DEC= JAN;
run;
%end;

proc compare base=returns_from_r 
			 compare= Calendar_Returns 
			 method= absolute
			 criterion= 0.0001
			 out=diff(where=(_type_ = "DIF"
			            and (abs(JAN)> 1e-4 or abs(FEB)> 1e-4 or abs(MAR)> 1e-4 or abs(APR)> 1e-4
						or abs(MAY)> 1e-4 or abs(JUN)> 1e-4 or abs(JUL)> 1e-4 or abs(AUG)> 1e-4
						or abs(SEP)> 1e-4 or abs(OCT)> 1e-4 or abs(NOV)> 1e-4 or abs(DEC)> 1e-4 or abs(SPY)> 1e-4)
					))
			 noprint;
			 var JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC SPY;
			 with JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC TOTAL;
run;

data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST table_CalendarReturns_TEST1;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST table_CalendarReturns_TEST1;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete prices diff returns_from_r Calendar_Returns;
	quit;
%end;

filename x clear;

%mend;
