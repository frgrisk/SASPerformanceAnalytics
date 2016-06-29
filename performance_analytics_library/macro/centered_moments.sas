/*---------------------------------------------------------------
* NAME: centered_moments.sas
*
* PURPOSE: calculate the first three centered moments.
*
* NOTES: The n-th centered moment is calculated as moment^n(R)= E[(r-E(R))^n];
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outCenteredVar - Optional. Output data set for centered variance. Default= centered_Var
* outCenteredSkew - Optional. Output data set for centered skewness. Default= centered_Skew
* outCenteredKurt - Optional. Output data set for centered kurtosis. Default= centered_Kurt
*
* MODIFIED:
* 7/8/2015 – DP - Initial Creation
* 9/29/2015 - CJ - Replaced PROC SQL with %get_number_column_names.
*				   Renamed temporary data sets with %ranname().
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro centered_moments(returns,  
						dateColumn= DATE,
						outCenteredVar= centered_Var,
						outCenteredSkew= centered_Skew,
						outCenteredKurt= centered_Kurt);

%local vars;

/*Define temporary data set names with random names*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN centered_moments: (&vars);
/*Name temporary data sets*/
%let centered_returns= %ranname();
%let cent_var= %ranname();
%let cent_skew= %ranname();
%let cent_kurt= %ranname();

%return_centered(&returns, outData= &centered_returns);

proc iml;
use &centered_returns;
read all var {&vars} into cm[colname= names];
close &returns;

CVar= mean(cm#cm);
CSkew= mean(cm#cm#cm);
CKurt= mean(cm#cm#cm#cm);

CVar= CVar`;
names= names`;

create &cent_var from CVar[rowname= names];
append from CVar[rowname= names];
close &cent_var;

CSkew= CSkew`;
names= names`;

create &cent_skew from CSkew[rowname= names];
append from CSkew[rowname= names];
close &cent_skew;

CKurt= CKurt`;
names= names`;

create &cent_kurt from CKurt[rowname= names];
append from CKurt[rowname= names];
close &cent_kurt;
quit;

proc transpose data= &cent_var out= &cent_var;
id names;
run;

data &outCenteredVar(rename= _name_= _STAT_);
format _name_ $32.;
set &cent_var;
n= _n_;
if n= 1 then _name_= 'Centered_Variance';
drop n;
run;

proc transpose data= &cent_skew out= &cent_skew;
id names;
run;

data &outCenteredSkew(rename= _name_= _STAT_);
format _name_ $32.;
set &cent_skew;
n= _n_;
if n= 1 then _name_= 'Centered_Skewness';
drop n;
run;

proc transpose data= &cent_kurt out= &cent_kurt;
id names;
run;

data &outCenteredKurt(rename= _name_= _STAT_);
format _name_ $32.;
set &cent_kurt;
n= _n_;
if n= 1 then _name_= 'Centered_Kurtosis';
drop n;
run;

proc datasets lib= work nolist;
delete &cent_var &cent_skew &cent_kurt &centered_returns;
run;
quit;
%mend;
