/*---------------------------------------------------------------
* NAME: Chart_ECDF.sas
*
* PURPOSE: Create a chart displaying the Empirical CDF of an asset in comparison with a normal density CDF. 
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* title- required.  Title for chart. [Default= Relative Performance Against &Rf]
* dateColumn- specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 2/3/2016 – CJ - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Chart_ECDF(returns, 
					title= Empirical CDF,
					dateColumn=Date);


%local vars;
/*Find all variable names excluding the date column*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN Chart_ECDF: (&vars);

title "&title";

ods graphics on;

/*Create ECDF chart with Normal CDF overlayed for each asset*/
proc univariate data=&returns noprint;
var &vars;
cdfplot/ normal;
inset normal(mu sigma);
run;

ods graphics off;

%mend Chart_ECDF;
