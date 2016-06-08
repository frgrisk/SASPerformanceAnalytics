/*---------------------------------------------------------------
* NAME: SortinoRatio.sas
*
* PURPOSE: Calculate Sortino Ratio as a better measure than Sharpe Ratio.
*
* NOTES: The user has the option of choosing to use the number of whole observations
*        or the number of subset observations where the returns are smaller than MAR.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. Default=0
* group - Optional. Specifies to choose full observations or subset observations as 'n' in the divisor. {FULL, SUBSET}
*		  Default=FULL
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Sortino Ratio.  Default="SortinoRatio".
*
*
* MODIFIED:
* 6/7/2015 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro SortinoRatio(returns,
							MAR= 0,
							group= FULL,
							dateColumn= DATE,
							outData= SortinoRatio);

%Kappa(&returns, MAR=&MAR, L=2, group=&group, dateColumn=&dateColumn, outData=&outData);

%mend;
