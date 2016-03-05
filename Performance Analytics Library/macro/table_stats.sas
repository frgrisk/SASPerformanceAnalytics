/*---------------------------------------------------------------
* NAME: table_stats.sas
*
* PURPOSE: Calculate base statistics of a price data set.
*
* NOTES: Creates table with number of observations, number of missing observations, minimum, quartile 1, median, 
         mean, geometric mean, quartile 3, maximum, standard error(mean), confidence interval(mean), variance,
		 standard deviation, skewness, and kurtosis;
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* alpha - Optional. Significance level.  Specifies the level of significance for the mean. [Default= 0.05]
* outStats - Optional. Output Data Set with related statistics. [Default= Stats]
* dateColumn - Optional. Date column in Data Set. Default=Date
* digits - Optional. Specifies the number of digits to display in the output table. [Default= 4]
* printTable - Optional. Option to print table.  {PRINT,NOPRINT} [Default= NOPRINT]
* MODIFIED:
* 6/29/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_stats(returns, 	
					alpha= 0.05,
					outStats= Stats, 
					dateColumn=Date,
					digits=4,
					printTable= noprint);
%local lib ds z;

/***********************************
*Figure out 2 level ds name of returns
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;


/*******************************
*Get numeric fields in data set
*******************************/
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
output out=_tempOut 
	N=Observations 
	NMISS=NAs
	MIN=Minimum
	Q1=Q1
	Median=Median
	Mean=Mean
	Q3=Q3
	MAX=Maximum
	STDERR=SE_Mean
	VAR=Variance
	STD=Stdev
	SKEW=Skewness
	KURT=Kurtosis;

run;

data _tempOut;
set _tempOut;
LCL_Mean = mean - se_mean*quantile('t',1-&alpha/2,Observations-1);
UCL_Mean = mean + se_mean*quantile('t',1-&alpha/2,Observations-1);
run;

proc sql noprint;
create table _geoMean as
select exp(mean(log(1+col1)))-1 as GeoMean,
	   _name_
	from _temp
	where col1^=.
	group by _name_;

data _tempOut;
merge _tempOut _geoMean;
by _name_;
run;

proc transpose data=_tempOut out=_tempOut(drop=_LABEL_);
run;

data _tempOut;
format _Name_ $32. &z %eval(&digits+4).&digits;
set _tempOut;

select (_NAME_);
	when ("Observations") do;
		so = 1;
	end;
	when ("NAs") do;
		so =2;
	end;
	when ("Minimum") do;
		so =3;
	end;
	when ("Q1") do;
		so =4;
		_NAME_ = "Quartile 1";
	end;
	when ("Median") do;
		so =5;
	end;
	when ("Mean") do;
		so =6;
		_NAME_ = "Arithmetic Mean";
	end;
	when ("GeoMean") do;
		so =7;
		_NAME_ = "Geometric Mean";
	end;
	when ("Q3") do;
		so =8;
		_NAME_ = "Quartile 3";
	end;
	when ("Maximum") do;
		so =9;
	end;
	when ("SE_Mean") do;
		so =10;
		_NAME_ = "SE Mean";
	end;
	when ("LCL_Mean") do;
		so =11;
		_NAME_ = "LCL Mean (%sysfunc(putn(%sysevalf(1-&alpha),4.2)))";
	end;
	when ("UCL_Mean") do;
		so =12;
		_NAME_ = "UCL Mean (%sysfunc(putn(%sysevalf(1-&alpha),4.2)))";
	end;
	when ("Variance") do;
		so =13;
	end;
	when ("Stdev") do;
		so =14;
	end;
	when ("Skewness") do;
		so =15;
	end;
	when ("Kurtosis") do;
		so =16;
	end;
	otherwise so=999;
end;
run;

proc sort data=_tempOut out=&outStats(drop=so rename=(_NAME_=_STAT_));
by so;
run;


proc datasets lib=work nolist;
delete _temp _tempOut _geoMean;
run;
quit;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outStats noobs;
	run;
%end;

%mend;
