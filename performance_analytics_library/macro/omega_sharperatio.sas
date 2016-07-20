/*---------------------------------------------------------------
* NAME: Omega_SharepeRatio.sas
*
* PURPOSE: Calculate Omega Sharpe ratio for return series
*
* NOTES: Omega Sharpe ratio is converted from Omega ratio to a ranking statistic
*        in familiar form to the Sharpe ratio. It can be simplified as Omega minus 1. 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. A reference point to be compared. The reference 
*       point may be the mean or some specified threshold.Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Omega Sharpe ratios.  Default="omegasharpe".
*
* MODIFIED:
* 7/18/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Omega_SharpeRatio(returns,
							  MAR= 0,
							  dateColumn= DATE,
						      outData= omegasharpe);
							
%local vars i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Omega_SharpeRatio: (&vars);

%let i = %ranname();

%Omega(&returns, MAR= &MAR, dateColumn= &dateColumn, outData= &outData);

data &outData (keep=_stat_ &vars);
	set &outData;

	array ret[*] &vars;
	do &i= 1 to dim(ret);
		ret[&i]= ret[&i]-1;
	end;

	_STAT_= 'Omega Sharpe Ratio';
run;

%mend;
