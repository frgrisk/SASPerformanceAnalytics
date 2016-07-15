/*---------------------------------------------------------------
* NAME: Prospect_Ratio.sas
*
* PURPOSE: Calculate prospect ratio which is used to penalize loss
*          since most people feel loss greater than gain
*
* NOTES: Watanabe notes that people have a tendency to feel loss greater 
*        than gain - a well-known phenomena described by prospect theory.
*        He suggests penalizing loss in the prospect ratio.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* MAR - Optional. Minimum Acceptable Return. Default=0
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with prospect ratio.  Default="ProspectRatio".
*
* MODIFIED:
* 6/9/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Prospect_Ratio(returns,
					  MAR= 0,
					  dateColumn= DATE,
				      outData= ProspectRatio);
							
%local vars temp stat_n down_std i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Prospect_Ratio: (&vars);

%let temp= %ranname();
%let stat_n= %ranname();
%let down_std= %ranname();

%let i = %ranname();

data &temp(drop=&i &dateColumn);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]<0 then ret[&i]=2.25*ret[&i]; 
	end;
run;

proc means data=&temp sum n noprint;
	output out=&temp(keep=&vars) sum=;
	output out=&stat_n(keep=&vars) n=;
run;

data &temp (drop= &i);
	set &temp;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=ret[&i]-&MAR; 
	end;
run;

data &temp(drop=&i);
	set &temp &stat_n(in=last);
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= lag(ret[&i])/ret[&i];
	end;
	if last;
run;

%downside_risk(&returns, MAR= &MAR, option=RISK, group= FULL, dateColumn= &dateColumn, outData= &down_std);

data &outData (keep= _stat_ &vars);
	format _STAT_ $32.;
	set &temp &down_std(in=last);

	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= lag(ret[&i])/ret[&i];
	end;
	_STAT_= 'Prospect Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &temp &down_std &stat_n;
run;
quit;

%mend;
