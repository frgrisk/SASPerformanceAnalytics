/*---------------------------------------------------------------
* NAME: return_centered.sas
*
* PURPOSE: calculate centered returns.
*
* NOTES: The n-th centered moment is calculated as moment^n(R)= E[(r-E(R))^n];
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with centered returns. 
*             Default="centered_returns"
*
* MODIFIED:
* 7/8/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_centered(returns, 
						dateColumn= DATE,
						outData= centered_returns);

%local vars;

/*Find all variable names excluding the date column and risk free variable*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN return_calculate: (&vars);

proc iml;
use &returns;
read all var {&vars} into a[colname= names];
close &returns;

MeanA= mean(a);
Centered= a-MeanA;

Centered= Centered`;
names= names`;

create &outData from Centered[rowname= names];
append from Centered[rowname= names];
close &outData;
quit;

proc transpose data= &outData out= &outData;
id names;
run;

data &outData;
merge &returns(keep= &dateColumn) &outData;
drop _name_;
run;
%mend;
