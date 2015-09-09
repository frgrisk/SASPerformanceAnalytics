/*---------------------------------------------------------------
* NAME: CAPM_JensenAlpha.sas
*
* PURPOSE: Calcuate the excess return adjusted for systematic risk.
*
* NOTES: The Jensen’s alpha is the intercept of the regression equation in the Capital Asset Pricing Model
and is in effect the exess return adjusted for systematic risk.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* BM- required.  Specifies the benchmark asset or index in the returns data set.
* Rf- required.  Specifies a variable or number assigned to the risk free rate of return.
* scale - required.  Number of periods per year used in the calculation.
* method- option to implement geometric chaining or arithmetic chaining when annualizing returns. 
*		  {GEOMETRIC, ARITHMETIC} [Default= GEOMETRIC]
* dateColumn - Date column in Data Set. Default=DATE
* outJensen - output Data Set with Jensen alphas.  Default="Jensen_Alpha". 
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
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


%local lib ds nv;

/***********************************
*Figure out 2 level ds name of RETURNS
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
%let ds=&lib;
%let lib=work;
%end;
%put lib:&lib ds:&ds;


%return_annualized(&returns, 
							scale=&scale,
							method= &method,
							dateColumn= &dateColumn, 
							outReturnAnnualized= annualized_returns);

%return_excess(annualized_returns, 
								Rf= &Rf, 
								dateColumn= &dateColumn,
								outReturn= annualized_returns);



%CAPM_alpha_beta(&returns, 
						BM= &BM, 
						Rf= &Rf,
						dateColumn= &dateColumn,  
						outBeta= outBeta);

data outBeta;
set outBeta;
if alphas_and_betas= 'alphas' then delete;
run;

proc sql noprint;
select name
into :ret separated by ' '
     from sashelp.vcolumn
where libname = upcase("&lib")
 and memname = upcase("&ds")
 and type = "num"
 and upcase(name) ^= upcase("&dateColumn")
 and upcase(name) ^= upcase("&Rf")
 and upcase(name) ^= upcase("&BM");
quit;

proc iml;
use outBeta;
read all var _num_ into x;
close outBeta;

use annualized_returns;
read all var {&ret} into y[colname= names];
close annualized_returns;

use annualized_returns;
read all var {&BM} into z;
close annualized_returns;
jensen= y-(x#z);

jensen= jensen`;
names= names`;

create &outJensen from jensen[rowname= names];
append from jensen[rowname= names];
close &outJensen;
quit;

proc transpose data= &outJensen out= &outJensen name= Jensen_Alpha;
id names;
run;

data &outJensen;
format Jensen_Alpha $32.;
set &outJensen;
Jensen_Alpha= 'Jensen_Alpha';
run;

proc datasets lib= work nolist;
delete outBeta annualized_returns;
run;
%mend;