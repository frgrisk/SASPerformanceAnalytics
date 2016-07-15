/*---------------------------------------------------------------
* NAME: Martin_Ratio.sas
*
* PURPOSE: Martin ratio of the return distribution
*
* NOTES: To calculate Martin ratio we divide the difference of the portfolio return
*        and the risk free rate by the ulcer index
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. the value or variable representing the risk free rate of return.    
       Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.    
*         Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with martin ratio.  Default="MartinRatio".
*
* MODIFIED:
* 6/1/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Martin_Ratio(returns,
							Rf= 0,
							scale= 1,
							method= DISCRETE,
							dateColumn= DATE,
							outData= MartinRatio);
							
%local vars ulcer_index annualized i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Martin_Ratio: (&vars);

%let ulcer_index= %ranname();
%let annualized= %ranname();
%let i = %ranname();

%return_excess(&returns, Rf=&Rf, dateColumn= &dateColumn, outData= &annualized);
%return_annualized(&annualized, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &annualized)

%Ulcer_Index(&returns, method= &method, dateColumn= &dateColumn, outData= &ulcer_index)


data &outData (drop= &i);
	set &annualized &ulcer_index;

	array Ulcer[*] &vars;

	do &i= 1 to dim(Ulcer);
		Ulcer[&i]= lag(Ulcer[&i])/Ulcer[&i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Martin Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &ulcer_index &annualized;
run;
quit;

%mend;
