/*---------------------------------------------------------------
* NAME: table_distributions.sas
*
* PURPOSE: Creates a table of distribution statistics.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* dateColumn - Optional. Specifies the date column in the data set.  Default= Date
* outData - Optional. Output Data Set with distribution statistics. Default= distribution_table
* digits - Optional. Specifies the amount of digits to display in output. Default= 4
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* printTable - Optional. Option to print table.  {PRINT, NOPRINT} Default= NOPRINT
* MODIFIED:
* 6/29/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
* 5/24/2016 - QY - Fix scale problem in Scaled Std Dev
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_distributions(returns, 
                            scale= 1,
							dateColumn= DATE, 
							outData= distribution_table, 
							digits= 4,
							VARDEF = DF,
							printTable= NOPRINT);


/*%let lib = %scan(&returns,1,%str(.));*/
/*%let ds = %scan(&returns,2,%str(.));*/
/*%if "&ds" = "" %then %do;*/
/*	%let ds=&lib;*/
/*	%let lib=work;*/
/*%end;*/
/*%put lib:&lib ds:&ds;*/
/**/
/*proc sql noprint;*/
/*select name*/
/*	into :z separated by ' '*/
/*	from sashelp.vcolumn*/
/*	where libname = upcase("&lib")*/
/*	  and memname = upcase("&ds")*/
/*	  and type = "num"*/
/*	  and upcase(name) ^= upcase("&dateColumn");*/
/*quit;*/

%local z i;
%let z= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN table_distribution: (&z);

%let i= %ranname();


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

data _tempOut2(drop=&i);
format _stat_ $32. &z %eval(&digits + 4).&digits;
set _tempOut2;
array vars[*] &z;
so = 10 + _n_;
if _stat_ = "Kurtosis" then do;
	do &i=1 to dim(vars);
		vars[&i] = vars[&i] + 3;
	end;	
	output;
	so = so + 1;
	_stat_ = "Excess kurtosis";
	do &i=1 to dim(vars);
		vars[&i] = vars[&i] - 3;
	end;	
end;
output;
run;

%standard_deviation(&returns,annualized= TRUE, scale=&scale, VARDEF= &VARDEF, outData=_tempOut3);

data _tempOut3(drop=&i);
	format _stat_ $32. &z %eval(&digits + 4).&digits;
	set _tempOut3;
	so = _n_;

	array STD_scaled[*] &z;

	do &i= 1 to dim(STD_scaled);
	STD_scaled[&i]= STD_scaled[&i]/sqrt(&scale);
	end;

	_stat_ = "Scaled Std Dev";
run;

data &outData;
set _tempOut1-_tempOut3;
run;

proc sort data=&outData out=&outData(drop=so &dateColumn);
by so;
run;

proc datasets lib=work nolist;
delete _temp _tempOut1- _tempOut3;
quit;

%if %upcase(&printTable)= PRINT %then %do;
	proc print data= &outData noobs;
	run; 
%end;

%mend;
