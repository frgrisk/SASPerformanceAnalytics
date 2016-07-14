/*---------------------------------------------------------------
* NAME: CAPM_epsilon.sas
*
* PURPOSE: computes values of epsilon (error term) as defined in the capital asset pricing model.
*
* NOTES: The value of epsilon is calculated given returns, a risk free rate, and a benchmark asset. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* BM - Optional. Specifies the variable name of benchmark asset or index in the returns data set. Default=0
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=0
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set of asset's Epsilon. Default="epsilon".
*
* MODIFIED:
* 6/17/2015 – DP - Initial Creation
* 9/26/2015 - CJ - Replaced all temporary counters and data sets with random names.
* 				   Replaced chaining with %return_annualized to give user optional chaining methods.
*				   Replaced macro %renamer with PROC Transpose preserving numeric variables.
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - Parameter consistency
* 7/13/2016 - QY - Changed order of %return_excess and %return_annualized
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro CAPM_epsilon(returns, 
						BM=, 
						Rf= 0,
						scale= 1,
						method= DISCRETE, 
						dateColumn= DATE, 
						outData= epsilon);

%local vars _tempRP Betas exBM i;
/*Find all variable names excluding the date column, benchmark, and risk free variables*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM); 
%put VARS IN CAPM_epsilon: (&vars);
/*Find number of variables in data set excluding the date column, benchmark, and risk free variables*/
%let nvars = %sysfunc(countw(&vars));
/*Define temporary data set names with random names*/
%let _tempRP= %ranname();
%let Betas= %ranname();
%let exBM= %ranname();
/* Assign random names to array counters*/
%let i= %ranname();

%return_excess(&returns,Rf= &Rf,dateColumn= &dateColumn,outData= &_tempRP);
%return_annualized(&_tempRP, scale= &scale, method= &method, outData= &_tempRP);


data &exBM;
	set &_tempRP;
	array ret[*] &vars;
	do &i=1 to dim(ret);
		ret[&i]=&BM;
	end;
run;

%CAPM_alpha_beta(&returns,BM= &BM,Rf= &Rf,dateColumn= &dateColumn,outData= &betas);

data &outData;
format _STAT_ $32.;
	set &_tempRP &betas &exBM end=last;
	array ret[*] &vars;
	do &i=1 to dim(ret);
		ret[&i]=lag3(ret[&i])-lag2(ret[&i])-lag(ret[&i])*ret[&i];
	end;
	if last;
	_stat_="Epsilon";
run;

/*data &_tempAlpha;*/
/*set &betas;*/
/*	if _STAT_= 'alphas'*/
/*		then delete;*/
/*run;*/
/**/
/**/
/*data &_tempBeta;*/
/*set &betas;*/
/*	if _STAT_= 'betas'*/
/*		then delete;*/
/*run;*/
/**/
/*proc iml;*/
/*use &exBM;*/
/*read all var _num_ into x;*/
/*close &exBM;*/
/**/
/*use &_tempAlpha;*/
/*read all var _num_ into y[colname= names];*/
/*close &_tempAlpha;*/
/**/
/*betaVal= y*x;*/
/**/
/*betaVal= betaVal`;*/
/*names= names`;*/
/**/
/*create &betaVal_t from betaVal[rowname= names];*/
/*append from betaVal[rowname= names];*/
/*close &betaVal_t;*/
/*quit;*/
/**/
/*proc transpose data= &betaVal_t out= &betaVal_t;*/
/*id names;*/
/*run;*/
/**/
/*data &outData;*/
/*set  &_tempBeta &betaVal_t &meanRet;*/
/*drop _NAME_ &BM &dateColumn;*/
/*run;*/
/**/
/*data &outData (drop= &s);*/
/*set &outData;*/
/**/
/*array epsilon[*] &vars;*/
/*	do &s= 1 to dim(epsilon);*/
/*		epsilon[&s]= &Rf + epsilon[&s]- lag(epsilon[&s]) - lag2(epsilon[&s]);*/
/*	end;*/
/*run;*/
/**/
/*data &outData;*/
/*set &outData;*/
/*if _n_= 1 then delete;*/
/*if _n_= 2 then delete;*/
/*_STAT_= 'Epsilon';*/
/*run;*/

proc datasets lib= work nolist;
delete &_tempRP &Betas &exBM;
run;
quit;
%mend;
