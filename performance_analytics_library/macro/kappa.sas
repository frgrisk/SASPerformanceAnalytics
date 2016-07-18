/*---------------------------------------------------------------
* NAME: Kappa.sas
*
* PURPOSE: Calculate Kappa which is a measure of downside risk-adjusted .
*
* NOTES: Different from R function 'Kappa', this macro gives user the choice of choosing to use 
*		 the number of whole observations or the number of subset observations where the returns 
* 		 are smaller than MAR.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. Default=0
* L - Optional. The exponential coefficient of Kappa. Default=1
* group - Optional. Specifies to choose full observations or subset observations as 'n' in the divisor. {FULL, SUBSET}
*		  Default=FULL
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Kappa.  Default="Kappa".
*
*
* MODIFIED:
* 6/7/2015 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro kappa(returns,
							MAR= 0,
							L= 1, 
							group= FULL,
							dateColumn= DATE,
							outData= kappa);

%local vars nvars temp_excess _LPM _means nrows Rf ii i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &MAR);
%put VARS IN Kappa: (&vars);

%let temp_excess=%ranname();
%let _means=%ranname();
%let nvars = %sysfunc(countw(&vars));
%let i=%ranname();
%let _LPM=%ranname();

%return_excess(&returns,Rf= &MAR, dateColumn= &dateColumn,outData= &temp_excess);
%LPM(&returns, n=&L, group=&group, MAR=&MAR, about_mean=NULL, dateColumn=&dateColumn, outData=&_LPM);


proc means data=&temp_excess mean noprint;
	output out=&_means(keep=&vars) mean=; 
run;

data &outData;
	set &_LPM(drop=_stat_) &_means;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=vars[&i]/lag(vars[&i])**(1/&L);
	end;
	if _n_=2 then output;
	drop &i;
run;

data &outData;
	format _STAT_ $32.;
	set &outData;
	_STAT_="Kappa";
run;

proc datasets lib = work nolist;
	delete &temp_excess &_means &_LPM;
run;
quit;
%mend;





