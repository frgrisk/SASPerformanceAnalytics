/*---------------------------------------------------------------
* NAME: table_AnnualizedReturns.sas
*
* PURPOSE: displays annualized summary statistics of return, standard deviation, and sharpe ratio.
*
* NOTES: The annualized returns displayed are the annualized average returns for the period.  
*		 The Sharpe ratio of a desired asset is calculatedgiven returns and a risk free rate.   Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in a return data set;
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set of annualized returns statistics.  Default="annualized_table".
* printTable - Optional. Option to print table.  {PRINT, NOPRINT} Default= NOPRINT
*
* MODIFIED:
* 6/10/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
* 5/25/2015 - QY - Add parameter digits 
*                  Edit format of output
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_Annualized_Returns(returns,
								Rf= 0,
								scale= 1, 
								method= DISCRETE, 
								VARDEF = DF,
								digits = 4,
								dateColumn= DATE, 
								outData= annualized_table, 
								printTable= NOPRINT);
%local Sharpe_Ratio Ann_Return Std_Dev _tempTable charTable vars;
%let Sharpe_Ratio= %ranname();
%let Ann_Return= %ranname();
%let Std_Dev= %ranname();
%let _tempTable= %ranname();
%let charTable= %ranname();

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN table_Annualized_Return: (&vars);

%SharpeRatio_annualized(&returns, 
					  Rf= &Rf, 
					  scale= &scale, 
					  VARDEF = DF,
					  dateColumn= &dateColumn, 
					  method= &method,
					  outData= &Sharpe_Ratio);

%return_annualized(&returns, 
							scale= &scale,
							method= &method,
							dateColumn= &dateColumn, 
							outData= &Ann_Return)

%Standard_Deviation(&returns, 
							scale= &scale,
							annualized= TRUE, 
							VARDEF = DF,
							dateColumn= &dateColumn, 
							outData= &Std_Dev);



data &outData (drop= &dateColumn n);
	format _stat_ $32. &vars %eval(&digits + 4).&digits;
	set &Ann_Return &Std_Dev &Sharpe_Ratio;
run;


proc transpose data= &outData out= &_tempTable(rename= (col1= Ann_Return) rename= (col2= Std_Dev) rename= (col3= Sharpe_Ratio));
run;

%to_character(datain= &_tempTable, dataout= &_tempTable, vars= Ann_Return Std_Dev Sharpe_Ratio, formats= percent12.4 percent8.2 8.4, n= 3);
run;

proc transpose data= &_tempTable out= &_tempTable name= _STAT_;
var _all_;
run;

data &charTable;
	set &_tempTable;
	if _STAT_= '_NAME_' then delete;

	drop _label_ &dateColumn;
run;

%if %upcase(&printTable)= PRINT %then %do;
proc print data= &charTable noobs;
title 'Annualized Return Statistics';
run; 
%end;

proc datasets lib=work nolist;
	delete &Sharpe_Ratio &Ann_Return &Std_Dev &_tempTable &charTable;
run;
quit;

%mend;


