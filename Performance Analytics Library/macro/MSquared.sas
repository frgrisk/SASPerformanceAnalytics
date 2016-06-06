/*---------------------------------------------------------------
* NAME: MSquared.sas
*
* PURPOSE: M squared is a risk adjusted return useful to judge the size of relative performance between different portfolios. 
*		  Useful in comparing portfolios with different levels of risk.  
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* NET - Optional. Specify whether report the value add over the benchmark. {FALSE, TRUE}. Default= FALSE.
* dateColumn - Optional. Date column in Data Set. Default=Date
* outData - Optional. Output Data Set of MSquared.  Default= "MSquared".
* MODIFIED:
* 7/24/2015 – DP - Initial Creation
* 10/2/2015 - CJ - Replaced PROC SQL with %get_number_column_names
*				   Renamed temporary data sets with %ranname
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
* 5/25/2016 - QY - Replace calculation of annualized Rf by %scalar_annualized
* 6/06/2016 - QY - Add NET parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro MSquared(returns, 
						BM=,  
						Rf= 0,
						scale= 1,
						method= DISCRETE, 
						VARDEF = DF, 
						NET= FALSE,
						dateColumn= DATE,
						outData= MSquared);

%local _temp_sr _temp_std _temp_bm vars i sb rm;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM &Rf); 
%put VARS IN MSquared: (&vars);

%let _temp_std= %ranname();
%let _temp_sr= %ranname();
%let _temp_bm= %ranname();

%let i= %ranname();

%SharpeRatio_annualized(&returns,scale=&scale,Rf=&Rf,method=&method,VARDEF = &VARDEF,dateColumn=&dateColumn, outData=&_temp_sr)

data &_temp_bm;
	set &returns(keep=&BM &dateColumn);
run;

%StdDev_annualized(&_temp_bm, scale=&scale,VARDEF = &VARDEF,dateColumn=&dateColumn ,outData= &_temp_std)
data _null_;
	set &_temp_std;
	call symputx("sb",put(&Bm,best32.),"l");
run;
%put &sb;

%return_annualized(&_temp_bm, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &_temp_bm);
data _null_;
	set &_temp_bm;
	call symputx("rm",put(&Bm,best32.),"l");
run;
%put &rm;

data &outData(drop=&i);
	format _STAT_ $32.;
	set &_temp_sr(drop=&bm);
	array vars[*] &vars;

	_STAT_ = "MSquared";

	do &i=1 to dim(vars);
		%if %upcase(&NET)=TRUE %then
			vars[&i] = vars[&i]*&sb -&rm + %scalar_annualized(&rf,scale=&scale,method=&method,type=VALUE);
		%else 
			vars[&i] = vars[&i]*&sb + %scalar_annualized(&rf,scale=&scale,method=&method,type=VALUE);
	end;
run;

proc datasets lib=work nolist;
	delete &_temp_std &_temp_sr &_temp_bm;
	run;
quit;

%mend;
