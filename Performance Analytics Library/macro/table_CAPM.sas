/*---------------------------------------------------------------
* NAME: table_CAPM.sas
*
* PURPOSE: 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns of the portfolio.
* BM - 
* Rf - 
* scale - 
* digits -
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Specifies name of output Data Set of correlations.  Default="Correlations".
* printTable - Optional. Option to print output table. {PRINT, NOPRINT} Default= [NOPRINT]
* 
* MODIFIED:
* 5/20/2016 – QY - Initial Creation
* 5/23/2016 - QY - Add VARDEF parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_CAPM(returns, 
					BM=, 
					Rf= 0,
					scale= 1,
					digits= 4,
					VARDEF = DF, 
					dateColumn= DATE, 
					outData= CAPM,
					printTable= NOPRINT);

%local vars RP alphaBeta bullBear R_square AnnuAlpha Corr tracking_error active_premium information_ratio treynor_ratio;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM); 
%put VARS IN table_CAPM: (&vars);

%let RP= %ranname();
%let alphaBeta= %ranname();
%let bullBear= %ranname();
%let R_square= %ranname();
%let AnnuAlpha= %ranname();
%let Corr= %ranname();
%let tracking_error= %ranname();
%let active_premium= %ranname();
%let information_ratio= %ranname();
%let treynor_ratio= %ranname();


%return_excess(&returns, Rf= &Rf, dateColumn= &dateColumn, outData= &RP);
data &RP(drop= i);
	set &RP;
	array excess[*] &vars;
	if _n_=1 then
	do i= 1 to dim(excess);
		excess[i]= .;
	end;
run;

/*calculate alpha and beta*/
%CAPM_alpha_beta(&returns, BM=&BM, Rf= &Rf, dateColumn= &dateColumn, outData= &alphaBeta);
/*calculate bull and bear beta*/
%Bull_Bear_beta(&returns, BM=&BM, Rf= &Rf, dateColumn= &dateColumn, outData= &bullBear);

/*calculate R square*/
proc RSQUARE data= &RP OUTEST= &R_square noprint;
model &vars = &BM;
quit;

data &R_square;
set &R_square;
keep _depvar_ _rsq_;
rename _rsq_= Rsquare;
run;

proc transpose data= &R_square out=&R_square(drop=_label_)  name= _STAT_;
id _depvar_;
run;

/*calculate annualized alpha*/
data &AnnuAlpha(drop=i);
format _stat_ $32.;
set &alphaBeta;
where _STAT_='alphas';
array alpha[*] &vars;
retain alpha;
do i=1 to dim(alpha);
	alpha[i]=(1+alpha[i])**(&scale) - 1;
end;
if _stat_='alphas' then 
	_stat_='Annualized Alphas';
run;

/*calculate correlation and p-value*/
%table_correlation(&returns, returnsCompare=&BM, dateColumn= &dateColumn, outData= &corr);

data &corr;
set &corr;
where var^=withvar;
run;

proc transpose data= &corr(keep=var correlation p_value) out=&corr(rename=(_label_=_stat_) drop=_name_);
id var;
run;

/*calculate tracking error*/
%TrackingError(&returns, BM=&BM, annualized= TRUE, scale= &scale,VARDEF= &VARDEF,dateColumn= &dateColumn, outData= &tracking_error)

/*calculate active premium*/
%ActivePremium(&returns, BM=&BM, scale= &scale, dateColumn= &dateColumn, outData= &active_premium)

/*calculate information ratio*/
%Information_Ratio(&returns, BM=&BM, scale= &scale, VARDEF= &VARDEF, dateColumn= &dateColumn, outData= &information_ratio)

/*calculate Treynor ratio*/
%Treynor_Ratio(&returns, BM=&BM, Rf= &Rf, scale = &scale, VARDEF= &VARDEF, modified = FALSE, dateColumn= &dateColumn, outData= &treynor_ratio)

data &outData;
format _stat_ $32. &vars %eval(&digits + 4).&digits;
set &alphaBeta &bullBear &R_square &AnnuAlpha &Corr &tracking_error &active_premium &information_ratio &treynor_ratio;
run;

proc datasets lib= work nolist;
delete &RP &alphaBeta &bullBear &R_square &AnnuAlpha &Corr &tracking_error &active_premium &information_ratio &treynor_ratio;
run;

%if %upcase(&printTable)= PRINT %then %do;
proc print data= &outData noobs;
run;
%end;

%mend;
