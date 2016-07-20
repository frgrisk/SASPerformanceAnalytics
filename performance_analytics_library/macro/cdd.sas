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
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* p - Optional. Confidence level. Default=0.95
* outData - Optional. Output Data Set with drawdowns.  Default="CDD".
*
* MODIFIED:
* 7/18/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro CDD(returns,
							invert=TRUE,
							p=0.95,
							method= DISCRETE,
							dateColumn= DATE,
							outData= CDD);

%local vars nvars ret_drawdown ret_drawdown2 i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN CDD: (&vars);

%let nvars = %sysfunc(countw(&vars));
%let i=%ranname();
%let ii=%ranname();
%let ret_drawdown= %ranname();
%let ret_drawdown2= %ranname();

%Drawdowns(&returns, method= &method, dateColumn= DATE, outData=&ret_drawdown)

/*Find CDD for each asset*/
%do &ii=1 %to &nvars;

	%let asset=%sysfunc(scan(&vars, &&&ii));
	data &ret_drawdown &ret_drawdown2;
		set &ret_drawdown(firstobs=2) end=eof;
	
		retain prior_sign sofar 1 index 1;
					
		if _n_ = 1 then do;
			prior_sign = sign(&asset);
			sofar = &asset;
		end;

		current_sign=sign(&asset);

		if current_sign = prior_sign then do;
			if &asset < sofar then do;
				sofar = &asset;
			end;
		end;
		else do;
			return = sofar;

			sofar = &asset;
			index = index+1;
			prior_sign = current_sign;
		end;
	
		if eof then do;
			output &ret_drawdown2;
		end;

		output &ret_drawdown;
	run;

	data &ret_drawdown2;
		set &ret_drawdown2;
		return = sofar;

		keep return;
	run;

	data &asset;
		set &ret_drawdown;

		retain lag_index 0;
		if lag_index ne index then do;
			output;
		end;
		lag_index = index;
		keep return;
	run;

	data &asset;
		set &asset &ret_drawdown2;
	run;

	data &asset;
		set &asset;
		if return ne . then do;
			output;
		end;
	run;
	proc sort data=&asset out=&asset;
		by return;
	run;

	proc univariate data=&asset noprint;
		var return;
		output out=q&asset pctlpts=%sysevalf((1-&p)*100)
		pctlpre=&asset
		pctlname=q ;
	run;
	proc sql noprint;
	create table b&asset as
	select a.*, b.*
	from &asset as a, q&asset as b;
	quit;

	data b&asset;
		set b&asset;
		if return>=&asset.q then return=. ;
	run;
	
	proc means data=b&asset mean noprint;
		var return;
		output out=&asset(keep=return) mean=;
	run;

	proc datasets lib = work nolist;
		delete b&asset q&asset;
	run;
	quit;
%end;

proc sql noprint;
	create table &outData as
	select *
	from
		%sysfunc(scan(&vars, %eval(1)))(rename=(return=%sysfunc(scan(&vars, %eval(1)))))
		%do &ii=2 %to &nvars;
			,%sysfunc(scan(&vars, &&&ii))(rename=(return=%sysfunc(scan(&vars, &&&ii))))
		%end;
	;
quit;

data &outData;
	format _STAT_ $32.;
	set &outData;
	array vars[*] &vars;
	if %upcase(&invert)=TRUE then do;
		do &i=1 to &nvars;
			vars[&i]=-vars[&i];
		end;
	end;
	_STAT_="CDD";
	keep _STAT_ &vars;
run;

proc datasets lib = work nolist;
	delete &ret_drawdown &ret_drawdown2 &vars;
run;
quit;

%mend;





