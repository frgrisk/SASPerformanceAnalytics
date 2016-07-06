/*---------------------------------------------------------------
* NAME: Bull_Bear_beta.sas
*
* PURPOSE: computes values of bull beta and bear beta as defined in the capital asset pricing model.
*
* NOTES: Betas of a desired asset are calculated given returns, a risk free rate, and a benchmark. Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in the return data set;
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set of bull and bear betas. Default= "bull_and_bear"
*
* MODIFIED:
* 5/18/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Bull_Bear_beta(returns, 
						BM=, 
						Rf= 0,
						dateColumn= DATE,  
						outData= bull_and_bear);

%local vars RP bull bear bull_Beta bear_Beta;
/*Find all variable names excluding the date column, benchmark, and risk free variables*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM); 
%put VARS IN Bull_Bear_beta: (&vars);
/*Define temporary data set names with random names*/
%let RP= %ranname();
%let bull= %ranname();
%let bear= %ranname();
%let bull_Beta= %ranname();
%let bear_Beta= %ranname();

%return_excess(&returns, Rf= &Rf, dateColumn= &dateColumn, outData= &RP);


/***************************************
* Calculate bull betas
****************************************/

data &bull;
set &RP;
where &BM>0;
run;

proc reg data= &bull OUTEST= &bull_Beta noprint;
model &vars = &BM;
run;
 
data &bull_Beta;
set &bull_Beta;
drop &vars _model_ _type_ _rmse_ Intercept;
rename &BM= bull_betas;
run;

proc transpose data= &bull_Beta out=&bull_Beta  name= _STAT_;
id _depvar_;
run;


/***************************************
* Calculate bear betas
****************************************/

data &bear;
set &RP;
where &BM<0;
run;

proc reg data= &bear OUTEST= &bear_Beta noprint;
model &vars = &BM;
run;
 
data &bear_Beta;
set &bear_Beta;
drop &vars _model_ _type_ _rmse_ Intercept;
rename &BM= bear_betas;
run;

proc transpose data= &bear_Beta out=&bear_Beta  name= _STAT_;
id _depvar_;
run;


/***************************************
* merge and output
****************************************/

data &outData(drop= _label_);
set &bull_beta &bear_beta;
run;

proc datasets lib= work nolist;
delete &RP &bull &bear &bull_Beta &bear_Beta;
run;
quit;
%mend;
