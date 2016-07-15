/*---------------------------------------------------------------
* NAME: pain_index.sas
*
* PURPOSE: Pain index of the return distribution
*
* NOTES: The pain index is the mean value of the drawdowns over the entire 
*        analysis period. The measure is similar to the Ulcer index except that 
*        the drawdowns are not squared.  Also, it's different than the average
*        drawdown, in that the numerator is the total number of observations 
*        rather than the number of drawdowns.
*        Visually, the pain index is the area of the region that is enclosed by 
*        the horizontal line at zero percent and the drawdown line in the 
*        Drawdown chart.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with pain index.  Default="PainIndex".
*
* MODIFIED:
* 5/31/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro pain_index(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= painindex);
							
%local vars drawdown stat_mean i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Pain_Index: (&vars);

%let drawdown= %ranname();
%let stat_sum= %ranname();
%let stat_n= %ranname();
%let i = %ranname();

%drawdowns(&returns, method= &method, dateColumn= &dateColumn, outData= &drawdown)

data &drawdown(drop=&i);
	set &drawdown(firstobs=2);
	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]= abs(ret[&i]);
	end;
run;

proc means data= &drawdown mean noprint;
output out= &stat_mean mean=;
run;

data &outData (keep=_stat_ &vars);
format _STAT_ $32.;
	set &stat_mean;
	_STAT_= 'Pain Index';
run;

proc datasets lib=work nolist;
	delete &drawdown &stat_mean;
run;
quit;

%mend;
