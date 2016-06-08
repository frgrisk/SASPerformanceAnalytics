/*---------------------------------------------------------------
* NAME: KellyRatio.sas
*
* PURPOSE: calculate Kelly ratio of a strategy.
*
* NOTES: The Kelly Criterion was identified by John Kelly, which can be expressed as the expected excess return
*		 of a strategy divided by the expected variance of the excess return.
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns.
* Rf - Optional. The value or variable representing the risk free rate of return. Default=0
* method - Optional. Option to use half-Kelly. Default=HALF
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with Kelly ratio.  Default="KellyRatio".
*
* MODIFIED:
* 6/07/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro KellyRatio(returns,
						Rf= 0,
						method= HALF,
						VARDEF = DF, 
						dateColumn= DATE,
						outData= KellyRatio);

%local ret i temp_excess _tempStd means;


%let ret=%get_number_column_names(_table=&returns,_exclude=&dateColumn &Rf);
%put VARS IN KellyRatio: (&ret);

%let temp_excess= %ranname();
%let _tempStd= %ranname();
%let means= %ranname();
%let i= %ranname();

%return_excess(&returns,Rf= &Rf, dateColumn= &dateColumn,outData= &temp_excess);
%Standard_Deviation(&returns, VARDEF = &VARDEF, dateColumn= &dateColumn, outData= &_tempStd);

data &temp_excess;
	set &temp_excess(firstobs=2);
run; 

proc means data=&temp_excess noprint;
	output out=&means mean=;
run;

data &_tempStd;
	set &_tempStd;
	array ret[*] &ret;

	do &i=1 to dim(ret);
		ret[&i] = ret[&i] ** 2;
	end;
run;

data &outData;
	format _stat_ $32.;
	set &_tempStd(keep=&ret) &&means(keep=&ret);
	array ret[*]  &ret;

	do &i=1 to dim(ret);
		%if %upcase(&method)=HALF %then %do;
			ret[&i] = ret[&i]/LAG(ret[&i])/2;
		%end;
		%else %do;
			ret[&i] = ret[&i]/LAG(ret[&i]);
		%end;
	end;
	_stat_ = "KellyRatio";
	drop &i;
	if _n_=2 then output;
run;

proc datasets lib = work nolist;
	delete &temp_excess &_tempStd &means;
run;
quit;


%mend;



 
