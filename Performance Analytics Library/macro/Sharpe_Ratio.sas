/*---------------------------------------------------------------
* NAME: Sharpe_Ratio.sas
*
* PURPOSE: The sharpe ratio is the return per unit of risk.  The unit of risk used in this macro is the
* 		   standard deviation of returns.
*
* NOTES: Calculates the Sharpe ratio of a desired asset given returns and a risk free rate.   Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in a return data set;
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outSharpe - Optional. Output Data Set with Sharpe ratios.  Default="SharpeRatio".
*
*
* Current version of Sharpe_Ratio only incorporates the use of Standard Deviation.  Later modifications may
* include VaR or ES, and an option for weights.
* MODIFIED:
* 6/3/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Sharpe_Ratio(returns,
							Rf= 0,
							dateColumn=DATE,
							outSharpe= SharpeRatio);
							
%local vars _tempRP _tempStd _tempSharpe i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put VARS IN Adjusted_SharpeRatio: (&vars);

%let _tempRP= %ranname();
%let _tempStd= %ranname();
%let _tempSharpe= %ranname();

%let i= %ranname();

%return_excess(&returns,Rf= &Rf, dateColumn= &dateColumn,outReturn= &_tempRP);

proc means data= &_tempRP noprint;
output out= &_tempRP;
run;

data &_tempRP;
set &_tempRP;
drop _freq_ _stat_ _type_ date;
where _stat_= 'MEAN';
run;


%Standard_Deviation(&returns,
							dateColumn= &dateColumn, 
							outStdDev= &_tempStd);

data &_tempSharpe (drop= &i);
set &_tempRP &_tempStd;

array Sharpe[*] &vars;

do &i= 1 to dim(Sharpe);
Sharpe[&i]= lag(Sharpe[&i])/Sharpe[&i];
end;
run;

data &outSharpe;
retain _STAT_;
set &_tempSharpe end= last;
_STAT_= 'Sharpe_Ratio';
if last; 
run;


proc datasets lib=work nolist;
	delete &_tempRP &_tempStd &_tempSharpe;
run;
quit;

%mend;
