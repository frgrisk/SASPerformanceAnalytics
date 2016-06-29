/*---------------------------------------------------------------
* NAME: simple_normalize.sas
*
* PURPOSE: Calculates the weights of all values for a certain variable in 
*          the data set.
*
* MACRO OPTIONS:
* data - Required. Data set containing required variable.
* var - Required. Name of the variable to be manipulated.
* sum - Optional. The summation of total weights. [Default = 1]
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro simple_normalize(data,var,sum=1);
proc sql noprint;
%local s;
select sum(&var)/&sum format=best32. into :s from &data;
quit;

data &data;
set &data;
&var = &var/&s;
run;
%mend;
