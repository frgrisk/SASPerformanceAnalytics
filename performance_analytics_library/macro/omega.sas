/*---------------------------------------------------------------
* NAME: Omega.sas
*
* PURPOSE: Calculate Omega for return series
*
* NOTES: Omega could be considered as a Sharper ratio, or the successor to Jensen's alpha.
*        As a way to capture all the higher moments of the returns distribution, it involves 
*        partitioning returns into loss and gain above and below a return threshold and then  
*        considering the probability weighted ratio of returns above and below the partitioning.
*        Omega takes the value 1 when r is the mean return. The slope of the Omega indicates 
*        risk: the steeper it is, the less the possibility of extreme returns, aka less risk.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. A reference point to be compared. The reference 
*       point may be the mean or some specified threshold.Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Omega ratios.  Default="omega".
*
* MODIFIED:
* 7/18/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Omega(returns,
				  MAR= 0,
				  dateColumn= DATE,
			      outData= omega);
							
%local vars upside downside i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Omega: (&vars);

%let upside= %ranname();
%let downside= %ranname();

%let i = %ranname();

data &upside(drop=&i &dateColumn);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]<=&MAR then ret[&i]=.; 
		else ret[&i]=ret[&i]-&MAR;
	end;
run;

proc means data=&upside sum noprint;
	output out=&upside sum=;
run;


data &downside(drop=&i &dateColumn);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]>=&MAR then ret[&i]=.; 
		else ret[&i]=&MAR-ret[&i];
	end;
run;

proc means data=&downside sum noprint;
	output out=&downside sum=;
run;

data &outData (keep=_stat_ &vars);
format _STAT_ $32.;

	set &upside &downside end=last;

	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= lag(ret[&i])/ret[&i];
	end;

	_STAT_= 'Omega Ratio';
	if last; 

run;

proc datasets lib=work nolist;
	delete &upside &downside;
run;
quit;

%mend;
