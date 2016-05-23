/*---------------------------------------------------------------
* NAME: Systematic_Risk.sas
*
* PURPOSE: Systematic risk as defined by Bacon(2008) is the product of beta by market risk.
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
* outData - Optional. Output Data Set of systematic risk.  Default="Risk_systematic".

* MODIFIED:
* 7/14/2015 – CJ - Initial Creation
* 03/1/2016 - DP - Changed to use table_SpecificRisk 
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Systematic_Risk(returns,
						BM=, 
						Rf= 0, 
						scale= 1, 
						dateColumn= DATE,
						outData= Risk_systematic);

%table_SpecificRisk(&returns, 
					BM=&BM, 
					Rf=&RF,
					scale= &scale,
					dateColumn= &dateColumn,
					outData= &outData,
					printTable= NOPRINT);

data &outData;
	set &outData(where=(_STAT_ = "Systematic Risk"));
run;

%mend;
