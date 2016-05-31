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
* 6/2/2015 – DP - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/25/2016 - QY - Edit format of output
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro return_annualized(returns, 
								scale= 1,
								method= DISCRETE,
								dateColumn= DATE, 
								outData= annualized_returns);

%local _tempRP nv ret i;

%let ret=%get_number_column_names(_table=&returns,_exclude=&dateColumn);

%let nv = %sysfunc(countw(&ret));

%let _tempRAnn = %ranname();
%let i = %ranname();

/*Create a series for taking STDev and Calculate Mean*/
data &_tempRAnn(drop=&i) &outData(drop=&i);
	set &returns end= last nobs=nobs;

	array ret[&nv] &ret;
	array prod[&nv] _temporary_;

	if _n_ = 1 then do;
		do &i=1 to &nv;
			/*DISCRETE*/
		%if %upcase(&method) = DISCRETE %then %do;
				prod[&i] = 1;
		%end;

				/*LOG*/
		%else %if %upcase(&method) = LOG %then %do;
				prod[&i] = 0;
		%end;
		end;
		delete;
	end;

	do &i=1 to &nv;
		/*DISCRETE*/
	%if %upcase(&method) = DISCRETE %then %do;
		prod[&i] = prod[&i] * (1+ret[&i])**(&scale);
		
	%end;
		/*LOG*/
	%else %if %upcase(&method) = LOG %then %do;
		prod[&i] = prod[&i] + ret[&i]*sqrt(&scale);
		ret[&i] = ret[&i] * sqrt(&scale);
	%end;
	end;
	output &_tempRAnn;

	if last then do;
	do &i=1 to &nv;
	%if %upcase(&method) = DISCRETE %then %do;

		ret[&i] =(prod[&i])**(1/(nobs-1)) - 1;
	%end;

		/*LOG*/
	%else %if %upcase(&method) = LOG %then %do;
		ret[&i] = prod[&i]/(nobs-1);
		ret[&i] = ret[&i] *sqrt(&scale);
	%end;
	
	end;
	output &outData;
	end;
run;
quit;

data &outData;
	format _stat_ $32.;
	set &outData(drop=&dateColumn);
	_stat_="Ann_Return";
run;

proc datasets lib= work nolist;
delete &_tempRAnn;
run;
quit;
%mend;
