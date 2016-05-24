/*---------------------------------------------------------------
* NAME: TrackingError.sas
*
* PURPOSE: calculate the tracking error of a portfolio given returns and a benchmark asset or index.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* annualized - Optional. Specifies whether to return annualized tracking error rather than tracking error. {TRUE,FALSE}. Default= FALSE
* scale - Optional. Option if annualized= TRUE, the number of periods in a year (ie daily scale= 252, monthly scale= 12, quarterly scale= 4).
          Default= 1
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with tracking error.  Default="tracking_error".
*
* MODIFIED:
* 7/13/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro TrackingError(returns,
							BM=,
							annualized= FALSE,
							scale= 1,
							VARDEF = DF, 
							dateColumn= DATE,
							outData= tracking_error);

%local rp ;
%let rp = %ranname();

%return_excess(&returns, 
				Rf= &BM, 
				dateColumn= &dateColumn,
				outData=&rp);

data &rp;
set &rp;
drop &BM;
run;


%Standard_Deviation(&rp, 
						scale= &scale, 
						annualized= &annualized,
						VARDEF= &VARDEF, 
						dateColumn= &dateColumn, 
						outData= &outData);

data &outData;
format _stat_ $32.;
_stat_='Tracking Error';
set &outData(drop=&dateColumn);
run;

proc datasets lib= work nolist;
delete &rp;
run;
quit;
%mend;
