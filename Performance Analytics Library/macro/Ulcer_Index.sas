/*---------------------------------------------------------------
* NAME: Ulcer_Index.sas
*
* PURPOSE: Calculate the Ulcer Index
*
* NOTES: This is similar to drawdown deviation except that the impact of the duration of 
*        drawdowns is incorporated by selecting the negative return for each period below 
*        the previous peak or high water mark.  The impact of long, deep drawdowns will 
*        have significant impact because the underperformance since the last peak is squared.
*        This approach is sensitive to the frequency of the time periods involved 
*        and penalizes managers that take time to recover to previous highs.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with ulcer index.  Default="UlcerIndex".
*
* MODIFIED:
* 5/31/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Ulcer_Index(returns,
							method= DISCRETE,
							dateColumn= DATE,
							outData= UlcerIndex);
							
%local vars drawdown stat_sum stat_n i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Ulcer_Index: (&vars);

%let drawdown= %ranname();
%let stat_sum= %ranname();
%let stat_n= %ranname();
%let i = %ranname();

%Drawdown_Peak(&returns, method= &method, dateColumn= &dateColumn, outData= &drawdown)

data &drawdown(drop=&i);
	set &drawdown(firstobs=2);
	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]= ret[&i]**2;
	end;
run;

proc means data= &drawdown sum n noprint;
	output out= &stat_sum sum=;
	output out= &stat_n n=;
run;

data &stat_sum(drop=&i);
	set &stat_sum;
	drop _freq_  _type_;
	array ret[*] &vars;
		do &i=1 to dim(ret);
			ret[&i]=sqrt(ret[&i]);
		end;
run;

data &stat_n(drop=&i);
	set &stat_n;
	drop _freq_  _type_;
	array ret[*] &vars;
		do &i=1 to dim(ret);
			ret[&i]=sqrt(ret[&i]);
		end;
run;


data &outData (drop= &i);
	set &stat_sum &stat_n;

	array Ulcer[*] &vars;

	do &i= 1 to dim(Ulcer);
		Ulcer[&i]= lag(Ulcer[&i])/Ulcer[&i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'Ulcer Index';
	if last; 
run;

proc datasets lib=work nolist;
	delete &drawdown &stat_sum &stat_n;
run;
quit;

%mend;
