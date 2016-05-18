/*---------------------------------------------------------------
* NAME: Treynor_Ratio.sas
*
* PURPOSE: 
*
* NOTES: 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Treynor ratios.  Default="TreynorRatio".
*
*
* Current version of Treynor Ratio only incorporates the use of Standard Deviation.  Later modifications may
* include VaR or ES, and an option for weights.

* MODIFIED:
* 
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Treynor_Ratio(returns,
							BM = ,
							Rf= 0,
							dateColumn= DATE,
							outData= TreynorRatio);
							
%local vars _tempRP _tempBeta _tempTreynor i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM);
%put VARS IN Treynor: (&vars);

%let _tempRP= %ranname();
%let _tempBeta= %ranname();
%let _tempTreynor= %ranname();

%let i= %ranname();

%return_excess(&returns,Rf= &Rf, dateColumn= &dateColumn,outData= &_tempRP);

proc means data= &_tempRP noprint;
output out= &_tempRP;
run;

data &_tempRP;
set &_tempRP;
drop _freq_ _stat_ _type_ date;
where _stat_= 'MEAN';
run;

%CAPM_alpha_beta(&returns, BM=&BM, Rf= &Rf, dateColumn= &dateColumn, outData= &_tempBeta);

data &_tempBeta;
set &_tempBeta;
where _stat_='betas';
run;


data &_tempTreynor (drop= &i _stat_ &BM);
set &_tempRP &_tempBeta;

array Treynor[*] &vars;

do &i= 1 to dim(Treynor);
Treynor[&i]= lag(Treynor[&i])/Treynor[&i];
end;
run;

data &outData;
retain _STAT_;
set &_tempTreynor end= last;
_STAT_= 'Treynor_Ratio';
if last; 
run;


proc datasets lib=work nolist;
	delete &_tempRP &_tempBeta &_tempTreynor;
run;
quit;

%mend;
