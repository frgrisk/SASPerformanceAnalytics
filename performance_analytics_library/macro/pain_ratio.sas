/*---------------------------------------------------------------
* NAME: pain_ratio.sas
*
* PURPOSE: Pain ratio of the return distribution
*
* NOTES: To calculate Pain ratio we divide the difference of the portfolio return
*        and the risk free rate by the Pain index
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. the value or variable representing the risk free rate of return.    
*      Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.    
*         Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with pain ratio.  Default="PainRatio".
*
* MODIFIED:
* 6/1/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro pain_ratio(returns,
							Rf= 0,
							scale= 1,
							method= DISCRETE,
							dateColumn= DATE,
							outData= painratio);
							
%local vars pain_index annualized i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Pain_Ratio: (&vars);

%let pain_index= %ranname();
%let annualized= %ranname();
%let i = %ranname();

%return_annualized(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &annualized)
%return_excess(&annualized, Rf=&Rf, dateColumn= &dateColumn, outData= &annualized);

%pain_index(&returns, method= &method, dateColumn= &dateColumn, outData= &pain_index)


data &outData (drop= &i);
	set &annualized &pain_index;

	array Pain[*] &vars;

	do &i= 1 to dim(Pain);
		Pain[&i]= lag(Pain[&i])/Pain[&i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Pain Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &pain_index &annualized;
run;
quit;

%mend;
