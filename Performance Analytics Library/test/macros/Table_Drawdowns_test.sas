%macro Table_Drawdowns_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\Table_Drawdowns_test_submit.sas";
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
put "returns = table.Drawdowns(returns[,1],top=10,digits=6)";
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
%Table_Drawdowns(prices,asset=IBM,top=10,digits=6);


/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from TableDrawdowns;
 %if ^&nv %then %do;
 	drop table TableDrawdowns;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(TableDrawdowns)) %then %do;
/*Error creating the data set, ensure compare fails*/
data TableDrawdowns;
	begindate = -999;
	troughdate = return;
	enddate = return;
	depth = return;
	length = return;
	totrough = return;
	recovery = return;
run;
%end;

%if ^%sysfunc(exist(returns_from_r)) %then %do;
/*Error creating the data set, ensure compare fails*/
data returns_from_r;
	from = -999;
	trough = return;
	to = return;
	depth = return;
	length = return;
	to_trough = return;
	recovery = return;
run;
%end;

proc compare base=returns_from_r 
			 compare=TableDrawdowns 
			 out=diff(where=(_type_ = "DIF"
			            and (fuzz(from) or fuzz(trough) or fuzz(to) 
			              or abs(depth)>1e-5 or fuzz(length) or fuzz(to_trough) or fuzz(recovery)
					)))
			 noprint;
			 var from trough to depth length to_trough recovery;
			 with begindate troughdate enddate depth length totrough recovery;
run;



data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST TABLE_DRAWDOWNS_TEST;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST TABLE_DRAWDOWNS_TEST;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices TableDrawdowns returns_from_r;
	quit;
%end;

%mend;
