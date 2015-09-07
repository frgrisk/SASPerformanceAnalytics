/*---------------------------------------------------------------
* NAME: Adjusted_SharpeRatio.sas
*
* PURPOSE: Adjusts the Sharpe Ratio for skewness and kurtosis by incorporating a penalty factor 
*		   for negative skewness and excess kurtosis. 
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* Rf- the value or variable representing the risk free rate of return.
* scale - required.  Number of periods per year used in the calculation.
* dateColumn - Date column in Data Set. Default=DATE
* outAdjSharpe - output Data Set with adjusted Sharpe Ratios.  Default="adjusted_SharpeRatio". 
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Adjusted_SharpeRatio(returns, 
								Rf=0, 
								scale= 1,
								dateColumn= DATE, 
								outAdjSharpe= adjusted_SharpeRatio);

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

proc univariate data=_temp noprint vardef=N;
var COL1;
by _NAME_;
output out=_tempOut 
	SKEW=Skewness
	KURT=Kurtosis;
run;

proc transpose data=_tempOut out=_tempOut(drop=_label_ rename=(_name_=_stat_));
id _name_;
run;

data _tempOut(drop=i so);
format _stat_ $32. &z;
set _tempOut;
array vars[*] &z;
so = 10 + _n_;
if _stat_ = "Kurtosis" then do;
	do i=1 to dim(vars);
		vars[i] = vars[i] + 3;
	end;	
	output;
	so = so + 1;
	_stat_ = Excess_kurtosis;
	do i=1 to dim(vars);
		vars[i] = vars[i] - 3;
	end;	
end;
output;
run;

proc transpose data= _tempOut out= _tempSkewKurt;
id _stat_;
run;

data _tempSkewKurt;
set _tempSkewKurt;
adjSkew= Skewness/6;
adjKurt= (Kurtosis-3)/24;
drop Skewness Excess_kurtosis Kurtosis;
run;

proc transpose data= _tempSkewKurt out= _tempSkewKurt;
id _name_;
run;

%local lib ds nv;

proc sql noprint;
select name
into :ret separated by ' '
     from sashelp.vcolumn
where libname = upcase("&lib")
 and memname = upcase("&ds")
 and type = "num"
 and upcase(name) ^= upcase("&dateColumn")
and upcase(name) ^= upcase("&Rf");
quit;

%let nv = %sysfunc(countw(&ret));

data _tempRP(drop=i) _meanRet1(drop=i);
set &returns end=last nobs=nobs;

array ret[&nv] &ret;
array prod[&nv] _temporary_;

if _n_ = 1 then do;
	do i=1 to &nv;
		prod[i] = 1;

	end;
	delete;
end;

do i=1 to &nv;
	prod[i] = prod[i] * (1+(ret[i]/100))**(&scale);
end;
output _tempRP;

if last then do;
	do i=1 to &nv;

		ret[i] =100*((prod[i])**(1/(nobs-1)) - 1);
	end;
	output _meanRet1;
end;
run;

%return_excess(_meanRet1, 
					 	Rf= &Rf, 
						dateColumn= &dateColumn, 
						outReturn= _meanRet1);

%Standard_Deviation(&returns, 
							annualized= TRUE, 
							scale= &scale,
							dateColumn= &dateColumn,
							outStdDev= _tempStd);

data Sharpe;
set _meanRet1 _tempStd (in=s);
drop i Date;
array ret[&nv] &ret;

do i=1 to &nv;
	ret[i] = lag(ret[i])/ret[i];
end;

if s;
run;

quit;


data &outAdjSharpe(drop= i);
set _tempSkewKurt Sharpe;
array vars[*] &z;
do i= 1 to dim(vars);
vars[i]= vars[i]*(1+((lag2(vars[i]))*vars[i])-((lag(vars[i]))*(vars[i]**2)));
end;

if _name_= 'adjSkew' then delete;
if _name_= 'adjKurt' then delete;
_name_= 'adjSharpe';
run;


proc datasets lib=work nolist;
delete _temp _tempOut _meanRet1 _tempStd Sharpe _tempRP
		_tempSkewKurt;
run;
quit;

%mend;