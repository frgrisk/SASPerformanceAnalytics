/*---------------------------------------------------------------
* NAME: Sharpe_Ratio.sas
*
* PURPOSE: The sharpe ratio is the return per unit of risk.  The unit of risk used in this macro is the
* 		   standard deviation of returns.
*
* NOTES: Calculates the Sharpe ratio of a desired asset given returns and a risk free rate.   Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in a return data set;
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* dateColumn - Date column in Data Set. Default=DATE
* outSharpe - output Data Set with Sharpe ratios.  Default="SharpeRatio".
*
*
* Current version of Sharpe_Ratio only incorporates the use of Standard Deviation.  Later modifications may
* include VaR or ES, and an option for weights.
* MODIFIED:
* 6/3/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Sharpe_Ratio(returns,
							Rf= 0,
							dateColumn=DATE,
							outSharpe= SharpeRatio);
							
%local lib ds Sharpe;

/***********************************
*Figure out 2 level ds name of RETURNS
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
%let ds=&lib;
%let lib=work;
%end;
%put lib:&lib ds:&ds;


/**********************
Calculate Sharpe Ratio
**********************/

%return_excess(&returns, 
					 	Rf= &Rf, 
						dateColumn= &dateColumn, 
						outReturn= _tempRP);

proc means data= _tempRP noprint;
output out= ExRet;
run;

data _tempExRet;
set ExRet;
drop i _freq_ _stat_ _type_ date;
where _stat_= 'MEAN';
run;


%Standard_Deviation(&returns,
							dateColumn= &dateColumn, 
							outStdDev= _tempStd);


data _tempVals;
set _tempExRet _tempStd;
run;

proc sql noprint;
select name
	into :Sharpe separated by ' '
	from sashelp.vcolumn
	where libname = upcase("work")
	  and memname = upcase("_tempVals")
	  and type = "num";
quit;

data _tempSharpe (drop= i);
set _tempVals;

array Sharpe[*] &Sharpe;

do i= 1 to dim(Sharpe);
Sharpe[i]= lag(Sharpe[i])/Sharpe[i];
end;

data &outSharpe;
		retain stat;
	set _tempSharpe end= last;
stat= 'SharpeRatio';
if last; 
run;


proc datasets lib=work nolist;
	delete &returns ExRet _tempExRet _tempRP _tempStd _tempVals _tempSharpe;
run;
quit;

%mend;
