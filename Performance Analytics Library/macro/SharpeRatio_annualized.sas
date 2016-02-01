/*---------------------------------------------------------------
* NAME: SharpeRatio_annualized.sas
*
* PURPOSE: displays an annualized sharpe ratio with option for geometric or arithmetic chaining.
*
* NOTES: The Sharpe ratio of a desired asset is calculated given returns, a risk free rate, and scale. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* scale - number of periods per year for which Sharpe Ratio is annualized.
* method- option for arithmetic or geometric chaining.  Default= GEOMETRIC
* dateColumn - Date column in Data Set. Default=DATE
* outSharpe - output Data Set with risk premium.  Default="Annualized_SharpeRatio".
*
* MODIFIED:
* 6/12/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro SharpeRatio_annualized(returns, 
					  				 Rf= 0, 
					 				 scale= 0,
					  				 method= GEOMETRIC, 
					  				 dateColumn= date, 
					  				 outSharpe= Annualized_SharpeRatio);

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

%return_excess(&returns, Rf= &Rf, dateColumn= &dateColumn, outReturn= &Chained_Ex_Ret);
%return_annualized(&Chained_Ex_Ret, scale= &scale, method= &method, outReturnAnnualized= &Chained_Ex_Ret);

%Standard_Deviation(&returns, 
							annualized= TRUE, 
							scale= &scale,
							dateColumn= &dateColumn,
							outStdDev= &Ann_StD);

data &outSharpe (drop= &j);
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
/*%return_annualized(&returns, scale= &scale, method= &method, outReturnAnnualized= &Chained_Ex_Ret);*/
/*%return_excess(&Chained_Ex_Ret, Rf= &Rf, dateColumn= &dateColumn, outReturn= &Chained_Ex_Ret);*/
/*%Standard_Deviation(&returns,annualized= TRUE, scale= &scale,dateColumn= &dateColumn,outStdDev= &Ann_StD);*/
/**/
/*data &outSharpe;*/
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
