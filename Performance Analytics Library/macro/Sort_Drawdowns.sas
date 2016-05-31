/*---------------------------------------------------------------
* NAME: Sort_Drawdowns.sas
*
* PURPOSE: Sort the drawdowns based on the return in an ascending order.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* assetName - Required. Name of the variable to find drawdown interval for.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with drawdowns.  Default="SortDrawdown".
*
* MODIFIED:
* 5/31/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Sort_Drawdowns(returns,
							assetName=,
							method= DISCRETE,
							dateColumn= DATE,
							outData= FindDrawdowns);


%Find_Drawdowns(&returns, assetName=&assetName, method=&method, dateColumn=&dateColumn, SortDrawdown= TRUE, outData=&SortDrawdown);

%mend;
