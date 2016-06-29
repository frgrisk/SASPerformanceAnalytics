/*---------------------------------------------------------------
* NAME: BernardoLedoit_Ratio.sas
*
* PURPOSE: Calculate Bernardo and Ledoit ratio of the return distribution
*
* NOTES: To calculate Bernardo and Ledoit ratio we take the sum of the subset of 
*        returns that are above 0 and we divide it by the opposite of the sum of 
*        the subset of returns that are below 0
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with BernardoLedoit ratio.  Default="BLratio".
*
* MODIFIED:
* 6/7/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro BernardoLedoit_Ratio(returns,
				 			 dateColumn= DATE,
			     			 outData= BLratio);
							
%local vars upside downside i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN BernardoLedoit_Ratio: (&vars);

%let upside= %ranname();
%let downside= %ranname();

%let i = %ranname();

data &upside(drop=&i &dateColumn);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]<=0 then ret[&i]=.; 
	end;
run;

proc means data=&upside sum noprint;
	output out=&upside sum=;
run;


data &downside(drop=&i &dateColumn);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]>=0 then ret[&i]=.; 
		ret[&i]=-ret[&i];
	end;
run;

proc means data=&downside sum noprint;
	output out=&downside sum=;
run;

data &outData (keep=&vars);
	set &upside &downside;

	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= lag(ret[&i])/ret[&i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'BernardoLedoit Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &upside &downside;
run;
quit;

%mend;
