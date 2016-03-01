/*---------------------------------------------------------------
* NAME: Specific_Risk.sas
*
* PURPOSE: Specific risk is the standard deviation of the error term in the regression equation.
*
* NOTES: This is not the same definition as the one given by Michael Jensen. Market risk is the standard deviation of
the benchmark. The systematic risk is annualized.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* Scale- required.  Number of periods per year used in the calculation. Default= 1.
* dateColumn - Date column in Data Set. Default=DATE
* outSpecificRisk - output Data Set of systematic risk.  Default="Risk_specific".

* MODIFIED:
* 7/14/2015 – CJ - Initial Creation
* 03/1/2016 - DP - Changed to use table_SpecificRisk 
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