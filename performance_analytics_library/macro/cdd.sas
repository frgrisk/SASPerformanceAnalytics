/*---------------------------------------------------------------
* NAME: CDD.sas
*
* PURPOSE: Calculate the conditional drawdown-at-risk (similar to conditional value-at-risk).
*		   It is the arthimatic mean of the worst (1-p)% drawdowns.
*
* NOTES: The weight option needs to be added in the future for portfolio calculation.
*		 R code calculates only the pth percentile, it's not consistent with the R documentation.
*		 This macro follows the definition of CDaR.
*		 See reference "Portfolio Optimization With Drawdown Constraints".
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* invert - Optional. Option to invert CDaR. {TRUE, FALSE} Default=TRUE
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* option - Optional. Choose the method to calculate CDaR. {SIMPLE, MEAN, WEIGHT}. Default=SIMPLE.
* pctldef - Optional. Choose the method to calculate p% percentile. (See SAS reference about 
*			calculating percentiles). Default=1
* dateColumn - Optional. Date column in Data Set. Default=DATE
* p - Optional. Confidence level. Default=0.95
* outData - Optional. Output Data Set with drawdowns.  Default="CDD".
*
* MODIFIED:
* 7/18/2016 – RM - Initial Creation
* 7/20/2016 - RM - Modified calculation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro CDD(returns,
							invert=TRUE,
							p=0.95,
							method= DISCRETE,
							option=SIMPLE,
							pctldef=1,
							dateColumn= DATE,
							outData= CDD);

%local vars nvars ret_drawdown _pctl ddp _sump _sum _n _wn _meanp i ii;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN CDD: (&vars);

%let nvars = %sysfunc(countw(&vars));
%let i=%ranname();
%let ii=%ranname();
%let _pctl= %ranname();
%let ret_drawdown= %ranname();
%let ddp= %ranname();
%let _sump= %ranname();
%let _sum= %ranname();
%let _n= %ranname();
%let _wn= %ranname();
%let _meanp= %ranname();

%Drawdowns(&returns, method= &method, dateColumn= DATE, outData=&ret_drawdown)

/*get p% percentile*/
proc univariate data=&ret_drawdown noprint pctldef=&pctldef;
	var &vars;
	output out=&_pctl pctlpts=%sysevalf((1-&p)*100)
	pctlpre=&vars
	pctlname=p;
run;

proc sql noprint;
	create table &ddp as
		select *
		from &ret_drawdown, &_pctl;
quit;

data &ddp;
	set &ddp;
	array vars[*] &vars;
	array varsp[*]
	%do &ii=1 %to &nvars;
		%sysfunc(scan(&vars, &&&ii))p
	%end;
	;
	do &i=1 to &nvars;
		if vars[&i]>varsp[&i] then vars[&i]=.;
		%if %upcase(&option=MEAN) %then %do;
			vars[&i]=vars[&i]-varsp[&i];
		%end;
	end;
	drop &i;
run;

/*if option=SIMPLE, outData is created here*/
proc means data=&ddp mean sum noprint;
	output out=&outData(keep=&vars) mean=;
	output out=&_sum(keep=&vars) sum=;
	output out=&_wn(keep=&vars) n=;
run;


/*if option=MEAN*/
%if %upcase(&option)=MEAN %then %do;
proc sql noprint;
	create table &_sump as
		select *
		from &_sum, &_pctl;
	select count(*) into: &_n
		from &ret_drawdown;
quit;

data &outData;
	set &_sump ;
	array vars[*] &vars;
	array varsp[*]
	%do &ii=1 %to &nvars;
		%sysfunc(scan(&vars, &&&ii))p
	%end;
	;

	do &i=1 to &nvars;
		vars[&i]=varsp[&i]+vars[&i]/((1-&p)*&&&_n);
	end;
	keep &vars;
run;
%end;

/*if option=WEIGHT*/
%if %upcase(&option)=WEIGHT %then %do;
proc sql noprint;
	create table &_meanp as
		select *
		from &outData, &_pctl;
	select count(*) into: &_n
		from &ret_drawdown;
quit;

data &outData;
	set &_wn &_meanp end=last;
	array vars[*] &vars;
	array varsp[*]
	%do &ii=1 %to &nvars;
		%sysfunc(scan(&vars, &&&ii))p
	%end;
	;

	do &i=1 to &nvars;
		if _n_=1 then do;
/*			vars[&i]=((&&&_n-vars[&i])/&&&_n-&p)/(1-&p); This is the same as "MEAN" method*/
			vars[&i]=((&&&_n-vars[&i])/&&&_n-&p)/&p;
		end;
		vars[&i]=lag(vars[&i])*varsp[&i]+(1-lag(vars[&i]))*vars[&i];
	end;

	if last then output;
	keep &vars;
run;

%end;

data &outData;
	format _STAT_ $32.;
	set &outData;
	array vars[*] &vars;

	%if %upcase(&invert)=TRUE %then %do;
		do &i=1 to &nvars;
			vars[&i]=-vars[&i];
		end;
	%end;
	_STAT_ = "Condition_Drawdown_at_Risk";
	drop &i;
run;

proc datasets lib = work nolist;
	delete &ret_drawdown &_pctl &ddp &_sum &_sump &_wn &_meanp;
run;
quit;

%mend;





