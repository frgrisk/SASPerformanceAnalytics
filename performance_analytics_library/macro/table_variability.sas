/*---------------------------------------------------------------
* NAME: table_variability.sas
*
* PURPOSE: Calculate variability in a returns data set.
*
* NOTES: Calculates mean absolute deviation, monthly standard deviation as well as annualized
	     standard deviation;
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* scale - Required. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* digits - Optional. Specifies the amount of digits to display in output. [Default= 4]
* dateColumn - Optional. Specifies the date column in the returns data set. [Default= Date]
* outData - Optional. Output Data Set with variability statistics. [Default= variability_table]
* printTable - Optional. Option to print output data set. {PRINT, NOPRINT} [Default= NOPRINT]
* MODIFIED:
* 6/29/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
* 5/26/2016 - QY - Replace part of mean absolution deviation by %Mean_Abs_Deivation
*				   Add parameter digits
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_variability(returns, 
								scale= 1,
								VARDEF = DF, 
								digits= 4,
								dateColumn= DATE,
								outData= variability_table,
								printTable= NOPRINT);

%local vars;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN tabel_variability: (&vars);

%Standard_Deviation(&returns, scale= &scale, annualized= TRUE, VARDEF= &VARDEF, outData= annualized_StdDev);
%Standard_Deviation(&returns, VARDEF= &VARDEF, outData= Monthly);
%Mean_Abs_Deviation(&returns, outData= MAD)

data &outData;
	format _stat_ $32. &vars %eval(&digits + 4).&digits;
	set MAD Monthly Annualized_StdDev;
	if _n_= 1 then _STAT_= 'Mean Absolute Deviation';
	if _n_= 2 then _STAT_= 'Monthly Standard Deviation';
	if _n_= 3 then _STAT_= 'Annualized Standard Deviation';
run;


%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outData noobs;
	run;
%end;

proc datasets lib= work nolist;
delete Monthly Annualized_StdDev MAD;
quit;

%mend;
