%macro Sort_Drawdowns_test(keep=FALSE);
%global pass notes;

%if &keep=FALSE %then %do;
	filename x temp;
%end;
%else %do;
	filename x "&dir\Sort_Drawdowns_test_submit.sas";
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
put "drawdowns=sortDrawdowns(findDrawdowns(returns, geometric=TRUE))";
put "returns=drawdowns[[1]]";
put "for(i in 2:7) {";
put "  returns=cbind(returns,drawdowns[[i]])";
put "}";
put "colnames(returns) = c('return','begin','trough','end','length','peaktotrough','recovery')";
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
%Sort_Drawdowns(prices,asset=IBM,method= DISCRETE);


/*If tables have 0 records then delete them.*/
proc sql noprint;
 %local nv;
 select count(*) into :nv TRIMMED from SortDrawdowns;
 %if ^&nv %then %do;
 	drop table SortDrawdowns;
 %end;
 
 select count(*) into :nv TRIMMED from returns_from_r;
 %if ^&nv %then %do;
 	drop table returns_from_r;
 %end;
quit ;

%if ^%sysfunc(exist(SortDrawdowns)) %then %do;
/*Error creating the data set, ensure compare fails*/
data SortDrawdowns;
	return = -999;
	begin = return;
	trough = return;
	end = return;
	length = return;
	peaktotrough = return;
	recovery = return;
run;
%end;

%if ^%sysfunc(exist(returns_from_r)) %then %do;
/*Error creating the data set, ensure compare fails*/
data returns_from_r;
	return = -999;
	begin = return;
	trough = return;
	end = return;
	length = return;
	peaktotrough = return;
	recovery = return;
run;
%end;

proc compare base=returns_from_r 
			 compare=SortDrawdowns 
			 out=diff(where=(_type_ = "DIF"
			            and (fuzz(return) or fuzz(begin) or fuzz(trough) 
			              or fuzz(end) or fuzz(length) or fuzz(peaktotrough) or fuzz(recovery)
					)))
			 noprint;
run;



data _null_;
if 0 then set diff nobs=n;
call symputx("n",n,"l");
stop;
run;

%if &n = 0 %then %do;
	%put NOTE: NO ERROR IN TEST SORT_DRAWDOWNS_TEST;
	%let pass=TRUE;
	%let notes=Passed;
%end;
%else %do;
	%put ERROR: PROBLEM IN TEST SORT_DRAWDOWNS_TEST;
	%let pass=FALSE;
	%let notes=Differences detected in outputs.;
%end;

%if &keep=FALSE %then %do;
	proc datasets lib=work nolist;
	delete diff prices SortDrawdowns returns_from_r;
	quit;
%end;

%mend;
