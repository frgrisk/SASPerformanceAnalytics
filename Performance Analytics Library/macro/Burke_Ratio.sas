/*---------------------------------------------------------------
* NAME: Burke_Ratio.sas
*
* PURPOSE: Burke ratio of the return distribution
*
* NOTES: To calculate Burke ratio we take the difference between the portfolio
*        return and the risk free rate and we divide it by the square root of the
*        sum of the square of the drawdowns. To calculate the modified Burke ratio
*        we just multiply the Burke ratio by the square root of the number of datas.

*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. the value or variable representing the risk free rate of return.    Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.    
*         Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* modified - Optional. 
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Burke Ratios.  Default="BurkeRatio".
*
* MODIFIED:
* 5/27/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Burke_Ratio(returns,
							Rf= 0,
							scale= 1,
							method= DISCRETE,
							modified= FALSE,
							dateColumn= DATE,
							outData= BurkeRatio);
							
%local vars i j nvar annualized drawdown divisor;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Burke_Ratio: (&vars);

%let annualized= %ranname();
%let drawdown= %ranname();
%let divisor= %ranname();
%let i=%ranname();
%let j=%ranname();
%let nvar = %sysfunc(countw(&vars));


%return_annualized(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &annualized)
%return_excess(&annualized, Rf=&Rf, dateColumn= &dateColumn, outData= &annualized);


data &drawdown(drop=&i);
	set &returns;
	array ret[*] &vars;
	array cumul[&nvar] _temporary_;
	array down[&nvar];

	do &i=1 to dim(ret);
		if ret[&i]=. then do;
			ret[&i]=0;
			cumul[&i]=0;
		end;

		if cumul[&i]<0 and ret[&i]>=0 then
			down[&i] = 1;

		if ret[&i]<0 then
			%if %upcase(&method) = DISCRETE %then %do;
			cumul[&i]=(1+cumul[&i])*(1+ret[&i])-1;
			%end;

			%else %if %upcase(&method) = LOG %then %do;
				cumul[&i]=sum(cumul[&i],ret[&i]);
			%end;

		else
			cumul[&i]=0;

		ret[&i]=cumul[&i];
	end;
run;

proc expand data=&drawdown out=&drawdown method=none; 
	%do &j=1 %to &nvar;
		convert down&&&j / transformout=(lead 1); 
	%end;
run;

data &drawdown(keep=&vars);
	set &drawdown end=last;
	array ret[*] &vars;
	array down[&nvar];
	do &i=1 to &nvar;
		if last and ret[&i]<0 then
			down[&i]=1;
		if down[&i]^=1 then
			ret[&i]=.;
	end;
run;

data &drawdown(drop=&i);
	set &drawdown;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]= ret[&i]**2;
	end;
run;

proc means data= &drawdown sum noprint;
output out= &divisor sum=;
run;

data &divisor(drop=&i);
	set &divisor;
	drop _freq_  _type_;
	array ret[*] &vars;
		do &i=1 to dim(ret);
			ret[&i]=sqrt(ret[&i]);
		end;
run;


data &outData (drop=&i);
	set &annualized &divisor;

	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= lag(ret[&i])/ret[&i];
		%if %upcase(&modified)=TRUE %then %do;
			ret[&i]=sqrt(&scale)*ret[&i];
		%end;
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Burke Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &annualized &drawdown &divisor;;
run;
quit;

%mend;
