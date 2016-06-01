/*---------------------------------------------------------------
* NAME: Sterling_Ratio.sas
*
* PURPOSE: Calculate a Sterling reward/risk ratio
*
* NOTES: Both the Calmar and the Sterling ratio are the ratio of annualized return
*        over the absolute value of the maximum drawdown of an investment. The
*        Sterling ratio adds an excess risk measure to the maximum drawdown,
*        traditionally and defaulting to 10%.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.    
*         Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* excess - Optional. The yield of risk-free investment compared by any investment with a return stream.
*          Default=0.1.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Sterling ratios.  Default="SterlingRatio".
*
* MODIFIED:
* 6/1/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Sterling_Ratio(returns,
							scale= 1,
							method= DISCRETE,
							excess = 0.1,
							dateColumn= DATE,
							outData= SterlingRatio);
							
%local vars annualized drawdown i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Sterling_Ratio: (&vars);

%let annualized= %ranname();
%let drawdown= %ranname();
%let i = %ranname();

%return_annualized(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &annualized)
%max_drawdown(&returns, method= &method, dateColumn= &dateColumn, outData= &drawdown)

data &drawdown(drop=&i);
	set &drawdown;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]= abs(ret[&i]+&excess);
	end;
run;


data &outData (drop=&i);
	set &annualized &drawdown;

	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]= lag(ret[&i])/ret[&i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Sterling Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &annualized &drawdown;
run;
quit;

%mend;
