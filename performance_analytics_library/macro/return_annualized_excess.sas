/*---------------------------------------------------------------
* NAME: return_annualized_excess.sas
*
* PURPOSE: Calculate the difference in performance between asset and benchmark.
*
* NOTES: There are two common measures of the excess return, "arithmetic" and "geometric". 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* scale - Required. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* option - Required. Specify whether report the geometric or arithmetic annualized excess return. {GEOMETRIC, ARITHMETIC}.
* dateColumn - Optional. Date column in Data Set. Default=Date
* outData - Optional. Output Data Set of annualized excess return.  Default= "Annualized_Excess".
*
* MODIFIED:
* 7/19/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro return_annualized_excess(returns, 
									BM=,  
									scale= 1,
									method= DISCRETE, 
									option= ,
									dateColumn= DATE,
									outData= Annualized_Excess);
								
%local _temp_bm vars i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM);
%put VARS IN return_annualized_excess: (&vars);

%let _temp_bm= %ranname();
%let i= %ranname();

%return_annualized(&returns,scale=&scale,method=&method,dateColumn=&dateColumn,outData=&outData);
data &_temp_bm(keep=&vars);
	set &outData;
	array ret[*] &vars;
	do &i=1 to dim(ret);
		ret[&i]=&BM;
	end;
run;


%if %upcase(&option)=ARITHMETIC %then %do;
	data &outData(keep=_stat_ &vars);
		format _STAT_ $32.;
		set &outData &_temp_bm end=last;
		array ret[*] &vars;

		do &i=1 to dim(ret);
			ret[&i] = lag(ret[&i])-ret[&i];
		end;
		if last;
		_STAT_ = "Arithmetic Excess Return";
	run;
%end;
%else %do;
	data &outData(keep=_stat_ &vars);
		format _STAT_ $32.;
		set &outData &_temp_bm end=last;
		array ret[*] &vars;

		do &i=1 to dim(ret);
			ret[&i] = (1+lag(ret[&i]))/(1+ret[&i])-1;
		end;
		if last;
		_STAT_ = "Geometric Excess Return";
	run;
%end;

proc datasets lib=work nolist;
	delete &_temp_bm;
run;
quit;

%mend;
