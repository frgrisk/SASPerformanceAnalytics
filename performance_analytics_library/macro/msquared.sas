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
* 3/09/2016 - QY - Parameter consistency
* 5/23/2016 - QY - Added VARDEF parameter
* 5/25/2016 - QY - Replaced calculation of annualized Rf by %scalar_annualized
* 6/06/2016 - QY - Added NET parameter
* 7/12/2016 - QY - Changed macro variables with datasets to eliminate truncate error
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

%local _temp_sr _temp_std _temp_bm vars i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM &Rf); 
%put VARS IN MSquared: (&vars);

%let _temp_std= %ranname();
%let _temp_sr= %ranname();
%let _temp_bm= %ranname();
%let i= %ranname();

%SharpeRatio_annualized(&returns,scale=&scale,Rf=&Rf,method=&method,VARDEF = &VARDEF, dateColumn=&dateColumn, outData=&_temp_sr)

%StdDev_annualized(&returns, scale=&scale, VARDEF = &VARDEF, dateColumn=&dateColumn ,outData= &_temp_std)

data &_temp_std(drop=&i);
	set &_temp_std;
	array ret[*] &vars;
	do &i=1 to dim(ret);
		ret[&i]=&BM;
	end;
run;

data &outData(keep=_stat_ &vars);
	format _STAT_ $32.;
	set &_temp_sr &_temp_std(in=b);
	array ret[*] &vars;

	do &i=1 to dim(ret);
		ret[&i] = ret[&i]*lag(ret[&i]) + %scalar_annualized(&rf,scale=&scale,method=&method,type=VALUE);
	end;
	if b;
	_STAT_ = "MSquared";
run;

%if %upcase(&NET)=TRUE %then %do;
	%return_annualized(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &_temp_bm);

	data &_temp_bm(keep=&vars);
		set &_temp_bm;
		array ret[*] &vars;
		do &i=1 to dim(ret);
			ret[&i]=&BM;
		end;
	run;

	data &outData(keep=_stat_ &vars);
	format _STAT_ $32.;
		set &_temp_bm &outData(in=b);
		array ret[*] &vars;

		do &i=1 to dim(ret);
			ret[&i] = ret[&i]-lag(ret[&i]);
		end;
		if b;
		_STAT_="Net MSquared";
	run;
%end;

proc datasets lib=work nolist;
	delete &_temp_std &_temp_sr &_temp_bm;
	run;
quit;

%mend;
