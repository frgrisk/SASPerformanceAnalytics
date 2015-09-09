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


%SharpeRatio_annualized(&returns,scale=&scale,Rf=&rf,outSharpe=__temp_sr,method=&method,dateColumn=&dateColumn)
%StdDev_annualized(&returns,scale=&scale,outStdDev= __temp_std,dateColumn=&dateColumn)

data _null_;
set __temp_std;
call symputx("sb",put(&Bm,best32.),"l");
run;

data &outMSquared(drop=i);
format _STAT_ $32.;
set __temp_sr(drop=&bm);
array vars[*] _numeric_;

_STAT_ = "MSquared";

do i=1 to dim(vars);
	vars[i] = vars[i]*&sb + (1+&rf)**&scale - 1;
end;
run;

proc datasets lib=work nolist;
delete __temp_std __temp_sr
_tempRP _tempStd _meanRet1;
run;
quit;

%mend;