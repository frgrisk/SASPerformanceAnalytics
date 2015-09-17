/*---------------------------------------------------------------
* NAME: Adjusted_SharpeRatio.sas
*
* PURPOSE: Adjusts the Sharpe Ratio for skewness and kurtosis by incorporating a penalty factor 
*		   for negative skewness and excess kurtosis. 
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* method- {GEOMETRIC, ARITHMETIC}. Specifies calculating returns using geometric or arithmetic chaining.
* Rf- the value or variable representing the risk free rate of return.
* scale - required.  Number of periods per year used in the calculation.
* dateColumn - Date column in Data Set. Default=DATE
* outAdjSharpe - output Data Set with adjusted Sharpe Ratios.  Default="adjusted_SharpeRatio". 
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
* 9/17/2015 - CJ - Replaced temporary variable and data set names with random names.
*				   Defined all local variables.
*				   Replaced Proc SQL statement with %get_number_column_names().
*				   Renamed column statistic "_STAT_" to be consistent with SAS results.
*				   Replaced code returning geometric chained returns with %return_annualized
*				   Inserted parameter method= to allow user to choose arithmetic or geometricaly chained returns.
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Adjusted_SharpeRatio(returns,
								method= GEOMETRIC, 
								Rf=0, 
								scale= 1,
								dateColumn= DATE, 
								outAdjSharpe= adjusted_SharpeRatio);


%local ret minRf nv i aa ab ac ad ae af ag;
%let ret= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put RET IN Adjusted_SharpeRatio: (&ret);
%let minRf= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put minRf IN Adjusted_SharpeRatio: (&minRf);
%let nv = %sysfunc(countw(&minRf));
%let aa= %ranname();
%let ab= %ranname();
%let ac= %ranname();
%let ad= %ranname();
%let ae= %ranname();
%let af= %ranname();
%let ag= %ranname();

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

proc transpose data=&returns out=&aa;
by &dateColumn;
var &ret;
run;

proc sort data=&aa;
by _name_;
run;

proc univariate data=&aa noprint vardef=N;
var COL1;
by _NAME_;
output out=&aa
	SKEW=Skewness
	KURT=Kurtosis;
run;

proc transpose data=&aa out=&aa(drop=_label_ rename=(_name_=_stat_));
id _name_;
run;

data &aa(drop=&ab so);
format _stat_ $32. &ret;
set &aa;
array vars[*] &ret;
so = 10 + _n_;
if _stat_ = "Kurtosis" then do;
	do &ab=1 to dim(vars);
		vars[&ab] = vars[&ab] + 3;
	end;	
	output;
	so = so + 1;
	_stat_ = Excess_kurtosis;
	do &ab=1 to dim(vars);
		vars[&ab] = vars[&ab] - 3;
	end;	
end;
output;
run;

proc transpose data= &aa out= &aa;
id _stat_;
run;

data &aa;
set &aa;
adjSkew= Skewness/6;
adjKurt= (Kurtosis-3)/24;
drop Skewness Excess_kurtosis Kurtosis;
run;

proc transpose data= &aa out= &aa;
id _name_;
run;

/*proc sql noprint;*/
/*select name*/
/*into :ret separated by ' '*/
/*     from sashelp.vcolumn*/
/*where libname = upcase("&lib")*/
/* and memname = upcase("&ds")*/
/* and type = "num"*/
/* and upcase(name) ^= upcase("&dateColumn")*/
/*and upcase(name) ^= upcase("&Rf");*/
/*quit;*/

/*data &af(drop=&ae) &ag(drop=&ae);*/
/*set &returns end=last nobs=nobs;*/
/**/
/*array ret[&nv] &ret1;*/
/*array prod[&nv] _temporary_;*/
/**/
/*if _n_ = 1 then do;*/
/*	do &ae=1 to &nv;*/
/*		prod[&ae] = 1;*/
/**/
/*	end;*/
/*	delete;*/
/*end;*/
/**/
/*do &ae=1 to &nv;*/
/*	prod[&ae] = prod[&ae] * (1+(ret[&ae]/100))**(&scale);*/
/*end;*/
/*output &af;*/
/**/
/*if last then do;*/
/*	do &ae=1 to &nv;*/
/**/
/*		ret[&ae] =100*((prod[&ae])**(1/(nobs-1)) - 1);*/
/*	end;*/
/*	output &ag;*/
/*end;*/
/*run;*/
%return_annualized(&returns, scale= &scale, method= &method, outReturnAnnualized= &ac);
%return_excess(&ac, Rf= &Rf, dateColumn= &dateColumn, outReturn= &ac);

%Standard_Deviation(&returns, 
							annualized= TRUE, 
							scale= &scale,
							dateColumn= &dateColumn,
							outStdDev= &ad);

data &ae (drop= &af);
set &ac &ad (in=s);
drop &ae Date;
array minRf[&nv] &minRf;

do &af=1 to &nv;
	minRf[&af] = lag(minRf[&af])/minRf[&af];
end;

if s;
run;

quit;


data &outAdjSharpe(drop= &ag rename= (_name_= _STAT_));
format _NAME_ $char16.;
set &aa &ae;
array vars[*] &minRf;
do &ag= 1 to dim(vars);
vars[&ag]= vars[&ag]*(1+((lag2(vars[&ag]))*vars[&ag])-((lag(vars[&ag]))*(vars[&ag]**2)));
end;

if _NAME_= 'adjSkew' then delete;
if _NAME_= 'adjKurt' then delete;
_NAME_= '_Adj_SharpeRatio';
run;


proc datasets lib=work nolist;
delete &aa &ac &ad &ae;
run;
quit;

%mend;
