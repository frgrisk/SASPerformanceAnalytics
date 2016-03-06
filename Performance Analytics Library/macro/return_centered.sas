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
* outCentered - Optional. Output Data Set with centered returns.  Only used if updateInPlace=FALSE 
*             Default="centered_returns"
*
* MODIFIED:
* 7/8/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_centered(returns, 
						dateColumn=DATE,
						outCentered=centered_returns);

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

create &outCentered from Centered[rowname= names];
append from Centered[rowname= names];
close &outCentered;
quit;

proc transpose data= &outCentered out= &outCentered;
id names;
run;

data &outCentered;
merge &returns(keep= &dateColumn) &outCentered;
drop _name_;
run;
%mend;
