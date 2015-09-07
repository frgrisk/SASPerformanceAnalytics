/*---------------------------------------------------------------
* NAME: table_AnnualizedReturns.sas
*
* PURPOSE: displays annualized summary statistics of return, standard deviation, and sharpe ratio.
*
* NOTES: The annualized returns displayed are the annualized average returns for the period.  
*		 The Sharpe ratio of a desired asset is calculatedgiven returns and a risk free rate.   Option to
* 		 input an unchanging value (0.02) or a variable risk free rate included in a return data set;
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns with option to include risk free rate variable.
* Rf- required.  Either a value or variable representing the Risk Free Rate of Return.
* scale - number of periods per year if Sharpe is annualized.
* method - {LOG, DISCRETE} -- compound or simple returns.  
*          Default=DISCRETE
* dateColumn - Date column in Data Set. Default=DATE
* outTable - output Data Set of annualized returns statistics.  Default="annualized_table".
* printTable - option to print table.  {PRINT, NOPRINT} Default= NOPRINT
*
* MODIFIED:
* 6/10/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro table_AnnualizedReturns(returns,
								Rf= 0,
								scale= 0, 
								method= GEOMETRIC, 
								dateColumn=DATE, 
								outTable= annualized_table, 
								printTable= noprint);

%SharpeRatio_annualized(&returns, 
					  Rf= &Rf, 
					  scale= &scale, 
					  dateColumn= &dateColumn, 
					  method= &method,
					  outSharpe= Sharpe_Ratio);

%return_annualized(&returns, 
							scale= &scale,
							method= &method,
							dateColumn= &dateColumn, 
							outReturnAnnualized= annualized_returns)

%Standard_Deviation(&returns, 
							scale= &scale,
							annualized= TRUE, 
							dateColumn= &dateColumn, 
							outStdDev= _tempStd1);



data &outTable (drop= s Date n);
		retain annualized;
	set annualized_returns _tempStd1 Sharpe_Ratio;
	n=_n_;
	if n=1 then annualized= 'Return';
	if n=2 then annualized= 'StdDev';
	if n=3 then annualized= 'Sharpe';
run;

proc transpose data= &outTable out= _tempTable2(rename= (col1= return) rename= (col2= stdDev) rename= (col3= SharpeRatio));
run;

%to_character(datain= _tempTable2, dataout= _tempTable2, vars= Return stdDev SharpeRatio, formats= percent12.4 percent8.2 8.4, n= 3);
run;

proc transpose data= _tempTable2 out= _tempTable3 name= Annualized;
var _all_;
run;

data charTable;
	set _tempTable3;
	if Annualized= '_NAME_' then delete;
	drop _label_ Date;
run;

%if %upcase(&printTable)= PRINT %then %do;
proc print data= charTable noobs;
run; 
%end;

proc datasets lib=work nolist;
	delete _tempRP _tempStd _meanRet1 Sharpe_Ratio annualized_returns 
			_tempStd1 _tempTable2 _tempTable3 charTable;
run;

%mend;


