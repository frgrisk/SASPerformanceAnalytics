/*---------------------------------------------------------------
* NAME: table_autocorrelation.sas
*
* PURPOSE: computes the autocorrelations up to lag= &nlag of assets in a data set.  Presents this data in a table.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns of the portfolio.
* nlag - Required.  Specifies the number of lags to perform (and number of columns)
	     The value of lag should be at least p+d+q based from the model ARIMA(p, d, q).  "table_autocorrelation"
		 will not return a p-value if lag is less than this value.
* digits - Optional. Specifies the amount of digits to display in output. Default= 4
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Specifies name of output Data Set of autocorrelations.  Default="AutoCorrelations".
* printTable- Optional. Option to print table.  {PRINT, NOPRINT}. Default= [NOPRINT]
* MODIFIED:
* 6/23/2015 – CJ - Initial Creation
* 7/15/2015 - DP - Updated to use only TIMESERIES and calculate Ljung-Box in Data Step.
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/25/2016 - QY - Add parameter digits
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_autocorrelation(returns, 
								nlag=, 
								digits=4,
								dateColumn= DATE, 
								outData= AutoCorrelations,
								printTable= NOPRINT);

%local lib ds vars n z i;

%let i = %ranname();

%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;


proc sql noprint;
select name
	into :vars separated by ' '
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");

select count(*)-1 into :n trimmed from &returns;
quit;


proc timeseries data= &returns 
				out=_null_
				outcorr= &outData;
	corr acf /transpose= YES nlag= &nlag;
	var &vars;
run;


data &outData;
	set &outData;
	drop _label_ _stat_ lag0 Q &i;
	rename _name_= StockId;

	/*Ljung-Box Test*/
	array lag[&nlag];
	Q = 0;
	do &i=1 to &nlag;
		Q = Q + (lag[&i]**2)/(&n-&i);
	end;
	Q = Q*&n*(&n+2);
	P_Value = 1-cdf('chisq',Q,6);
run;

%let z= %get_number_column_names(_table= &outData, _exclude= _name_);
data &outData;
	retain stockID;
	format &z %eval(&digits + 4).&digits;
	set &outData;
run;


%if %upcase(&printTable)= PRINT %then %do;
proc print data= &outData noobs;
run; 
%end;
%mend;
