/*---------------------------------------------------------------
* NAME: UpsidePotentialRatio.sas
*
* PURPOSE: Upside potential ratio is a further improvement on the Sharpe ratio, extending
*          the measurement of only upside on the numerator, and only the measure of downside
*          on the denominator.
*
* NOTES: Divide upside potential by downside risk.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with d ratio.  Default="DRatio".
*
* MODIFIED:
* 6/9/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro UpsidePotentialRatio(returns,
							  MAR= 0,
							  group= FULL,
							  dateColumn= DATE,
						      outData= UPR);
								
%local vars upside downside i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN UpsidePotentialRatio: (&vars);

%let upside= %ranname();
%let downside= %ranname();

%let i = %ranname();

%upside_risk(&returns,MAR=&MAR,option=potential,group=&group,dateColumn=&dateColumn,outData=&upside)
%downside_risk(&returns,MAR=&MAR,option=risk,group=&group,dateColumn=&dateColumn,outData=&downside)

data &outData(keep=&vars);
	set &upside &downside;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=lag(ret[&i])/ret[&i];
	end;
run;


data &outData;
	format _STAT_ $32.;
	set &outData end= last;
	_STAT_= 'Upside Potential Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &upside &downside;
run;
quit;

%mend;
