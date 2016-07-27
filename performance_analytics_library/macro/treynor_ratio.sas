/*---------------------------------------------------------------
* NAME: Treynor_Ratio.sas
*
* PURPOSE: The Treynor ratio is similar to the Sharpe Ratio, except it uses beta as the volatility measure 
*          (to divide the investment's annualized excess return over the beta).
*
* NOTES: Calculates the Treynor ratio of a desired asset given returns, the benchmark and a risk free rate. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in a return data set. Number of periods
*        in a year (scale) and way of compounding (method) are inputs in calculating annualized returns. To calculate
*        the modified Treynor ratio, we replace the denominator by systematic risk. 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0.
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* modified - Optional. Specifies either regular or modified Treynor Ratio {FALSE, TRUE}.  
           Default=FALSE.
* dateColumn - Optional. Date column in Data Set. Default=DATE.
* outData - Optional. Output Data Set with Treynor ratios.  Default="TreynorRatio".
*
*
* Current version of Treynor Ratio only incorporates the use of Standard Deviation.  Later modifications may
* include VaR or ES, and an option for weights.

* MODIFIED:
* 5/18/2016 - QY - Initial Creation
* 5/23/2016 - QY - Add VARDEF parameter
* 
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Treynor_Ratio(returns,
							BM = ,
							Rf= 0,
							scale = 1,
							method = DISCRETE,
							VARDEF = DF, 
							modified = FALSE,
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
%return_annualized(&_tempRP,scale= &scale, method= &method, dateColumn= &dateColumn, outData= &_tempRP);

%if %upcase(&modified) = FALSE %then %do;
	%CAPM_alpha_beta(&returns, BM=&BM, Rf= &Rf, dateColumn= &dateColumn, outData= &_tempBeta)

	data &_tempBeta;
	set &_tempBeta;
	where _stat_='Betas';
	run;
%end;
%else %do;
	%Systematic_Risk(&returns,BM= &BM, Rf= &Rf, scale= &scale, VARDEF= &VARDEF, dateColumn= DATE, outData= &_tempBeta)
%end;

data &_tempTreynor (drop= &i _stat_ &BM &dateColumn);
set &_tempRP &_tempBeta;

array Treynor[*] &vars;

do &i= 1 to dim(Treynor);
Treynor[&i]= lag(Treynor[&i])/Treynor[&i];
end;
run;

data &outData;
format _STAT_ $32.;
set &_tempTreynor end= last;
_STAT_= 'Treynor Ratio';
if last; 
run;


proc datasets lib=work nolist;
	delete &_tempRP &_tempBeta &_tempTreynor;
run;
quit;

%mend;
