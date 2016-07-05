/*---------------------------------------------------------------
* NAME: Total_Risk.sas
*
* PURPOSE: Calculate total risk of the return distribution.
*
* NOTES: The square of total risk is the sum of the square of systematic risk and
*        the square of specific risk. Both terms are annualized.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set of total risk.  Default="Risk_total".

* MODIFIED:
* 6/07/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Total_Risk(returns, 
						BM=, 
						Rf= 0,
						scale= 1,
						VARDEF = DF,
						dateColumn= DATE,
						outData= Risk_total);

%table_SpecificRisk(&returns, 
					BM=&BM, 
					Rf=&RF,
					scale= &scale,
					VARDEF= &VARDEF,
					dateColumn= &dateColumn,
					outData= &outData,
					printTable= NOPRINT);

%local vars;
%let vars= %get_number_column_names(_table= &returns, _exclude=&dateColumn _stat_ &BM);

data &outData;
	set &outData(where=(_STAT_ = "Total Risk"));
	format &vars best12.;
run;

%mend;
