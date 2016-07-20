/*---------------------------------------------------------------
* NAME: SharpeRatio_annualized.sas
*
* PURPOSE: displays an annualized sharpe ratio with option for DISCRETE or LOG chaining.
*
* NOTES: The Sharpe ratio of a desired asset is calculated given returns, a risk free rate, and scale. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=0
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=date
* outData - Optional. Output Data Set with annualized Sharpe Ratio.  Default="Annualized_SharpeRatio".
*
* MODIFIED:
* 6/12/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro SharpeRatio_annualized(returns, 
					  				 Rf= 0, 
					 				 scale= 1,
					  				 method= DISCRETE, 
									 VARDEF = DF,
					  				 dateColumn= DATE, 
					  				 outData= Annualized_SharpeRatio);

%local ret nv j Chained_Ex_Ret Ann_StD;
/*Find all variable names excluding the date column and risk free variable*/
%let ret= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put RET IN SharpeRatio_annualized: (&ret);
/*Find number of columns in the data set*/
%let nv = %sysfunc(countw(&ret));
/*Define counters for array operations*/
%let j= %ranname();
/*Define temporary data set names with random names*/
%let Chained_Ex_Ret= %ranname();
%let Ann_StD= %ranname();

%return_excess(&returns, Rf= &Rf, dateColumn= &dateColumn, outData= &Chained_Ex_Ret);
%return_annualized(&Chained_Ex_Ret, scale= &scale, method= &method, dateColumn=&dateColumn, outData= &Chained_Ex_Ret);

%Standard_Deviation(&returns, 
							annualized= TRUE, 
							scale= &scale,
							VARDEF = &VARDEF, 
							dateColumn= &dateColumn,
							outData= &Ann_StD);

data &outData (drop= &j);
	format _STAT_ $32.;
	set &Chained_Ex_Ret &Ann_StD (in=s);
	_STAT_= 'Sharpe Ratio';
	array minRf[&nv] &ret;

	do &j=1 to &nv;
		minRf[&j] = lag(minRf[&j])/minRf[&j];
	end;
	if s;
run;


proc datasets lib=work nolist;
delete &Ann_StD &Chained_Ex_Ret;
run;
quit;
%mend;
