/*---------------------------------------------------------------
* NAME: table_InformationRatio.sas
*
* PURPOSE: calculate the information ratio of a portfolio given returns and a benchmark asset or index as well as the tracking error
* 		   and annualized tracking error.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names the benchmark asset or index from the data set.
* scale- option if annualized= TRUE, the number of periods in a year (ie daily scale= 252, monthly scale= 12, quarterly scale= 4).
* dateColumn - Date column in Data Set. Default=DATE
* outTable - output Data Set with information ratio and tracking error.  Default="table_InformationRatio".
* printTable- option to print the output data set.  {PRINT, NOPRINT}, [Default= NOPRINT]
*
* MODIFIED:
* 7/13/2015 – CJ - Initial Creation
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