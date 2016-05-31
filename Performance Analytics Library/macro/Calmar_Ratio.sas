/*---------------------------------------------------------------
* NAME: Calmar_Ratio.sas
*
* PURPOSE: 
*
* NOTES: 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.    
*         Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Calmar ratios.  Default="CalmarRatio".
*
* MODIFIED:
* 5/27/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Calmar_Ratio(returns,
							scale= 1,
							method= DISCRETE,
							dateColumn= DATE,
							outData= CalmarRatio);
							
%local vars annualized drawdown;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Calmar_Ratio: (&vars);

%let annualized= %ranname();
%let drawdown= %ranname();

%return_annualized(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &annualized)
%max_drawdown(&returns, method= &method, dateColumn= &dateColumn, outData= &drawdown)

data &drawdown(drop=i);
	set &drawdown;
	array ret[*] &vars;

	do i= 1 to dim(ret);
	ret[i]= abs(ret[i]);
	end;
run;


data &outData (drop= i);
	set &annualized &drawdown;

	array ret[*] &vars;

	do i= 1 to dim(ret);
	ret[i]= lag(ret[i])/ret[i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Calmar Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &annualized &drawdown;
run;
quit;

%mend;
