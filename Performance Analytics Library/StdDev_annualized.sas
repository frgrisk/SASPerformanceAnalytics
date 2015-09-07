/*---------------------------------------------------------------
* NAME: StdDev_annualized.sas
*
* PURPOSE: calculate annualized standard deviation from a data
*		   set of returns.
*
* NOTES: Number of periods in a year are to scale (daily scale= 252,
*		 monthly scale= 12, quarterly scale= 4). 
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* scale - required.  Number of periods per year used in the calculation.
* annualized - option to annualize the standard deviation.  Default= FALSE
* dateColumn - Date column in Data Set. Default=DATE
* outStdDev - output Data Set with annualized standard deviation.  Default="annualized_StdDev". 
*
* MODIFIED:
* 6/3/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro StdDev_annualized(returns, 
					scale=, 
					dateColumn= DATE, 
					outStdDev= annualized_StdDev);


%Standard_Deviation(&returns, 
					scale=&scale, 
					annualized= TRUE,
					dateColumn= &dateColumn, 
					outStdDev= &outStdDev);
%mend;


