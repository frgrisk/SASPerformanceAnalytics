/*---------------------------------------------------------------
* NAME: Hurst_Index.sas
*
* PURPOSE: Calculate the Hurst index which can be used to measure whether returns are mean reverting, totally
*          random, or persistent.
*
* NOTES: A Hurst index between 0.5 and 1 suggests that the returns are persistent. 
		 At 0.5, the index suggests returns are totally random.
		 Between 0 and 0.5, it suggests that the returns are mean reverting.
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. output Data Set with hurst index.  Default="HurstIndex"
*
* MODIFIED:
* 6/09/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Hurst_Index(returns, 
						dateColumn= DATE, 
						outData= HurstIndex);

%local stat vars i;
%let stat= %ranname();

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &MAR);
%put VARS IN Hurst_Index: (&vars);

%let i= %ranname();

proc means data=&returns noprint;
	output out=&stat(keep=_stat_ &vars);
run;

data &stat(drop=&i);
	set &stat;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=log( ( lag2(ret[&i]) - lag3(ret[&i]) )/ret[&i] ) / log( lag4(ret[&i]) );
	end;
run;

data &outData;
	format _STAT_ $32.;
	set &stat end=last;
	_STAT_= "Hurst Index";
	if last;
run;

proc datasets lib= work nolist;
delete &stat;
run;
quit;							
%mend;
