/*---------------------------------------------------------------
* NAME: SharpeRatio_annualized.sas
*
* PURPOSE: displays an annualized sharpe ratio with option for geometric or arithmetic chaining.
*
* NOTES: The Sharpe ratio of a desired asset is calculated given returns, a risk free rate, and scale. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* scale - number of periods per year for which Sharpe Ratio is annualized.
* method- option for arithmetic or geometric chaining.  Default= GEOMETRIC
* dateColumn - Date column in Data Set. Default=DATE
* outSharpe - output Data Set with risk premium.  Default="Annualized_SharpeRatio".
*
* MODIFIED:
* 6/12/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro SharpeRatio_annualized(returns, 
					  				 Rf= 0, 
					 				 scale= 0,
					  				 method= GEOMETRIC, 
					  				 dateColumn= date, 
					  				 outSharpe= Annualized_SharpeRatio);


%local lib ds nv;

%return_excess(&returns, 
					 	Rf= &Rf, 
						dateColumn= &dateColumn, 
						outReturn= _tempRP);

/***********************************
*Figure out 2 level ds name of RETURNS
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
%let ds=&lib;
%let lib=work;
%end;
%put lib:&lib ds:&ds;

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

/*Create a series for taking STDev and Calculate Mean*/
data _tempRP(drop=i) _meanRet1(drop=i);
set _tempRP end=last nobs=nobs;

array ret[&nv] &ret;
array prod[&nv] _temporary_;

if _n_ = 1 then do;
	do i=1 to &nv;
		/*Geometric*/
%if %upcase(&method) = GEOMETRIC %then %do;
		prod[i] = 1;
%end;

		/*Arithmetic*/
%else %if %upcase(&method) = ARITHMETIC %then %do;
		prod[i] = 0;
%end;
	end;
	delete;
end;

do i=1 to &nv;
	/*Geometric*/
%if %upcase(&method) = GEOMETRIC %then %do;
	prod[i] = prod[i] * (1+ret[i])**(&scale);
	
%end;
	/*Arithmetic*/
%else %if %upcase(&method) = ARITHMETIC %then %do;
	prod[i] = prod[i] + ret[i]*sqrt(&scale);
	ret[i] = ret[i] * sqrt(&scale);
%end;
end;
output _tempRp;

if last then do;
	do i=1 to &nv;
	%if %upcase(&method) = GEOMETRIC %then %do;

		ret[i] =(prod[i])**(1/(nobs-1)) - 1;
		ret[i]= ret[i]/(&scale);
	%end;

		/*Arithmetic*/
	%else %if %upcase(&method) = ARITHMETIC %then %do;
		ret[i] = prod[i]/(nobs-1);
	%end;
	ret[i] = ret[i] * sqrt(&scale);
	end;
	output _meanRet1;
end;
run;

proc summary data=_tempRp;
var &ret;
output out=_tempStd(drop=_type_ _freq_) std=;
run;

data &outSharpe;
set _meanRet1 _tempStd (in=s);
drop i Date;
array ret[&nv] &ret;

do i=1 to &nv;
	ret[i] = lag(ret[i])/ret[i];
end;

if s;
run;

quit; 
%mend;
