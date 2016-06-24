/*---------------------------------------------------------------
* NAME: LPM.sas
*
* PURPOSE: Calculate lower partial moments for a time series
*
* NOTES: LPM is a family of risk measures specified by n-th degree and a reference point. 
*        The reference point may be the mean or some specified threshold. By choosing the
*        degree of moment, an investor can specify the measure to suit his risk aversion.
*        Intuitively, large values of n will penalize large deviations more than low values.
*        Semi-variance is a special case of LPM for which the degree of the moment is set to 2.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* n - Optional. The n-th moment to return. It can be used as an indicator of risk preference. 
				Risk averse behavior is signified by n>1, whereas risk seeking behavior is indicated
				by n<1. Default=2.
* group - Optional. Specifies to choose full observations or subset observations as 'n' in the divisor. {FULL, SUBSET}
*		  Default=FULL
* threshold - Optional. A reference point to be compared. The reference point may be the mean or some
              specified threshold. Default=0.
* about_mean - Optional. Specify whether to calculate LPM about the mean under the threshold, the mean of all 
               observations, or threshold. {UNDER, ALL, NULL}. Default=NULL. 
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with lower partial moments.  Default="lpm".
*
* MODIFIED:
* 6/21/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro LPM(returns,
				  n= 2,
				  group= FULL,
				  threshold= 0,
				  about_mean= NULL,
				  dateColumn= DATE,
			      outData= lpm);
							
%local vars nvars temp stat_mean stat_n stat_sum i j;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN LPM: (&vars);

%let temp= %ranname();
%let stat_mean= %ranname();
%let stat_n= %ranname();
%let stat_sum= %ranname();

%let i = %ranname();
%let nvars = %sysfunc(countw(&vars));


proc means data=&returns mean n noprint;
%if %upcase(&about_mean)=ALL %then %do;
	output out=&stat_mean(keep=&vars) mean=;
%end;
	output out=&stat_n(keep=&vars) n=;
run;

%if %upcase(&about_mean)=NULL %then %do;
	data &temp(keep=&vars);
		set &returns(firstobs=2);
		array ret[*] &vars;
		do &i=1 to &nvars;
			if ret[&i]>=&threshold then ret[&i]=.; 
			else ret[&i]=&threshold-ret[&i];
		end;
	run;
%end;

%else %if %upcase(&about_mean)=ALL %then %do;
	data &temp(keep=&vars);
		set &stat_mean &returns(firstobs=2);
		array ret[*] &vars;
		array R_avg[&nvars] _temporary_;
		do &i=1 to &nvars;
			if _n_=1 then R_avg[&i]=ret[&i];
			else do;
				if ret[&i]>=R_avg[&i] then ret[&i]=.; 
				else ret[&i]=R_avg[&i]-ret[&i];
			end;
		end;
	run;

	data &temp;
		set &temp(firstobs=2);
	run;
%end;

%else %if %upcase(&about_mean)=UNDER %then %do;
	data &temp(keep=&vars);
		set &returns(firstobs=2);
		array ret[*] &vars;
		do &i=1 to &nvars;
			if ret[&i]>=&threshold then ret[&i]=.; 
		end;
	run;

	proc means data=&temp mean noprint;
		output out=&stat_mean(keep=&vars) mean=;
	run;

	data &temp(keep=&vars);
		set &stat_mean &temp;
		array ret[*] &vars;
		array R_avg[&nvars] _temporary_;
		do &i=1 to &nvars;
			if _n_=1 then R_avg[&i]=ret[&i];
			else do;
				if ret[&i] ^=. and ret[&i]<R_avg[&i] then 
					ret[&i]=R_avg[&i]-ret[&i];
				else if ret[&i] ^=. and ret[&i]>=R_avg[&i] then
					ret[&i]=0;
			end;
		end;
	run;

	data &temp;
		set &temp(firstobs=2);
	run;
%end;
	

data &temp(keep=&vars);
	set &temp;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]=ret[&i]**&n;
	end;
run;

%if %upcase(&group)=SUBSET %then %do;
	proc means data=&temp mean noprint;
		output out=&outData(keep=&vars) mean=;
	run;
%end;
%else %do;
	proc means data=&temp sum noprint;
		output out=&stat_sum(keep=&vars) sum=;
	run;

	data &outData(keep=&vars);
		set &stat_sum &stat_n;
		array ret[*] &vars;

		do &i= 1 to dim(ret);
			ret[&i]=lag(ret[&i])/ret[&i];
		end;
	run;
%end;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Lower Partial Moment';
	if last; 
run;

proc datasets lib=work nolist;
	delete &temp &stat_mean &stat_n &stat_sum;
run;
quit;

%mend;
