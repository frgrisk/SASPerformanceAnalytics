/*---------------------------------------------------------------
* NAME: Average_Drawdown.sas
*
* PURPOSE: Calculates the average depth of the observed drawdowns.
*
* NOTES: 
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with average drawdowns.  Default="Avg_DD".
*
* MODIFIED:
* 6/02/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Average_Drawdown(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= Avg_DD);
							
%local vars drawdown stat_sum stat_n i j;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN Average_Drawdown: (&vars);

%let drawdown= %ranname();
%let stat_sum= %ranname();
%let stat_n= %ranname();

%let i = %ranname();
%let nvar = %sysfunc(countw(&vars));


%Drawdowns(&returns, method=&method, dateColumn=&dateColumn, outData=&drawdown);


data &drawdown(drop=&i);
	set &drawdown;
	array ret[*] &vars;
	array worst[&nvar] _temporary_;

	do &i=1 to dim(ret);
		if ret[&i]=0 then
			worst[&i]=0;
		else if ret[&i]<worst[&i] then 
			worst[&i]=ret[&i];
		ret[&i]=worst[&i];
	end;
run;

data &drawdown(drop=&i);
	set &drawdown;
	array ret[*] &vars;
	array last[&nvar] _temporary_;
	array flag[&nvar];
	
	do &i=1 to dim(ret);
	if _n_= 1 then
		last[&i] = ret[&i];
	if sign(ret[&i])^=sign(last[&i]) and ret[&i]=0 then
		flag[&i]=1;
	last[&i]=ret[&i];
	end;
run;

proc expand data=&drawdown out=&drawdown method=none; 
	%do j=1 %to &nvar;
		convert flag&j / transformout=(lead 1); 
	%end;
run;

data &drawdown(keep=&vars);
	set &drawdown end=last;
	array ret[*] &vars;
	array flag[&nvar];
	do &i=1 to &nvar;
		if last and ret[&i]<0 then
			flag[&i]=1;
		if flag[&i]^=1 then
			ret[&i]=.;
	end;
run;


proc means data= &drawdown sum n noprint;
	output out= &stat_sum sum=;
	output out= &stat_n n=;
run;

data &outData (drop= &i _type_ _freq_);
	set &stat_sum &stat_n;

	array dd[*] &vars;

	do &i= 1 to dim(dd);
		dd[&i]= lag(dd[&i])/dd[&i];
	end;

	do &i= 1 to dim(dd);
		dd[&i]= abs(dd[&i]);
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Average Drawdown';
	if last; 
run;


proc datasets lib=work nolist;
	delete &drawdown &stat_sum &stat_n;
run;
quit;

%mend;
