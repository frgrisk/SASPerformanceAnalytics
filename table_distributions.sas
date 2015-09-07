/*---------------------------------------------------------------
* NAME: table_distributions.sas
*
* PURPOSE: Creates a table of distribution statistics.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* dateColumn- specifies the date column in the data set.  [Default= Date]
* outDistribution - output Data Set with distribution statistics. [Default= distribution_table]
* digits- specifies the amount of digits to display in output [Default= 4]
* scale- required.  Denotes the scale to annualize standard deviation. [Default= 1]
* printTable - option to print table.  {PRINT, NOPRINT} Default= NOPRINT
* MODIFIED:
* 6/29/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_distributions(returns, 
							dateColumn= Date, 
							outDistribution= distribution_table, 
							digits=4,
							scale=1,
							printTable= noprint);


%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;

proc sql noprint;
select name
	into :z separated by ' '
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

proc transpose data=&returns out=_temp;
by &dateColumn;
var &z;
run;

proc sort data=_temp;
by _name_;
run;

proc univariate data=_temp noprint ;
var COL1;
by _NAME_;
output out=_tempOut1 
	SKEW=Skewness
	KURT=Kurtosis;
run;

proc univariate data=_temp noprint vardef=N;
var COL1;
by _NAME_;
output out=_tempOut2 
	SKEW=Skewness
	KURT=Kurtosis;
run;

proc transpose data=_tempOut1 out=_tempOut1(drop=_label_ rename=(_name_=_stat_));
id _name_;
run;

proc transpose data=_tempOut2 out=_tempOut2(drop=_label_ rename=(_name_=_stat_));
id _name_;
run;

data _tempOut1;
format _stat_ $32. &z %eval(&digits + 4).&digits;
set _tempOut1;

so = 20 + _n_;
if _stat_ = "Kurtosis" then do;
	_stat_ = "Sample excess kurtosis";
end;
else if _stat_ = "Skewness" then do;
	_stat_ = "Sample skewness";
end;
run;

data _tempOut2(drop=i);
format _stat_ $32. &z %eval(&digits + 4).&digits;
set _tempOut2;
array vars[*] &z;
so = 10 + _n_;
if _stat_ = "Kurtosis" then do;
	do i=1 to dim(vars);
		vars[i] = vars[i] + 3;
	end;	
	output;
	so = so + 1;
	_stat_ = "Excess kurtosis";
	do i=1 to dim(vars);
		vars[i] = vars[i] - 3;
	end;	
end;
output;
run;

%standard_deviation(&returns,annualized= TRUE, scale=&scale,outStdDev=_tempOut3);

data _tempOut3;
format _stat_ $32. &z %eval(&digits + 4).&digits;
set _tempOut3;
so = _n_;

_stat_ = "Scaled Std Dev";
run;

data &outDistribution;
set _tempOut1-_tempOut3;
run;

proc sort data=&outDistribution out=&outDistribution(drop=so);
by so;
run;

proc datasets lib=work nolist;
delete _temp _tempOut1- _tempOut3;
quit;

%if %upcase(&printTable)= PRINT %then %do;
	proc print data= &outDistribution noobs;
	run; 
%end;

%mend;
