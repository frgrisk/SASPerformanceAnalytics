/*---------------------------------------------------------------
* NAME: return_relative.sas
*
* PURPOSE: Calculate relative cumulative performance through time.
*
* NOTES: Calculate ratio of the cumulative performance for assets over benchmark 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with relative cumulative performance. Default="relative_cum" 
*
* MODIFIED:
* 7/20/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro return_relative(returns,
							BM= ,
							method= DISCRETE,
							dateColumn= DATE,
							outData= relative_cum);

%local vars  i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM); 
%put VARS IN return_relative: (&vars);

%let i= %ranname();

%return_cumulative(&returns,method= &method,dateColumn= &dateColumn,outData= &outData);

data &outData(drop=&i &BM);
	set &outData;
	array ret[*] &vars;
	do &i=1 to dim(ret);
		ret[&i]=(1+ret[&i])/(1+&BM);
	end;
run;

%mend;

