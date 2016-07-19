/*---------------------------------------------------------------
* NAME: MSquared_Excess.sas
*
* PURPOSE: Calculate M squared excess return measures the quantity above benchmark.
*
* NOTES: As normal excess returns, there are geometric excess and arithmetic excess. 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Required. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* option - Required. Specify whether report the geometric or arithmetic excess M Squared. {GEOMETRIC, ARITHMETIC}.
* dateColumn - Optional. Date column in Data Set. Default=Date
* outData - Optional. Output Data Set of MSquared excess return.  Default= "MSquaredExcess".
*
* MODIFIED:
* 7/13/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro MSquared_Excess(returns, 
						BM=,  
						Rf= 0,
						scale= 1,
						method= DISCRETE, 
						VARDEF = DF, 
						option= ,
						dateColumn= DATE,
						outData= MSquaredExcess);
								
%local _temp_bm vars i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &Rf &BM);
%put VARS IN MSquared_Excess: (&vars);

%let _temp_bm= %ranname();
%let i= %ranname();

%if %upcase(&option)=ARITHMETIC %then %do;
	%MSquared(&returns,BM=&BM,Rf= &Rf,scale= &scale,method= &method,VARDEF = &VARDEF,NET= TRUE,dateColumn= &dateColumn,outData= &outData);
	data &outData;
		set &outData;
		_stat_="Excess MSquared";
	run;
%end;
%else %do;
	%return_annualized(&returns, scale= &scale, method= &method, dateColumn= &dateColumn, outData= &_temp_bm);

	data &_temp_bm(keep=&vars);
		set &_temp_bm;
		array ret[*] &vars;
		do &i=1 to dim(ret);
			ret[&i]=&BM;
		end;
	run;

	%MSquared(&returns,BM=&BM,Rf= &Rf,scale= &scale,method= &method,VARDEF = &VARDEF,NET= FALSE,dateColumn= &dateColumn,outData= &outData);

	data &outData(keep=_stat_ &vars);
		format _STAT_ $32.;
		set &outData &_temp_bm(in=b);
		array ret[*] &vars;

		do &i=1 to dim(ret);
			ret[&i] = (1+lag(ret[&i]))/(1+ret[&i])-1;
		end;
		if b;
		_STAT_ = "Excess MSquared";
	run;
%end;

proc datasets lib=work nolist;
	delete &_temp_bm;
run;
quit;

%mend;
