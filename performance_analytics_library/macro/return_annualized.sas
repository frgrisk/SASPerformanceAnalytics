/*---------------------------------------------------------------
* NAME: return_annualized.sas
*
* PURPOSE: calculate annualized simple or compound returns from a data
*		   set of prices.
*
* NOTES: Calculates the annualized return using DISCRETE or LOG 
*		 chaining.  Number of periods in a year are to scale (daily scale= 252,
*		 monthly scale= 12, quarterly scale= 4). 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* scale - Required. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with annualized returns.  Default="annualized_returns". 
*
* MODIFIED:
* 6/02/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - Parameter consistency
* 5/25/2016 - QY - Edited format of output
* 7/06/2016 - QY - Edited calculation by geo_mean and arithmetric mean 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_annualized(returns, 
								scale= 1,
								method= DISCRETE,
								dateColumn= DATE, 
								outData= annualized_returns);

%local _temp nv vars i;
%let vars=%get_number_column_names(_table=&returns,_exclude=&dateColumn);
%put VARS IN return_annualized: (&vars);

%let _temp=%ranname();
%let nv = %sysfunc(countw(&vars));
%let i = %ranname();


		/*DISCRETE*/
%if %upcase(&method) = DISCRETE %then %do;
	%geo_mean(&returns,dateColumn=&dateColumn,outData= &_temp);

	data &outData(keep=_stat_ &vars);
	format _STAT_ $32.;
		set &_temp;
		array ret[&nv] &vars;
		do &i=1 to &nv;
			ret[&i]=(1+ret[&i])**&scale-1;
		end;
		_stat_="Annualized Return";
	run;
%end;

		/*LOG*/
%if %upcase(&method) = LOG %then %do;
	proc means data=&returns mean noprint;
		output out=&_temp mean=;
	run;

	data &outData(keep=_stat_ &vars);
	format _STAT_ $32.;
		set &_temp;
		array ret[&nv] &vars;
		do &i=1 to &nv;
			ret[&i]=ret[&i]*&scale;
		end;
		_stat_="Annualized Return";
	run;
%end;


proc datasets lib= work nolist;
delete &_temp;
run;
quit;
%mend;
