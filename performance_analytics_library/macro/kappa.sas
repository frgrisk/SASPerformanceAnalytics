/*---------------------------------------------------------------
* NAME: kappa.sas
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

%local vars nvars temp_excess means sum nrows Rf ii i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put VARS IN Kappa: (&vars);

%let temp_excess=%ranname();
%let means=%ranname();
%let sum=%ranname();
%let nvars = %sysfunc(countw(&vars));
%let ii=%ranname();

%return_excess(&returns,Rf= &MAR, dateColumn= &dateColumn,outData= &temp_excess);

data &temp_excess;
	set &temp_excess(firstobs=2);
run; 

%do i=1 %to &nvars;
	%local nrows&i;
	proc sql noprint;
		select count(%sysfunc(scan(&vars, &i)))
		into   :nrows&i
		from   &temp_excess
		%if %upcase(&group)=SUBSET %then %do;
			where %sysfunc(scan(&vars, &i))<0;
		%end;
	quit;
%end;

proc means data=&returns noprint;
	output out=&means;
run;

data &means;
	set &means;
	where _stat_ = 'MEAN';
	drop _type_ _freq_ &dateColumn;
run;

data &temp_excess;
	set &temp_excess;
	array vars[*] &vars;
	array power[&nvars];

	do &ii=1 to &nvars;
		power[&ii] = max(-vars[&ii],0) ** &L;
	end;
	keep power1-power&nvars;
run;

proc means data=&temp_excess noprint;
	output out=&sum sum=;
run;

data &outData;
	format _stat_ $32.;
	set &sum &means;
	array vars[*] &vars;
	array kappa[&nvars] (&nvars*0);
	array power[&nvars];

	%do i=1 %to &nvars;
		kappa[&i] = (vars[&i] - &MAR)/ ((LAG(power[&i])/&&nrows&i) ** (1/&L));
	%end;
	rename
		%do i=1 %to &nvars;
			kappa&i=%sysfunc(scan(&vars, &i))
		%end;
	;
	_stat_ = "Kappa";
	keep _stat_ kappa1-kappa&nvars;
	if _n_=2 then output;
run;

proc datasets lib = work nolist;
	delete &temp_excess &means &sum;
run;
quit;
%mend;





