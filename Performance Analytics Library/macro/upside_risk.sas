/*---------------------------------------------------------------
* NAME: upside_risk.sas
*
* PURPOSE: Calculate upside risk, upside variance, or upside potential which measure the 
*          variability of performance over a minimum target rate.
*
* NOTES: Option group specify divisor "n" as the number of full observations or the number of observations
*        which over-perform the minimum acceptable return(MAR). We use the positive value of difference between returns and MAC
*        as the measure of upside. Upside potential is the sum of the differences over n. Upside variance
*        is the sum of square of the differences over n. Upside risk the square root of upside variance. 
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. Default=0
* option- Required. {RISK, VARIANCE, POTENTIAL}.  Choose "RISK" to calculate the upside risk, 
*					 "VARIANCE" to calculate upside variance, or "POTENTIAL" to calculate upside potential.
* group - Optional. Specifies to choose full observations or subset observations as 'n' in the divisor. {FULL, SUBSET}
*		  Default=FULL
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

%local stat_sum stat_n temp vars i;
%let stat_sum= %ranname();
%let stat_n= %ranname();
%let temp= %ranname();

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &MAR);
%put VARS IN upside_risk: (&vars);

%let i= %ranname();

data &temp(drop=&i &dateColumn);
	set &returns(firstobs=2);
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=ret[&i]-&MAR;
	end;
run;

data &temp(drop=&i);
	set &temp;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]<=0 then ret[&i]=.; 
	end;
run;

%if %upcase (&group)= FULL %then %do;
	proc means data=&returns n noprint;
		output out=&stat_n n=;
	run;
%end;

%else %if %upcase(&group)= SUBSET %then %do;
	proc means data=&temp n noprint;
		output out=&stat_n n=;
	run;
%end;


%if %upcase (&option)= RISK %then %do;
	data &temp(drop=&i);
		set &temp;
		array ret[*] &vars;

		do &i= 1 to dim(ret);
			ret[&i]=ret[&i]**2;
		end;
	run;

	proc means data=&temp sum noprint;
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
	data &temp(drop=&i);
		set &temp;
		array ret[*] &vars;

		do &i= 1 to dim(ret);
			ret[&i]=ret[&i]**2;
		end;
	run;

	proc means data=&temp sum noprint;
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
	proc means data=&temp sum noprint;
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
delete &stat_sum &stat_n &temp
run;
quit;
							
%mend;
