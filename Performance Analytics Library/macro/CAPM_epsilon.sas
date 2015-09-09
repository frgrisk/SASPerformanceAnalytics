/*---------------------------------------------------------------
* NAME: CAPM_epsilon.sas
*
* PURPOSE: computes values of epsilon (error term) as defined in the capital asset pricing model.
*
* NOTES: The value of epsilon is calculated given returns, a risk free rate, and a benchmark asset. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* BM- required.  Names variable containing returns of benchmark asset from returns data set. 
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* Scale- Required. Specifies the number of periods in one year.  [Daily= 252, Weekly= 52, Monthly= 12, Quarterly= 4] 
* dateColumn - Date column in Data Set. Default=DATE
* outEpsilon - output Data Set of asset's Epsilon.  Default="Epsilon".
* MODIFIED:
* 6/17/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro CAPM_epsilon(returns, 
						BM= 0, 
						Rf= 0,
						scale= 0,
						dateColumn= DATE, 
						outEpsilon= epsilon);


%local lib ds ret ;

/***********************************
*Figure out 2 level ds name of PRICES
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;

proc sql noprint;
select name
into :ret separated by ' '
     from sashelp.vcolumn
where libname = upcase("&lib")
 and memname = upcase("&ds")
 and type = "num"
 and upcase(name) ^= upcase("&dateColumn")
and upcase(name) ^= upcase("&Rf");
quit;

%let nv = %sysfunc(countw(&ret));

/*Create a series for taking STDev and Calculate Mean*/
data &returns(drop=i) _meanRet1(drop=i);
set &returns end=last nobs=nobs;

array ret[&nv] &ret;
array prod[&nv] _temporary_;

if _n_ = 1 then do;
	do i=1 to &nv;
		prod[i] = 1;
	end;
	delete;
end;

do i=1 to &nv;
	prod[i] = prod[i] * (1+ret[i])**(&scale);

end;
output &returns;

if last then do;
	do i=1 to &nv;

		ret[i] =(prod[i])**(1/(nobs)) - 1;
	end;
	output _meanRet1;
end;
run;

%CAPM_alpha_beta(&returns, 
						BM= &BM, 
						Rf= &Rf,
						dateColumn= &dateColumn,  
						outBeta= alphas_and_betas);

%return_excess(_meanRet1, 
					 	Rf= &Rf, 
						dateColumn= &dateColumn, 
						outReturn= _tempRP);

data _temp;
set _tempRP;
keep &BM;

data _temp2;
set alphas_and_betas;
	if alphas_and_betas= 'alphas'
		then delete;
run;

data _temp3;
set alphas_and_betas;
	if alphas_and_betas= 'betas'
		then delete;
run;

proc iml;
use _temp;
read all var _num_ into x;
close _temp;

use _temp2;
read all var _num_ into y[colname= names];
close _temp2;

betaVal= y*x;

betaVal= betaVal`;
names= names`;

create betaVal_t from betaVal[rowname= names];
append from betaVal[rowname= names];
close betaVal_t;
quit;

proc transpose data= betaVal_t out= real_t;
var _all_;
run;

proc transpose data= real_t(obs= 1) out= tempNames;
var _all_;
run; 

proc sql noprint;
select catx('=', _name_, names)
	into :rename separated by ' '
		from tempNames;
quit;

data real_t;
	set real_t(rename= (&rename));
run;

%let nvars= %sysfunc(countw(&ret));

%macro renamer;
 %do z=1 %to &nvars;
 rename x&z = %scan(&ret,&z) ;
 %end;
%mend;
data real_t;
set real_t;
array charx{&nvars} &ret;
array x{&nvars};
do z=1 to &nvars;
 x{z}=input(charx{z},best24.);
end;
drop &ret z;
%renamer

data real_t;
set real_t;
if names= 'names'
	then delete;
drop names;
run;

data outEps1;
set  _temp3 real_t _meanRet1;
drop alphas_and_betas &BM date;
run;

proc sql noprint;
select name
	into :vars separated by ' '
	from sashelp.vcolumn
		where libname = upcase("work")
 		and memname = upcase("outEps1")
 		and type = "num"
		and upcase(name) ^= upcase("&dateColumn")
		and upcase(name) ^= upcase("&Rf")
		and upcase(name) ^= upcase("&BM");
quit;

data &outEpsilon (drop= s);
set outEps1;

array epsilon[*] &vars;

do s= 1 to dim(epsilon);
	epsilon[s]= &Rf + epsilon[s]- lag(epsilon[s]) - lag2(epsilon[s]);
end;
run;

data &outEpsilon;
set &outEpsilon;
if _n_= 1 then delete;
if _n_= 2 then delete;
keep &vars;
run;

data &outEpsilon;
stat= 'epsilon';
set &outEpsilon;
run;

proc datasets lib= work nolist;
delete _tempRP tempNames alphas_and_betas _temp _temp2 _temp3 
		real_t outEps1 betaVal_t _meanRet1;
run;
%mend;
