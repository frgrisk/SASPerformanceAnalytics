/*---------------------------------------------------------------
* NAME: Systematic_Risk.sas
*
* PURPOSE: Systematic risk as defined by Bacon(2008) is the product of beta by market risk.
*
* NOTES: This is not the same definition as the one given by Michael Jensen. Market risk is the standard deviation of
the benchmark. The systematic risk is annualized.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set. 
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* Scale- number of periods in a year (daily scale= 252, monthly scale= 12, quarterly scale= 4).
* dateColumn - Date column in Data Set. Default=DATE
* outSR - output Data Set of systematic risk.  Default="Risk_systematic".

* MODIFIED:
* 7/14/2015 – CJ - Initial Creation
* 03/1/2016 - DP - Changed to use table_SpecificRisk 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Systematic_Risk(returns,
						BM=, 
						Rf=0, 
						scale= 1, 
						dateColumn= DATE,
						outSR= Risk_systematic);

%table_SpecificRisk(&returns, 
					BM=&BM, 
					Rf=&RF,
					scale= &scale,
					dateColumn= &dateColumn,
					outTable= &outSR,
					printTable= NOPRINT);

data &outSR;
	set &outSR(where=(_STAT_ = "Systematic Risk"));
run;

%mend;
