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
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with standard deviation.  Default="StdDev". 
*
* MODIFIED:
* 6/3/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
* 5/25/2016 - QY - Edit format of output
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Standard_Deviation(returns, 
						annualized= FALSE,
						scale= 1,
						VARDEF = DF, 
						dateColumn= DATE, 
						outData= StdDev);
%local stdDev i;

%let i= %ranname();

proc means data= &returns VARDEF= &VARDEF noprint;
output out= &outData;
run;


%let stdDev=%get_number_column_names(_table=&outData,_exclude=&dateColumn _type_ _freq_);


data &outData;
set &outData;
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

data &outData;
	format _stat_ $32.;
	set &outData(drop=&dateColumn);
	_stat_="Std_Dev";
run;

%mend;

	

