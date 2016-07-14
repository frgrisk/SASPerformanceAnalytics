/*---------------------------------------------------------------
* NAME: Adjusted_SharpeRatio.sas
*
* PURPOSE: Adjusts the Sharpe Ratio for skewness and kurtosis by incorporating a penalty factor 
*		   for negative skewness and excess kurtosis. 
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* Rf - Optional. the value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. output Data Set with adjusted Sharpe Ratios.  Default="adjusted_SharpeRatio"
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
* 9/17/2015 - CJ - Replaced temporary variable and data set names with random names.
*				   Defined all local variables.
*				   Replaced Proc SQL statement with %get_number_column_names().
*				   Renamed column statistic "_STAT_" to be consistent with SAS results.
*				   Replaced code returning DISCRETE chained returns with %return_annualized
*				   Inserted parameter method= to allow user to choose LOG or DISCRETEaly chained returns.
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - Parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
* 7/13/2016 - QY - Replaced calculation of annualized Sharpe ratio by %SharpeRatio_annualized
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Adjusted_SharpeRatio(returns,
								Rf= 0, 
								scale= 1,
								method= DISCRETE,
								VARDEF = DF, 
								dateColumn= DATE, 
								outData= adjusted_SharpeRatio);


%local ret nv i Skew_Kurt_Table SR;
/*Find all variable names excluding the date column and risk free variable*/
%let ret= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf);
%put RET IN Adjusted_SharpeRatio: (&ret);
/*Find number of columns in the data set*/
%let nv = %sysfunc(countw(&ret));
/*Define counters for array operations*/
%let i= %ranname();
/*Define temporary data set names with random names*/
%let Skew_Kurt_Table= %ranname();
%let SR= %ranname();

%SharpeRatio_annualized(&returns, Rf= &Rf, scale= &scale, method= &method, VARDEF = &VARDEF, dateColumn= &dateColumn, outData= &SR);

proc transpose data=&returns out=&Skew_Kurt_Table;
by &dateColumn;
var &ret;
run;

proc sort data=&Skew_Kurt_Table;
by _name_;
run;

proc univariate data=&Skew_Kurt_Table noprint vardef=N;
var COL1;
by _NAME_;
output out=&Skew_Kurt_Table
	SKEW=Skewness
	KURT=Kurtosis;
run;


data &Skew_Kurt_Table;
set &Skew_Kurt_Table;
adjSkew= Skewness/6;
adjKurt= (Kurtosis)/24;
drop Skewness Kurtosis;
run;

proc transpose data= &Skew_Kurt_Table out= &Skew_Kurt_Table;
id _name_;
run;


data &outData(drop= &i _name_);
	retain _stat_ &ret;
	format _stat_ $32.;
	set &Skew_Kurt_Table &SR;

	array vars[*] &ret;
	do &i= 1 to &nv;
	vars[&i]= vars[&i]*(1+lag2(vars[&i])*vars[&i]-lag(vars[&i])*vars[&i]**2);
	end;

	if _NAME_= 'adjSkew' then delete;
	if _NAME_= 'adjKurt' then delete;
	_stat_= 'Adj_SharpeRatio';
run;

proc datasets lib=work nolist;
delete &Skew_Kurt_Table &SR;
run;
quit;


%mend;
 
