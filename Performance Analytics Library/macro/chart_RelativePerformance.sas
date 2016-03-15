/*---------------------------------------------------------------
* NAME: Chart_RelativePerformance.sas
*
* PURPOSE: Create a chart displaying relative performance compared to a benchmark asset or instrument. 
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. The value or variable representing the risk free rate of return. [Default=0]
* title - Optional.  Title for chart. [Default= Relative Performance Against &Rf]
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           [Default=DISCRETE]
* dateColumn - Optional. Specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 2/1/2016 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro chart_RelativePerformance(returns,
										Rf= 0,
										title= Relative Performance Against &Rf, 
										method= DISCRETE,  
										dateColumn= DATE);

%local vars;
/*Find all variable names excluding the risk free variable*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &Rf); 
%put VARS IN return_calculate: (&vars);

%return_excess(&returns, 
						Rf= &Rf, 
						outData= &returns);

data &returns(keep= &vars);
set &returns;
run;

%return_cumulative(&returns, 
							method= &method,
							outData= &returns); 

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



