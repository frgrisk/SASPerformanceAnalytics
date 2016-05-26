/*---------------------------------------------------------------
* NAME: Mean_Abs_Deviation.sas
*
* PURPOSE: Calculate mean absolute deviation. 
*
* NOTES: It is defined as the sum of absolute value of difference between the returns and average return divided by total number.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with mean absolute deviation.  Default="mean_abs_dev". 
*
* MODIFIED:
* 5/25/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Mean_Abs_Deviation(returns, 
						dateColumn= DATE, 
						outData= mean_abs_dev);

%local vars z meandata merged price_t;

%let meandata=%ranname();
%let merged=%ranname();
%let price_t=%ranname();


%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Mean_Abs_Deviation: (&vars);

/*table of mean*/
proc means data= &returns mean noprint;
output out= &meanData;
run;

data &meanData;
	set &meanData;
	drop _freq_ _type_ &dateColumn;
	if _stat_ = 'N' then delete;
	if _stat_ = 'STD' then delete;
	if _stat_ = 'MIN' then delete;
	if _stat_ = 'MAX' then delete;
run;

proc transpose data= &meanData out= &meanData;
run;

data &meanData;
set &meanData;
rename col1= Mean;
run;

/*proc sort data= &meanData;*/
/*by _name_;*/
/*run;*/

/*table of returns*/
proc transpose data= &returns(drop=&dateColumn) out= &price_t;
run;

/*proc sort data= &price_t;*/
/*by _name_;*/
/*run;*/

/*merged table*/
data &merged;
	merge &price_t &meanData;
run;

%let z= %get_number_column_names(_table= &merged, _exclude= col1);

data &merged(drop= i mean);
	set &merged;

	array z[*] &z;

	do i= 1 to dim(z);
		z[i]= sum(z[i], -(Mean));
		z[i]= abs(z[i]);
	end;
run;

proc transpose data= &merged out= &merged;
run;

proc means data= &merged mean noprint;
output out= &outData;
run;

data &outData;
	format _stat_ $32.;
	set &outData;
	drop _type_ _freq_;
	where _stat_ = 'MEAN';
	if _stat_='MEAN' then _stat_='Mean Absolute Deviation';
run;

proc datasets lib= work nolist;
delete &meandata &merged &price_t;
run;
quit;

%mend;

	

