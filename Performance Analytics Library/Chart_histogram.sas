/*---------------------------------------------------------------
* NAME: CAPM_JensenAlpha.sas
*
* PURPOSE: Create a simple histogram for an asset or instrument using returns data set.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* asset- required.  Specifies the benchmark asset or index in the returns data set.
* type- specifies whether y-axis should go by probability or frequency. {count, percent}, [Default= count]  
* title- required.  Title for histogram. [Default= asset name]
* xlabel- required.  Label for the x-axis.  [Default= "Returns"]
* ylabel- required.  Label for the y-axis.  [Default= "Frequency"]
* density- option to overlay a normal density curve on top of the histogram for comparison. If true, [Density= Density]
*
* MODIFIED:
* 7/24/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Chart_histogram(returns, 
								asset=,
								type= count,
								title= &asset,
								xlabel= Returns,
								ylabel= Frequency,
								density=0,
								dateColumn= Date);

/***********************************
*Figure out 2 level ds name of RETURNS
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
%let ds=&lib;
%let lib=work;
%end;
%put lib:&lib ds:&ds;

proc sgplot data= &returns;
histogram &asset/ scale= &type  binwidth= 0.001;
title "&title";
Xaxis label= "&xlabel";
Yaxis label= "&ylabel" ;
%if %upcase(&density)= %upcase(density) %then %do;
&density &asset;
%end;
run;
%mend;