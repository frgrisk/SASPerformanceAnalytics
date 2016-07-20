/*---------------------------------------------------------------
* NAME: Market_Timing.sas
*
* PURPOSE: Calculate the market timing skills of the managers.
*
* NOTES: The Treynor-Mazuy model adds market timing as a quadratic pact in the basic CAPM. A statistically
*        significant positive value gamma (the second term coeffecient in the regression) would imply
*        positive market timing skill, which means if a manager can forecast market returns, he will hold
*        a greater proportion of the market portfolio when the return of the market is high and a smaller
*        proportion when the return is low.
*        The Merton-Henriksson model measures the excess return obtained by the manager that cannot be
*        replicated by a mix of options and market portfolio, which represents market timing ability. The
*        basic idea of MH test is to perform a multiple regression depend on portfolio excess return and 
*        a second variable that mimics the payoff to an option. It adds a up-market return D and market
*        timing ability, gamma, in the basic CAPM. 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* option- Required. Specify the model between Treynor-Mazuy and Henriksson-Merton models. {TM, HM}. Default="TM".
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set of asset market timing. Default= "market_timing"
*
* MODIFIED:
* 7/19/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Market_Timing(returns, 
						BM=, 
						Rf= 0,
						option= ,
						dateColumn= DATE,  
						outData= market_timing);

%local vars RP Betas Second;
/*Find all variable names excluding the date column, benchmark, and risk free variables*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM); 
%put VARS IN Market_Timing: (&vars);
/*Define temporary data set names with random names*/
%let RP= %ranname();
%let Betas= %ranname();
%let Second= %ranname();

%return_excess(&returns, 
					 	Rf= &Rf, 
						dateColumn= &dateColumn, 
						outData= &RP);

data &RP;
	set &RP;
%if %upcase(&option)=TM %then %do;
	&Second=&BM**2;
%end;
%else %do;
	if &BM<0 then &Second=0;
	else &Second=&BM;
%end;
run;
	
/***************************************
*Use proc reg to compute alpha and beta
****************************************/

proc reg data= &RP OUTEST= &Betas noprint;
model &vars = &BM &Second;
run;
quit;
 
data &Betas;
set &Betas;
drop &vars _model_ _type_ _rmse_;
rename Intercept= Alpha;
rename &BM= Beta;
rename &Second= Gamma;
run;

proc transpose data= &Betas out=&outData  name= _STAT_;
id _depvar_;
run;

data &outData(drop= _label_);
set &outData;
run;

proc datasets lib= work nolist;
delete &RP &Betas;
run;
quit;
%mend;
