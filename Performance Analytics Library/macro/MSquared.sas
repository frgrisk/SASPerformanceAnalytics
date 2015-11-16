/*---------------------------------------------------------------
* NAME: MSquared.sas
*
* PURPOSE: M squared is a risk adjusted return useful to judge the size of relative performance between different portfolios. 
*		  Useful in comparing portfolios with different levels of risk.  
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set. 
* Rf- specifies a variable name or value that is the risk free rate of return.
* method- option to annualize returns using geometric or arithmetic chaining.  {GEOMETRIC, ARITHMETIC} [Default= GEOMETRIC].
* dateColumn - Date column in Data Set. Default=DATE
* outMSquared - output Data Set of MSquared.  Default= "MSquared".
* MODIFIED:
* 7/24/2015 – DP - Initial Creation
* 10/2/2015 - CJ - Replaced PROC SQL with %get_number_column_names
*				   Renamed temporary data sets with %ranname
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro MSquared(returns, 
						BM=,  
						Rf=0,
						scale=1,
						method= GEOMETRIC, 
						dateColumn= Date,
						outMSquared= MSquared);

%local _temp_sr _temp_std vars;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM &Rf); 
%put VARS IN CoMoments: (&vars);

%let _temp_std= %ranname();
%let _temp_sr= %ranname();

%let i= %ranname();

%SharpeRatio_annualized(&returns,scale=&scale,Rf=&rf,outSharpe=&_temp_sr,method=&method,dateColumn=&dateColumn)
%StdDev_annualized(&returns,scale=&scale,outStdDev= &_temp_std,dateColumn=&dateColumn)

data _null_;
set &_temp_std;
call symputx("sb",put(&Bm,best32.),"l");
run;

data &outMSquared(drop=&i);
format _STAT_ $32.;
set &_temp_sr(drop=&bm);
array vars[*] &vars;

_STAT_ = "MSquared";

do &i=1 to dim(vars);
	vars[&i] = vars[&i]*&sb + (1+&rf)**&scale - 1;
end;
run;

proc datasets lib=work nolist;
delete &_temp_std &_temp_sr;
run;
quit;

%mend;