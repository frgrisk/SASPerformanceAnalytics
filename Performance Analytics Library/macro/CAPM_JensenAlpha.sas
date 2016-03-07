/*---------------------------------------------------------------
* NAME: CAPM_JensenAlpha.sas
*
* PURPOSE: Calcuate the excess return adjusted for systematic risk.
*
* NOTES: The Jensen’s alpha is the intercept of the regression equation in the Capital Asset Pricing Model
and is in effect the exess return adjusted for systematic risk.
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* method - Optional. Specifies either geometric or arithmetic chaining method {GEOMETRIC, ARITHMETIC}.  
           Default=GEOMETRIC
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outJensen - Optional. Output Data Set with Jensen alphas.  Default="Jensen_Alpha". 
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
* 9/25/2015 - CJ - Renamed temporary data sets using macro %ranname.
*				   Replaced PROC SQL with %get_number_column_names.
*				   Renamed Jensen_Alpha "_STAT_".
* 3/05/2016 – RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro CAPM_JensenAlpha(returns, 
							BM=, 
							Rf=0, 
							scale= 1,
							method= GEOMETRIC,
							dateColumn= DATE, 
							outJensen= Jensen_Alpha);


%local _tempBeta _tempRAnn _tempRAnn_ex ;
/*Find number of variables in data set excluding the date column, benchmark, and risk free variables*/
/*Define temporary data set names with random names*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM); 
%put VARS IN CAPM_alpha_beta: (&vars);
/*Name temporary data sets*/
%let _tempBeta= %ranname();
%let _tempRAnn_ex= %ranname();


%return_annualized(&returns, 
							scale=&scale,
							method= &method,
							dateColumn= &dateColumn, 
							outReturnAnnualized= &_tempRAnn_ex);

%return_excess(&_tempRAnn_ex, 
								Rf= &Rf, 
								dateColumn= &dateColumn,
								outReturn= &_tempRAnn_ex);



%CAPM_alpha_beta(&returns, 
						BM= &BM, 
						Rf= &Rf,
						dateColumn= &dateColumn,  
						outBeta= &_tempBeta);

data &_tempBeta;
set &_tempBeta;
if _STAT_= 'alphas' then delete;
run;

proc iml;
use &_tempBeta;
read all var _num_ into x;
close &_tempBeta;

use &_tempRAnn_ex;
read all var {&vars} into y[colname= names];
close &_tempRAnn_ex;

use &_tempRAnn_ex;
read all var {&BM} into z;
close &_tempRAnn_ex;
jensen= y-(x#z);

jensen= jensen`;
names= names`;

create &outJensen from jensen[rowname= names];
append from jensen[rowname= names];
close &outJensen;
quit;

proc transpose data= &outJensen out= &outJensen name= _STAT_;
id names;
run;

data &outJensen;
format _STAT_ $32.;
set &outJensen;
_STAT_= 'Jensen_Alpha';
run;

proc datasets lib= work nolist;
delete &_tempBeta &_tempRAnn_ex;
run;
quit;
%mend;
