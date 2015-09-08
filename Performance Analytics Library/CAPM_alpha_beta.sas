/*---------------------------------------------------------------
* NAME: CAPM_alpha_beta.sas
*
* PURPOSE: computes values of alpha and beta as defined in the capital asset pricing model.
*
* NOTES: Alpha and Beta of a desired asset are calculated given returns, a risk free rate, and a benchmark. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set. 
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* dateColumn - Date column in Data Set. Default=DATE
* outBeta - output Data Set of asset Alphas and Betas.  Default= "alphas_and_betas".
* MODIFIED:
* 6/17/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro CAPM_alpha_beta(returns, 
						BM= 0, 
						Rf= 0,
						dateColumn= DATE,  
						outBeta= alphas_and_betas);

/***********************************
*Figure out 2 level ds name of RETURNS
************************************/
%local lib ds vars rename;

%let lib= %scan(&returns, 1, %str(.));
%let ds= %scan(&returns, 2, %str(.));
%if &ds= "" %then %do;
%let ds= &lib;
%let lib= work;
%end;
%put lib:&lib ds:&ds;

%return_excess(&returns, 
					 	Rf= &Rf, 
						dateColumn= &dateColumn, 
						outReturn= _tempRP);

proc sql noprint;
select name
	into :vars separated by ' '
     from sashelp.vcolumn
		where libname = upcase("work")
 		and memname = upcase("_tempRP")
 		and type = "num"
		and upcase(name) ^= upcase("&dateColumn")
		and upcase(name) ^= upcase("&Rf")
		and upcase(name) ^= upcase("&BM");
quit;

/***************************************
*Use proc reg to compute alpha and beta
****************************************/
proc reg data= _tempRP OUTEST= _tempBetas noprint;
model &vars= &BM /B;
run;

data _tempBetas;
set _tempBetas;
drop &vars _model_ _type_ _rmse_;
rename Intercept= alphas;
rename &BM= betas;
run;

proc transpose data= _tempBetas out= _tempBetas name= alphas_and_betas;
var _all_;
run;

data _tempBetas;
set _tempBetas;
drop _label_;

proc transpose data= _tempBetas(obs= 1) out= tempNames;
var _all_;
run; 

proc sql noprint;
select catx('=', _name_, col1)
	into :rename separated by ' '
		from tempNames;
quit;

data _tempBetas;
	set _tempBetas(rename= (&rename));
run;

data &outBeta;
	set _tempBetas;
	drop _label_;
	if _depvar_= '_DEPVAR_' then delete;
	if _depvar_= 'Stocks' then delete;
	rename _depvar_= alphas_and_betas;
run;

%let nvars= %sysfunc(countw(&vars));

%macro renamer;
 %do z=1 %to &nvars;
 rename x&z = %scan(&vars,&z) ;
 %end;
%mend;
data &outBeta;
set &outBeta;
array charx{&nvars} &vars;
array x{&nvars};
do z=1 to &nvars;
 x{z}=input(charx{z},best12.);
end;
drop &vars z;
%renamer

proc datasets lib= work nolist;
delete _tempRP _tempBetas tempNames;
run;
%mend;