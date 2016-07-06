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
* returns - Required.  Data Set containing returns.
* scale - Required. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* annualized - Optional. Annualize the standard deviation. {TRUE,FALSE} Default= FALSE
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with annualized standard deviation.  Default="annualized_StdDev". 
*
* MODIFIED:
* 6/3/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro StdDev_annualized(returns, 
					scale= 1, 
					VARDEF = DF, 
					dateColumn= DATE, 
					outData= annualized_StdDev);


%Standard_Deviation(&returns, 
					scale=&scale, 
					annualized= TRUE,
					VARDEF = &VARDEF, 
					dateColumn= &dateColumn, 
					outData= &outData);
%mend;


