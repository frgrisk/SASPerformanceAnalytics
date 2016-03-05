/*---------------------------------------------------------------
* NAME: table_InformationRatio.sas
*
* PURPOSE: calculate the information ratio of a portfolio given returns and a benchmark asset or index as well as the tracking error
* 		   and annualized tracking error.
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outTable - Optional. Output Data Set with information ratio and tracking error.  Default="table_InformationRatio".
* printTable - Optional. Option to print the output data set.  {PRINT, NOPRINT}, [Default= NOPRINT]
*
* MODIFIED:
* 7/13/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_InformationRatio(returns,
								BM=,
								scale= 1,
								dateColumn=DATE,
								outTable=table_InformationRatio, 
								printTable= NOPRINT);

%local tea teb ir;

%let tea=%ranname();
%let teb=%ranname();
%let ir=%ranname();

%TrackingError(&returns,
						BM= &BM,
						annualized= TRUE,
						scale= &scale,
						outTrackingError=&tea);

%TrackingError(&returns,
						BM= &BM,
						annualized= FALSE,
						scale= &scale,
						outTrackingError= &teb);

%Information_Ratio(&returns, 
						BM= &BM, 
						scale= &scale,
						dateColumn= &dateColumn,
						outInformationRatio= &ir);

data &tea;
format _stat_ $32.;
set &tea;
_stat_= 'Annualized_TE';
run;

data &teb;
format _stat_ $32.;
set &teb;
_stat_= 'Tracking_Error';
run;

data &outTable;
set &teb &tea &ir ;
run;

%if %upcase(&printTable) = PRINT %then %do;
	proc print data=&outTable noobs;
	run;
%end;

proc datasets lib= work nolist;
delete &teb &tea &ir;
run;
quit;
%mend;
