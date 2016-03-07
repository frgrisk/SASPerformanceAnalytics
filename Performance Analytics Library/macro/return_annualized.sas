/*---------------------------------------------------------------
* NAME: return_annualized.sas
*
* PURPOSE: calculate annualized simple or compound returns from a data
*		   set of prices.
*
* NOTES: Calculates the annualized return using geometric or arithmetic 
*		 chaining.  Number of periods in a year are to scale (daily scale= 252,
*		 monthly scale= 12, quarterly scale= 4). 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* scale - Required. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* method - Optional. Specifies either geometric or arithmetic chaining method {GEOMETRIC, ARITHMETIC}.  
           Default=GEOMETRIC
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outReturnAnnualized - Optional. Output Data Set with annualized returns.  Default="annualized_returns". 
*
* MODIFIED:
* 6/2/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_annualized(returns, 
								scale=,
								method= GEOMETRIC,
								dateColumn= DATE, 
								outReturnAnnualized= annualized_returns);

%local _tempRP nv ret;

%let ret=%get_number_column_names(_table=&returns,_exclude=&dateColumn);

%let nv = %sysfunc(countw(&ret));

%let _tempRAnn = %ranname();

/*Create a series for taking STDev and Calculate Mean*/
data &_tempRAnn(drop=i) &outReturnAnnualized(drop=i);
set &returns end= last nobs=nobs;

array ret[&nv] &ret;
array prod[&nv] _temporary_;

if _n_ = 1 then do;
	do i=1 to &nv;
		/*Geometric*/
%if %upcase(&method) = GEOMETRIC %then %do;
		prod[i] = 1;
%end;

		/*Arithmetic*/
%else %if %upcase(&method) = ARITHMETIC %then %do;
		prod[i] = 0;
%end;
	end;
	delete;
end;

do i=1 to &nv;
	/*Geometric*/
%if %upcase(&method) = GEOMETRIC %then %do;
	prod[i] = prod[i] * (1+ret[i])**(&scale);
	
%end;
	/*Arithmetic*/
%else %if %upcase(&method) = ARITHMETIC %then %do;
	prod[i] = prod[i] + ret[i]*sqrt(&scale);
	ret[i] = ret[i] * sqrt(&scale);
%end;
end;
output &_tempRAnn;

if last then do;
	do i=1 to &nv;
	%if %upcase(&method) = GEOMETRIC %then %do;

		ret[i] =(prod[i])**(1/(nobs-1)) - 1;
	%end;

		/*Arithmetic*/
	%else %if %upcase(&method) = ARITHMETIC %then %do;
		ret[i] = prod[i]/(nobs-1);
		ret[i] = ret[i] *sqrt(&scale);
	%end;
	
	end;
	output &outReturnAnnualized;
end;
run;
quit;

proc datasets lib= work nolist;
delete &_tempRAnn;
run;
quit;
%mend;






