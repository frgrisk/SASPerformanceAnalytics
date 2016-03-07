/*---------------------------------------------------------------
* NAME: Specific_Risk.sas
*
* PURPOSE: Specific risk is the standard deviation of the error term in the regression equation.
*
* NOTES: This is not the same definition as the one given by Michael Jensen. Market risk is the standard deviation of
the benchmark. The systematic risk is annualized.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outSpecificRisk - Optional. Output Data Set of systematic risk.  Default="Risk_specific".

* MODIFIED:
* 7/14/2015 – CJ - Initial Creation
* 03/1/2016 - DP - Changed to use table_SpecificRisk 
* 3/05/2016 – RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Specific_Risk(returns, 
						BM=, 
						Rf=0,
						scale= 1,
						dateColumn= DATE,
						outSpecificRisk= Risk_specific);

%table_SpecificRisk(&returns, 
					BM=&BM, 
					Rf=&RF,
					scale= &scale,
					dateColumn= &dateColumn,
					outTable= &outSpecificRisk,
					printTable= NOPRINT);

data &outSpecificRisk;
	set &outSpecificRisk(where=(_STAT_ = "Specific Risk"));
run;


%mend;
