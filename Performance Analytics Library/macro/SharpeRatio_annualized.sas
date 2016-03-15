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
* dateColumn - Optional. Date column in Data Set. Default=date
* outData - Optional. Output Data Set with risk premium.  Default="Annualized_SharpeRatio".
*
* MODIFIED:
* 6/12/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro SharpeRatio_annualized(returns, 
					  				 Rf= 0, 
					 				 scale= 1,
					  				 method= DISCRETE, 
					  				 dateColumn= DATE, 
					  				 outData= Annualized_SharpeRatio);

%local ret nv j Chained_Ex_Ret Ann_StD SR;
/*Find all variable names excluding the date column and risk free variable*/
%let ret= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put RET IN Adjusted_SharpeRatio: (&ret);
/*Find number of columns in the data set*/
%let nv = %sysfunc(countw(&ret));
/*Define counters for array operations*/
%let j= %ranname();
/*Define temporary data set names with random names*/
%let Chained_Ex_Ret= %ranname();
%let Ann_StD= %ranname();

%return_excess(&returns, Rf= &Rf, dateColumn= &dateColumn, outData= &Chained_Ex_Ret);
%return_annualized(&Chained_Ex_Ret, scale= &scale, method= &method, outData= &Chained_Ex_Ret);

%Standard_Deviation(&returns, 
							annualized= TRUE, 
							scale= &scale,
							dateColumn= &dateColumn,
							outData= &Ann_StD);

data &outData (drop= &j);
retain _STAT_;
format _STAT_ $32.;
set &Chained_Ex_Ret &Ann_StD (in=s);
drop &dateColumn;
_STAT_= 'Sharpe_Ratio';
array minRf[&nv] &ret;

do &j=1 to &nv;
	minRf[&j] = lag(minRf[&j])/minRf[&j];
end;

if s;
run;

quit;
/*%local vars nv _tempRP _tempStd _tempRPStd;*/
/**/
/*/*Find all variable names excluding the date column and risk free variable*/*/
/*%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf); */
/*%put VARS IN SharpeRatio_annualized: (&vars);*/
/**/
/*%let nv = %sysfunc(countw(&vars));*/
/**/
/*%let _tempRP= %ranname();*/
/*%let _tempStd= %ranname();*/
/*%let Ann_St= %ranname();*/
/**/
/*%let i= %ranname();*/
/**/
/*%return_annualized(&returns, scale= &scale, method= &method, outData= &Chained_Ex_Ret);*/
/*%return_excess(&Chained_Ex_Ret, Rf= &Rf, dateColumn= &dateColumn, outReturn= &Chained_Ex_Ret);*/
/*%Standard_Deviation(&returns,annualized= TRUE, scale= &scale,dateColumn= &dateColumn,outData= &Ann_StD);*/
/**/
/*data &outData;*/
/*set RP Std (in=s);*/
/*drop &i &dateColumn;*/
/*array vars[&nv] &vars;*/
/**/
/*do &i=1 to &nv;*/
/*	vars[&i] = lag(vars[&i])/vars[&i];*/
/*end;*/

/*if s;*/
/*run;*/

/*quit; */

/*proc datasets lib= work nolist;*/
/*delete &_tempRP &_tempStd;*/
/*run;*/
/*quit;*/

proc datasets lib=work nolist;
delete &Ann_StD &Chained_Ex_Ret;
run;
quit;
%mend;
