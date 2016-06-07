/*---------------------------------------------------------------
* NAME: D_Ratio.sas
*
* PURPOSE: Calculate D ratio of the return distribution
*
* NOTES: It has values between zero and infinity. The lower the d ratio the better the 
*        performance, a value of zero indicating there are no returns less than zero 
*        and a value of infinity indicating there are no returns greater than zero.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with d ratio.  Default="DRatio".
*
* MODIFIED:
* 6/7/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro D_Ratio(returns,
				  dateColumn= DATE,
			      outData= DRatio);
							
%local vars upside up_n downside down_n i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN D_Ratio: (&vars);

%let upside= %ranname();
%let downside= %ranname();
%let up_n= %ranname();
%let down_n= %ranname();

%let i = %ranname();

data &upside(drop=&i &dateColumn);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]<=0 then ret[&i]=.; 
	end;
run;

proc means data=&upside sum n noprint;
	output out=&upside sum=;
	output out=&up_n n=;
run;

data &upside(drop=&i);
	set &upside &up_n;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=lag(ret[&i])*ret[&i]; 
	end;
run;

data &upside(keep=&vars);
	set &upside end=last;
	if last;
run;

data &downside(drop=&i &dateColumn);
	set &returns;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		if ret[&i]>=0 then ret[&i]=.; 
		ret[&i]=-ret[&i];
	end;
run;

proc means data=&downside sum n noprint;
	output out=&downside sum=;
	output out=&down_n n=;
run;

data &downside(drop=&i);
	set &downside &down_n;
	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]=lag(ret[&i])*ret[&i]; 
	end;
run;

data &downside(keep=&vars);
	set &downside end=last;
	if last;
run;

data &outData (drop= &i);
	set &downside &upside;

	array ret[*] &vars;

	do &i= 1 to dim(ret);
		ret[&i]= lag(ret[&i])/ret[&i];
	end;
run;

data &outData;
	format _stat_ $32.;
	set &outData end= last;
	_STAT_= 'D Ratio';
	if last; 
run;

proc datasets lib=work nolist;
	delete &upside &up_n &downside &down_n;
run;
quit;

%mend;
