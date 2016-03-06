/*---------------------------------------------------------------
* NAME: Standard_Deviation.sas
*
* PURPOSE: calculate standard deviation from a data set of returns.  
* 		   Option to annualize this value to a given scale.
*
* NOTES: Number of periods in a year are to scale (daily scale= 252,
*		 monthly scale= 12, quarterly scale= 4). 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* annualized - Optional. Option to annualize the standard deviation.  {TRUE, FALSE} Default= FALSE
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outStdDev - Optional. Output Data Set with annualized standard deviation.  Default="StdDev". 
*
* MODIFIED:
* 6/3/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Standard_Deviation(returns, 
						annualized= FALSE,
						scale=1, 
						dateColumn= DATE, 
						outStdDev= StdDev);
%local stdDev i;

%let i= %ranname();

proc means data= &returns noprint;
output out= &outStdDev;
run;


%let stdDev=%get_number_column_names(_table=&outStdDev,_exclude=&dateColumn _type_ _freq_);


data &outStdDev;
set &outStdDev;
where _stat_= 'STD';
drop &i _freq_ _type_ _stat_;

array stdDev[*] &stdDev;
do &i= 1 to dim(stdDev);

%if %upcase(&annualized) = TRUE %then %do;
		stdDev[&i] = stdDev[&i]*SQRT(&scale);
	%end;
	%else %if %upcase(&annualized) = FALSE %then %do;
		stdDev[&i]= stdDev[&i];
	%end;
	%else %do;
		%put ERROR: Invalid value in ANNUALIZED=&annualized.  Please use TRUE, or FALSE;
		stop;
	%end;
end;
run;
%mend;

	

