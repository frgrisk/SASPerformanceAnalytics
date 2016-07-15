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
* returns - Required.  Data Set containing returns.
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
							
%local vars drawdown stat_mean i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Ulcer_Index: (&vars);

%let drawdown= %ranname();
%let stat_mean= %ranname();
%let i = %ranname();

%Drawdowns(&returns, method= &method, dateColumn= &dateColumn, outData= &drawdown)

data &drawdown(drop=&i);
	set &drawdown(firstobs=2);
	array ret[*] &vars;

	do &i= 1 to dim(ret);
	ret[&i]= ret[&i]**2;
	end;
run;

proc means data= &drawdown mean noprint;
	output out= &stat_mean mean=;
run;

data &outData(keep=_stat_ &vars);
format _STAT_ $32.;
	set &stat_mean;
	array ret[*] &vars;
		do &i=1 to dim(ret);
			ret[&i]=sqrt(ret[&i]);
		end;
	_STAT_= 'Ulcer Index';
run;

proc datasets lib=work nolist;
	delete &drawdown &stat_mean;
run;
quit;

%mend;
