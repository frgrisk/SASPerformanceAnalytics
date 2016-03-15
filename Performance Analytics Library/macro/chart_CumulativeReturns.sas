/*---------------------------------------------------------------
* NAME: Chart_CumulativeReturns.sas
*
* PURPOSE: Create a chart displaying the cumulative returns of an asset or instrument over time. 
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* title - Optional.  Title for chart. Default= Cumulative Returns
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* WealthIndex - Optional.  Specifies that the value of a dollar in the first sample is $1, therefore charting the value of the returns per dollar over time.
						[Default= FALSE] {TRUE, FALSE}
* grid - Optional. Overlay grid lines on the returns axis. [Default= TRUE] 
* Interval - Optional.  Specifies the frequency of grid lines overlayed on the returns axis. [Default= 1 (100%)]
* dateColumn - Optional. Specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 2/3/2016 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro chart_CumulativeReturns(returns,
										title= Cumulative Returns, 
										method= DISCRETE, 
										WealthIndex= FALSE,
										grid= TRUE,
										Interval= 1,  
										dateColumn= DATE);

%local vars nv i;
/*Find all variable names excluding the date column*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN Chart_CumulativeReturns: (&vars);
/*Find the number of variables in vars*/
%let nv = %sysfunc(countw(&vars));
/*Assign a random name to i*/
%let i= %ranname();

/*Calculate cumulative returns*/
%return_cumulative(&returns, 
							method= &method,
							outData= &returns);

/*Calculate the Value of $1 over time if WealthIndex=TRUE*/
%if &WealthIndex = TRUE %then %do;
data &returns(drop= &i);
set &returns;

array vars[&nv] &vars;
	do &i= 1 to &nv;
		vars[&i]= vars[&i] + 1;
	end;
%end; 

/*Arrange data into one column by date*/
proc transpose data= &returns out= &returns;
by &dateColumn;
run;

/*Chart using by groups*/
proc sgplot data= &returns;
series x= &dateColumn y= col1/ group= _NAME_;
title "&title";
xaxis label= 'Date' type= time;
yaxis label= 'Cumulative Return' 
	%if &grid= TRUE %then %do;
		grid values= (0 to 10 by &interval) valueshint valuesformat= best12.
	%end;
;
keylegend/ border position= bottomright title= "Asset Name";
run;

%mend chart_CumulativeReturns;
