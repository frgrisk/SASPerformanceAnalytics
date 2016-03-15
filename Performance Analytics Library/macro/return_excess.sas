/*---------------------------------------------------------------
* NAME: return_excess.sas
*
* PURPOSE: calculate simple or compound returns from prices in excess of a given "risk free" rate.
*
* NOTES: Calculates the risk premium of a desired asset returns and a risk free rate.   Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in a return data set;
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with risk premium.  Default="risk_premium".
*
* MODIFIED:
* 5/28/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_excess(returns,
						Rf= 0,
						dateColumn= DATE,
						outData= risk_premium);

%local ret i;


%let ret=%get_number_column_names(_table=&returns,_exclude=&dateColumn &Rf);
%put RET IN return_excess: (&ret);

%let i= %ranname();

data &outData(drop=&i);
	set &returns ;
	array ret[*] &ret;

	do &i=1 to dim(ret);

	if ret[&i] = . then 
		ret[&i] = 0;
	ret[&i]= ret[&i] -&Rf;
	end;
run;
%mend;



 
