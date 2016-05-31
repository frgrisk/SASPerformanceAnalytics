/*---------------------------------------------------------------
* NAME: Drawdown_Peak.sas
*
* PURPOSE: Calculate the drawdowns since the previous peak
*
* NOTES: 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with drawdowns since previous peak.  Default="drawdownPeak".
*
* MODIFIED:
* 5/31/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Drawdown_Peak(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= drawdownPeak);
							
%local vars nvar cumul_ret peak merged i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Drawdowns: (&vars);

%let nvar = %sysfunc(countw(&vars));

%let cumul_ret= %ranname();
%let peak= %ranname();
%let merged= %ranname();

%let i = %ranname();


%return_cumulative(&returns, method= &method, outData=&cumul_ret)

data &cumul_ret(drop=&i);
	set &cumul_ret;

	array var[*] &vars;

	do &i= 1 to dim(var);
	var[&i]=var[&i]+1;
	end;
run;

data &peak(drop=&i);
	set &cumul_ret;
	array ret[*] &vars;
	array peak[&nvar];
	retain peak;

	do &i=1 to dim(ret);
		if _n_=1 then 
			peak[&i]=ret[&i];
		if ret[&i]>peak[&i] then
			peak[&i]=ret[&i];
	end;
run;

data &peak(drop=&i);
	set &peak;
	array ret[*] &vars;
	array peak[&nvar];

	do &i=1 to dim(ret);
		if peak[&i]^=ret[&i] then
			peak[&i]=.;
		else 
			peak[&i]=1;
	end;
run;


data &merged;
	merge &returns &peak(drop=&vars);
	by &dateColumn;
run;


data &outData;
	set &merged;

	array ret[*] &vars;
	array peak[&nvar];
	array cumul[&nvar] _temporary_;

	do &i=1 to dim(ret);
		if ret[&i]=. then do;
			ret[&i]=0;
			cumul[&i]=0;
		end;

		if peak[&i]=1 then
			cumul[&i]=0;
		else
			%if %upcase(&method) = DISCRETE %then %do;
			cumul[&i]=(1+cumul[&i])*(1+ret[&i])-1;
			%end;

			%else %if %upcase(&method) = LOG %then %do;
				cumul[&i]=sum(cumul[&i],ret[&i]);
			%end;

		ret[&i]=cumul[&i];
	end;
	
	keep &vars;
run;
	

proc datasets lib=work nolist;
	delete &cumul_ret &peak &merged;
run;
quit;

%mend;
