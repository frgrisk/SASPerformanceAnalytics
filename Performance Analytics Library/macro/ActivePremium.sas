/*---------------------------------------------------------------
* NAME: ActivePremium.sas
*
* PURPOSE: Cacluate the return on an investment's annualized return minus the benchmark's annualized return.
*
* NOTES: Also known as active return.
*		 Active premium= Investment's annualized return- Benchmark's annualized return. 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. output Data Set with annualized returns.  Default="active_premium"
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification  
* 3/09/2016 - QY - parameter consistency 
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro ActivePremium(returns, 
							BM=, 
							scale= 1,
							method= DISCRETE,
							dateColumn= DATE, 
							outData= active_premium);

%local ar;
						
%let ar = %ranname();

%return_annualized(&returns, 
					scale= &scale, 
					method= &method, 
					dateColumn= &dateColumn, 
					outData= &ar);

%return_excess(&ar, 
				Rf= &BM, 
				dateColumn= &dateColumn,
				outData= &outData);

data &outData;
format _stat_ $32.;
_stat_='Active Premium';
set &outData;
drop &BM &dateColumn;
run; 

proc datasets lib= work nolist;
delete &ar;
run;
quit;
%mend;


								
