/*---------------------------------------------------------------
* NAME: Average_Recovery.sas
*
* PURPOSE: Find the average recovery of drawdowns
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with average recovery.  Default="AverageRecovery".
*
* MODIFIED:
* 6/03/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Average_Recovery(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= AverageRecovery);

%local vars i nvar DD DD2 DDrow stat_DD2;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Average_Length: (&vars);

%let nvar = %sysfunc(countw(&vars));

%let DD= %ranname();
%let DD2= %ranname();
%let stat_DD2= %ranname();
%let DDrow= %ranname();
%let i= %ranname();

%Drawdowns(&returns, method= &method, dateColumn= DATE, outData=&DD)

data &DD &&DDrow;
	set &DD(firstobs=2) end=eof;
	array ret[*] &vars;
	array prior_sign[&nvar] _temporary_ (&nvar*1);
	array current_sign[&nvar] _temporary_;
	array sofar[&nvar] _temporary_;
	array dmin[&nvar] (&nvar*1);
	array trough[&nvar] (&nvar*1);
	array to[&nvar] (&nvar*1);
	array end[&nvar] (&nvar*1);
	array recovery[&nvar] (&nvar*0);
	array sign_flag[&nvar];

	do &i=1 to &nvar;

		if _n_ = 1 then do;
			prior_sign[&i] = sign(ret[&i]);
			sofar[&i] = ret[&i];
		end;
		current_sign[&i] = sign(ret[&i]);

		if current_sign[&i] = prior_sign[&i] then do;
			if ret[&i] < sofar[&i] then do;
				sofar[&i] = ret[&i];
				dmin[&i] = _n_;
			end;
			to[&i] = _n_+1;
		end;

		else do;
			trough[&i] = dmin[&i];
			end[&i] = to[&i];
			sofar[&i] = ret[&i];
			to[&i] = _n_+1;
			dmin[&i] = _n_;
			prior_sign[&i] = current_sign[&i];
		end;
		if ret[&i]<0 then sign_flag[&i] = 0;
		if ret[&i]=0 then sign_flag[&i] = 1;
		if eof then output &DDrow;
		recovery[&i] = end[&i] - trough[&i];
	end;
	drop &i;
	output &DD;
run;

data &DDrow;
	set &DDrow end=eof;
	array trough[&nvar];
	array end[&nvar];
	array to[&nvar];
	array dmin[&nvar];
	array recovery[&nvar];
	do &i=1 to &nvar;
		trough[&i] = dmin[&i];
		end[&i] = to[&i];
		recovery[&i] = end[&i] - trough[&i];
	end;
	if eof then output;
	drop &i;
run;

data &DD2;
	set &DD &DDrow;
run;

data &DD2;
	set &DD2 end=eof;
	array recovery[&nvar];
	array sign_flag[&nvar];

	do &i=1 to &nvar;
		if not eof then do;
			if sign_flag[&i] = 0 then recovery[&i] = .;
			if sign_flag[&i] = 1 and LAG(sign_flag[&i]) ^= 0
				then recovery[&i] = .;
		end;
		if eof and sign_flag[&i] = 1 then recovery[&i] = .;
	end;
	keep recovery1-recovery&nvar;
run;



proc means data= &DD2 noprint;
	output out= &stat_DD2 ;
run;

data &outData;
	format _STAT_ $32.;
	set &stat_DD2;
	where _stat_='MEAN';
	rename
		%do &i=1 %to &nvar;
			recovery&&&i=%sysfunc(scan(&vars, &&&i))
		%end;
	;
	_STAT_ = 'AverageRecovery';
	drop _type_ _freq_;
run;

/*proc datasets lib=work nolist;*/
/*	delete &DD &DD2 &stat_DD2 $DDrow;*/
/*run;*/
/*quit;*/
%mend;
