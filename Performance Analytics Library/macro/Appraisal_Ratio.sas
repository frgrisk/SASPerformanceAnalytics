/*---------------------------------------------------------------
* NAME: Appraisal_Ratio.sas
*
* PURPOSE: Appraisal ratio is the Jensen's alpha adjusted for specific risk.  The numerator is divided by 
*		   specific risk instead of total risk.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* BM- required.  Specifies the benchmark asset or index in the returns data set.
* Rf- required.  Specifies a variable or number assigned to the risk free rate of return.
* scale - required.  Number of periods per year used in the calculation.
* option- required.  {APPRAISAL, MODIFIED, ALTERNATIVE}.  Choose "appraisal" to calculate the appraisal ratio, 
*					 "modified" to calculate modified Jensen's alpha, or "alternative" to calculate alternative
*					 Jensen's alpha.
* method- option to annualize Jensen's alpha using geometric chaining or arithmetic chaining. {GEOMETRIC, ARITHMETIC} 
*		  [Default= GEOMETRIC].
* dateColumn - Date column in Data Set. Default=DATE
* outAppraisalRatio - output Data Set with Appraisal Ratios.  Default="Appraisal_Ratio". 
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Appraisal_Ratio(returns, 
								BM=, 
								Rf=0, 
								scale= 1,
								option=, 
								method= GEOMETRIC,
								dateColumn= DATE, 
								outAppraisalRatio= Appraisal_Ratio);


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
%CAPM_JensenAlpha(&returns, 
							BM= &BM, 
							Rf= &Rf, 
							scale= &scale, 
							method= &method,
							dateColumn= &dateColumn, 
							outJensen= Jensen_Alpha);

%if %upcase (&option)= APPRAISAL %then %do;
%Specific_Risk(&returns, 
						BM=&BM, 
						Rf=&Rf,
						scale= &scale,
						dateColumn= &dateColumn,
						outSpecificRisk= divisor);

%end;

%else %if %upcase(&option)= MODIFIED %then %do;
%CAPM_alpha_beta(&returns, 
						BM= &BM, 
						Rf= &Rf, 
						dateColumn= &dateColumn, 
						outBeta= divisor);
data divisor;
set divisor;
if alphas_and_betas= 'alphas' then delete;
run;
%end;

%else %if %upcase(&option)= ALTERNATIVE %then %do;
%Systematic_Risk(&returns, 
						BM=&BM, 
						Rf=&Rf,
						scale= &scale,
						dateColumn= &dateColumn,
						outSR= divisor);
%end;

proc sql noprint;
select name
into :vars separated by ' '
     from sashelp.vcolumn
where libname = upcase("&lib")
 and memname = upcase("&ds")
 and type = "num"
 and upcase(name) ^= upcase("&dateColumn")
 and upcase(name) ^= upcase("&Rf")
 and upcase(name) ^= upcase("&BM");
quit;

data &outAppraisalRatio(drop= i);
set divisor Jensen_Alpha;

array vars[*] &vars;
do i= 1 to dim(vars);

vars[i]= vars[i]/lag(vars[i]);
end;
run;

data &outAppraisalRatio;
retain _name_;
set &outAppraisalRatio;
rename _name_= AppraisalRatio;
%if %upcase(&option)= APPRAISAL %then %do;
if stat= 'SpecRisk' then delete;
drop stat;
%end;
%else %if %upcase(&option)= MODIFIED %then %do;
if alphas_and_betas= 'betas' then delete;
drop alphas_and_betas;
%end;
%else %if %upcase(&option)= ALTERNATIVE %then %do;
if stat= 'Sys_Risk' then delete;
drop stat;
%end;
run;

data &outAppraisalRatio;
format AppraisalRatio $32.;
set &outAppraisalRatio;
AppraisalRatio= upcase("&option");
drop Jensen_Alpha;
run;

proc datasets lib= work nolist;
delete divisor Jensen_Alpha;
run;
							
%mend;