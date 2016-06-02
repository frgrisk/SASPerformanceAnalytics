/*---------------------------------------------------------------
* NAME: Pain_Index.sas
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
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
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
%macro Pain_Index(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= PainIndex);
							
%local vars drawdown stat_sum stat_n i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Pain_Index: (&vars);

%let drawdown= %ranname();
%let stat_sum= %ranname();
%let stat_n= %ranname();
%let i = %ranname();

%Drawdowns(&returns, method= &method, dateColumn= &dateColumn, outData= &drawdown)

data &drawdown(drop=&i);
	set &drawdown(firstobs=2);
	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]= abs(ret[&i]);
	end;
run;

proc means data= &drawdown sum n noprint;
output out= &stat_sum sum=;
output out= &stat_n n=;
run;

data &outData (drop= &i _type_ _freq_);
	set &stat_sum &stat_n;

	array Pain[*] &vars;

	do &i= 1 to dim(Pain);
		Pain[&i]= lag(Pain[&i])/Pain[&i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Pain Index';
	if last; 
run;

proc datasets lib=work nolist;
	delete &drawdown &stat_sum &stat_n;
run;
quit;

%mend;
