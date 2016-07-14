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
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Sharpe ratios.  Default="SharpeRatio".
*
*
* Current version of Sharpe_Ratio only incorporates the use of Standard Deviation.  Later modifications may
* include VaR or ES, and an option for weights.
* MODIFIED:
* 6/3/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Sharpe_Ratio(returns,
							Rf= 0,
							VARDEF= DF, 
							dateColumn= DATE,
							outData= SharpeRatio);
							
%local vars _tempRP _tempStd i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put VARS IN Sharpe_Ratio: (&vars);

%let _tempRP= %ranname();
%let _tempStd= %ranname();

%let i= %ranname();

%return_excess(&returns,Rf= &Rf, dateColumn= &dateColumn,outData= &_tempRP);

proc means data= &_tempRP noprint;
	output out= &_tempRP(keep=&vars) mean=;
run;

%Standard_Deviation(&returns, VARDEF = &VARDEF, dateColumn= &dateColumn, outData= &_tempStd);

data &outData (keep= _stat_ &vars);
format _STAT_ $32.;
	set &_tempRP &_tempStd(in=b);

	array Sharpe[*] &vars;
	do &i= 1 to dim(Sharpe);
		Sharpe[&i]= lag(Sharpe[&i])/Sharpe[&i];
	end;

	_STAT_= 'Sharpe Ratio';
	if b;
run;

proc datasets lib=work nolist;
	delete &_tempRP &_tempStd;
run;
quit;

%mend;
