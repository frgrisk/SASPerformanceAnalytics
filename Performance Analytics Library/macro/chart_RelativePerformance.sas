/*---------------------------------------------------------------
* NAME: Chart_RelativePerformance.sas
*
* PURPOSE: Create a chart displaying relative performance compared to a benchmark asset or instrument. 
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* Rf- required.  Names the risk free rate or benchmark asset to be used in comparison.
* title- required.  Title for chart. [Default= Relative Performance Against &Rf]
* method- option.  Specifies the method of chaining in computing the cumulative return.  [Default= GEOMETRIC] {GEOMETRIC, ARITHMETIC}  
* dateColumn- specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 2/1/2016 – CJ - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro chart_RelativePerformance(returns,
										Rf=0,
										title= Relative Performance Against &Rf, 
										method= GEOMETRIC,  
										dateColumn= Date);

%local vars;
/*Find all variable names excluding the risk free variable*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &Rf); 
%put VARS IN return_calculate: (&vars);

%return_excess(&returns, 
						Rf= &Rf, 
						outReturn= &returns);

data &returns(keep= &vars);
set &returns;
run;

%return_cumulative(&returns, 
							method= &method,
							outReturn= &returns); 

proc transpose data= &returns out= &returns;
by &dateColumn;
run;

proc sgplot data= &returns;
series x= &dateColumn y= col1/ group= _NAME_;
title "&title";
xaxis label= 'Date' type= time;
yaxis label= 'Cumulative Return' grid valuesformat= percent10.1 ;
keylegend/ border position= bottomright title= "Asset Name";
run;

%mend chart_RelativePerformance;



