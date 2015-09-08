/*---------------------------------------------------------------
* NAME: TrackingError.sas
*
* PURPOSE: calculate the tracking error of a portfolio given returns and a benchmark asset or index.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names the benchmark asset or index from the data set.
* annualized- specifies whether to return annualized tracking error rather than tracking error.
* scale- option if add_annualized= TRUE, the number of periods in a year (ie daily scale= 252, monthly scale= 12, quarterly scale= 4).
* dateColumn - Date column in Data Set. Default=DATE
* outTrackingError - output Data Set with tracking error.  Default="tracking_error".
*
* MODIFIED:
* 7/13/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro TrackingError(returns,
							BM=,
							annualized= FALSE,
							scale= 1,
							dateColumn=DATE,
							outTrackingError=tracking_error);

%local rp ;
%let rp = %ranname();

%return_excess(&returns, 
				Rf= &BM, 
				dateColumn= &dateColumn,
				outReturn=&rp);

data &rp;
set &rp;
drop &BM;
run;


%Standard_Deviation(&rp, 
						scale= &scale, 
						annualized= &annualized,
						dateColumn= &dateColumn, 
						outStdDev= &outTrackingError);

proc datasets lib= work nolist;
delete &rp;
run;
quit;
%mend;