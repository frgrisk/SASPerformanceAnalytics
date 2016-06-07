/*---------------------------------------------------------------
* NAME: upside_risk.sas
*
* PURPOSE: 
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* MAR - 
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* option- Required.  
* group - Optional. 
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. output Data Set with upside risks.  Default="UpsideRisk"
*
* MODIFIED:
* 6/07/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro upside_risk(returns, 
						MAR= 0, 
						option=,
						group= FULL,
						dateColumn= DATE, 
						outData= UpsideRisk);

%local nv stat_sum stat_n vars i;
%let stat_sum= %ranname();
%let stat_n= %ranname();

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &MAR);
%put VARS IN upside_risk: (&vars);

%let nv= %sysfunc(countw(&vars));
%let i= %ranname();

%if %upcase (&group)= FULL %then %do;
proc means data=&returns n noprint;
	output out=&stat_n n=;
run;
%end;

data &returns(drop=&i &dateColumn);
	set &returns(firstobs=2);
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=ret[&i]-&MAR;
	end;
run;

data &returns(drop=&i);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]<=0 then ret[&i]=.; 
	end;
run;


%if %upcase(&group)= SUBSET %then %do;
proc means data=&returns n noprint;
	output out=&stat_n n=;
run;
%end;


%if %upcase (&option)= RISK %then %do;
data &returns(drop=&i);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=ret[&i]**2;
	end;
run;

proc means data=&returns sum noprint;
	output out=&stat_sum sum=;
run;

data &outData(keep=_stat_ &vars);
	set &stat_sum &stat_n;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=sqrt(lag(ret[&i])/ret[&i]);
	end;
run;
%end;

%else %if %upcase(&option)= VARIANCE %then %do;
data &returns(drop=&i);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=ret[&i]**2;
	end;
run;

proc means data=&returns sum noprint;
	output out=&stat_sum sum=;
run;

data &outData(keep=_stat_ &vars);
	set &stat_sum &stat_n;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=lag(ret[&i])/ret[&i];
	end;
run;

%end;

%else %if %upcase(&option)= POTENTIAL %then %do;
proc means data=&returns sum noprint;
	output out=&stat_sum sum=;
run;

data &outData(keep=_stat_ &vars);
	set &stat_sum &stat_n;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=lag(ret[&i])/ret[&i];
	end;
run;
%end;


data &outData;
	format _STAT_ $32.;
	set &outData end=last;
	_STAT_= upcase("Upside &option");
	if last;
run;

proc datasets lib= work nolist;
delete &stat_sum &stat_n;
run;
quit;
							
%mend;
