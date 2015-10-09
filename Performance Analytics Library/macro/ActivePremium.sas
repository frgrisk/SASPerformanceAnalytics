/*---------------------------------------------------------------
* NAME: ActivePremium.sas
*
* PURPOSE: Cacluate the return on an investment's annualized return minus the benchmark's annualized return.
*
* NOTES: Also known as active return.
*		 Active premium= Investment's annualized return- Benchmark's annualized return. 
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* BM- required.  Specifies the benchmark asset or index in the returns data set.
* scale - required.  Number of periods per year used in the calculation.
* method - {GEOMETRIC, ARITHMETIC} -- option for either geometric or arithmetic chaining.  
           Default=GEOMETRIC
* dateColumn - Date column in Data Set. Default=DATE
* outActivePremium - output Data Set with annualized returns.  Default="active_premium". 
*
* MODIFIED:
* 7/22/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro ActivePremium(returns, 
							BM=, 
							scale= 1,
							method= GEOMETRIC,
							dateColumn= DATE, 
							outActivePremium= active_premium);

%local ar;
						
%let ar = %ranname();

%return_annualized(&returns, 
					scale= &scale, 
					method= &method, 
					dateColumn= &dateColumn, 
					outReturnAnnualized= &ar);

%return_excess(&ar, 
				Rf= &BM, 
				dateColumn= &dateColumn,
				outReturn= &outActivePremium);

data &outActivePremium;
set &outActivePremium;
drop &BM &dateColumn;
run; 

proc datasets lib= work nolist;
delete &ar;
run;
quit;
%mend;


								