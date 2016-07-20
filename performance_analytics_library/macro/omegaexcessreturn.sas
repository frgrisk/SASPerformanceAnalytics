/*---------------------------------------------------------------
* NAME: OmegaExcessReturn.sas
*
* PURPOSE: Calculate omega excess return for return series
*
* NOTES: Omega excess return is another form of downside risk_adjusted return.
*        The downside risk-adjusted benchmark return is calculated by multiplying
*        the downside variance of the style benchmark by 3 times the style beta. 
*        The 3 is arbitrary and assumes the investor requires 3 units of return for   
*        1 unit of variance. The style beta is ratio of downside risk of portfolio 
*        divided by the downside risk of the style benchmark.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* MAR - Optional. Minimum Acceptable Return. A reference point to be compared. The reference 
*       point may be the mean or some specified threshold.Default=0
* scale - Required. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with omega excess returns.  Default="omegaexcess".
*
* MODIFIED:
* 7/18/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro OmegaExcessReturn(returns,
							  BM= ,
							  MAR= 0,
							  scale= 1,
							  method= DISCRETE,
							  dateColumn= DATE,
						      outData= omegaexcess);
							
%local vars annualized std_bchmk std_asset i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM);
%put VARS IN OmegaExcessReturn: (&vars);

%let annualized= %ranname();
%let std_bchmk= %ranname();
%let std_asset= %ranname();

%let i = %ranname();

%return_annualized(&returns,scale= &scale, method= &method, dateColumn= &dateColumn, outData= &annualized);

%downside_risk(&returns, MAR=&MAR, option=RISK, dateColumn= &dateColumn, outData= &std_asset);

data &std_bchmk(keep=&vars);
	set &std_asset;

	array ret[*] &vars;
	do &i=1 to dim(ret);
		ret[&i]=&BM;
	end;
run;

data &std_asset(keep=&vars);
	set &std_asset;
run;

data &outData (keep=_stat_ &vars);
format _STAT_ $32.;

	set &std_asset &std_bchmk &annualized end=last;

	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= ret[&i]-3*lag(ret[&i])*lag2(ret[&i])*&scale;
	end;

	_STAT_= 'Omega Excess Return';
	if last; 

run;

proc datasets lib=work nolist;
	delete &annualized &std_asset &std_bchmk;
run;
quit;

%mend;
