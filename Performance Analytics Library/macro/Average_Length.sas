/*---------------------------------------------------------------
* NAME: Average_Length.sas
*
* PURPOSE: Find the average length of drawdowns
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with drawdowns.  Default="AverageLength".
*
* MODIFIED:
* 6/03/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Average_Length(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= AverageLength);

%local vars i nvar DD DD2 stat_DD2;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Average_Length: (&vars);

%let nvar = %sysfunc(countw(&vars));

%let DD= %ranname();
%let DD2= %ranname();
%let stat_DD2= %ranname();
%let i= %ranname();

%Drawdowns(&returns, method= &method, dateColumn= DATE, outData=&DD)

data &DD;
	set &DD(firstobs=2);
	array ret[*] &vars;
	
	array length[&nvar] (&nvar*1);
	array sign_flag[&nvar];

	do &i = 1 to &nvar;
		if ret[&i]<0 then do;
			length[&i] = length[&i]+1;
			sign_flag[&i] = 0;
		end;
		if ret[&i]=0 then do;
			length[&i] = 1;
			sign_flag[&i] = 1;
		end;
	end;
	drop &i;
run;

data &DD2;
	set &DD;
	array sign_flag[&nvar];
	array length[&nvar];
    array laglength[&nvar] _temporary_;
	do &i=1 to &nvar;
		laglength[&i]=LAG(length[&i]);

		if sign_flag[&i] = 1 and lag(sign_flag[&i]) = 0 then do;
			length[&i] = laglength[&i];
		end;
	end;
	drop &vars &i;
run;

data &DD2;
	set &DD2 end=eof;
	array length[&nvar];
	array sign_flag[&nvar];

    do &i=1 to &nvar;
		if not eof then do;
			if sign_flag[&i] = 0 then length[&i] = .;
			if length[&i] = 1 then length[&i] = .;
		end;

		if eof and sign_flag[&i] = 1 then length[&i] = .;
	end;
	keep length1-length&nvar ;
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
			length&&&i=%sysfunc(scan(&vars, &&&i))
		%end;
	;
	_STAT_ = 'AverageLength';
	drop _type_ _freq_;
run;

proc datasets lib=work nolist;
	delete &DD &DD2 &stat_DD2;
run;
quit;
%mend;
