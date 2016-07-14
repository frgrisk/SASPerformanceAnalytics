/*---------------------------------------------------------------
* NAME: table_DrawdownsRatio.sas
*
* PURPOSE: Create a table of drawdowns summary: Calmar ratio, Sterling ratio, 
*          Burke ratio, Pain index, Ulcer index, Pain ratio and Martin ratio.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns of the portfolio.
* Rf - Optional. The value or variable representing the risk free rate of return.  Default=0.
* scale - Optional. Number of periods in a year. {daily=252, monthly=12, quarterly=4, yearly=1}.  Default=1.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE.
* digits - Optional. Specifies number of digits displayed in the output. Default=4.
* dateColumn - Optional. Date column in Data Set.  Default=DATE.
* outData - Optional. Output table with drawdown ratios.  Default="table_DrawdownsRatio".
* printTable - Optional. Option to print output table. {PRINT, NOPRINT}.  Default= NOPRINT.
* 
* MODIFIED:
* 6/1/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_DrawdownsRatio(returns, 
							Rf= 0,
							scale= 1,
							method= DISCRETE,
							digits= 4,
							dateColumn= DATE, 
							outData= table_DrawdownsRatio,
							printTable= NOPRINT);

%local vars Sterling Calmar Burke PI Ulcer PR Martin i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf); 
%put VARS IN table_DrawdownsRatio: (&vars);

%let Sterling= %ranname();
%let Calmar= %ranname();
%let Burke= %ranname();
%let PI= %ranname();
%let Ulcer= %ranname();
%let PR= %ranname();
%let Martin= %ranname();
%let i= %ranname();

%Sterling_Ratio(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &sterling)
%Calmar_Ratio(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &Calmar)
%Burke_Ratio(&returns, Rf= &Rf, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &Burke)
%Pain_Index(&returns, method= &method, dateColumn= &dateColumn, outData= &PI)
%Ulcer_Index(&returns, method= &method, dateColumn= &dateColumn, outData= &Ulcer)
%Pain_Ratio(&returns, Rf= &Rf, method= &method, dateColumn= &dateColumn, outData= &PR)
%Martin_Ratio(&returns, Rf= &Rf, method= &method, dateColumn= &dateColumn, outData= &Martin)

data &outData;
	format _stat_ $32. &vars %eval(&digits + 4).&digits;
	set &Sterling &Calmar &Burke &PI &Ulcer &PR &Martin;
run;

proc datasets lib= work nolist;
delete &Sterling &Calmar &Burke &PI &Ulcer &PR &Martin;
run;
quit;

%if %upcase(&printTable)= PRINT %then %do;
proc print data= &outData noobs;
run;
%end;

%mend;


