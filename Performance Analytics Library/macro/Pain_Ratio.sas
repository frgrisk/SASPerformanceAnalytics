/*---------------------------------------------------------------
* NAME: Pain_Ratio.sas
*
* PURPOSE: Pain ratio of the return distribution
*
* NOTES: To calculate Pain ratio we divide the difference of the portfolio return
*        and the risk free rate by the Pain index
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - 
* scale - 
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
%macro Pain_Ratio(returns,
							Rf= 0,
							scale= 1,
							method= DISCRETE,
							dateColumn= DATE,
							outData= PainRatio);
							
%local vars pain_index annualized i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Pain_Ratio: (&vars);

%let pain_index= %ranname();
%let annualized= %ranname();
%let i = %ranname();

%return_annualized(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &annualized)
%return_excess(&annualized, Rf=&Rf, dateColumn= &dateColumn, outData= &annualized);

%Pain_Index(&returns, method= &method, dateColumn= &dateColumn, outData= &pain_index)


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
