/*---------------------------------------------------------------
* NAME: Drawdowns.sas
*
* PURPOSE: Calculate the drawdowns since the previous peak
*
* NOTES: A drawdown is the decline of an investment since its most recent peak price. 
*		 If the return of the investment is positive, the drawdown is zero. 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with drawdowns.  Default="drawdowns".
*
* MODIFIED:
* 5/31/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Drawdowns(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= drawdowns);
							
%local vars nvar cumul_ret i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Drawdowns: (&vars);

%let nvar = %sysfunc(countw(&vars));

%let cumul_ret= %ranname();
%let i = %ranname();


%return_cumulative(&returns, method= &method, outData=&cumul_ret)

data &cumul_ret(drop=&i);
	set &cumul_ret;

	array var[*] &vars;

	do &i= 1 to dim(var);
	var[&i]=var[&i]+1;
	end;
run;

data &outData(drop=&i &dateColumn);
	set &cumul_ret;
	array ret[*] &vars;
	array max[&nvar] _temporary_;

	do &i=1 to dim(ret);
		if _n_=1 then 
			max[&i]=ret[&i];
		if ret[&i]>max[&i] then
			max[&i]=ret[&i];
		ret[&i]=ret[&i]/max[&i]-1;
	end;
run;



proc datasets lib=work nolist;
	delete &cumul_ret;
run;
quit;

%mend;
