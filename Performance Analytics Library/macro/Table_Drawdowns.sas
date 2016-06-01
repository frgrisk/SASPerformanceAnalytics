/*---------------------------------------------------------------
* NAME: Table_Drawdowns.sas
*
* PURPOSE: Display the statistics of the worst drawdowns in a table.
*
* NOTES: The number of drawdowns to be displayed is specified by user. Only one asset can be 
*        calculated at one time. 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* asset - Required. Name of the variable to find drawdown interval for.
* TOP - Required. The number of the drawdowns with worst depth to include.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* digits - Optional. Specifies number of digits displayed in the output. 
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with drawdowns.  Default="TableDrawdowns".
* printTable - Optional. Option to print table.  {PRINT, NOPRINT} Default= NOPRINT
*
* MODIFIED:
* 5/31/2016 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Table_Drawdowns(returns,
							asset=,
							TOP=,
							method= DISCRETE,
							digits= 4,
							dateColumn= DATE,
							outData= TableDrawdowns,
							printTable= NOPRINT);

%local vars nvar ncol find_drawdown dateTable beginTable troughTable endTable;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Table_Drawdowns: (&vars);

%let nvar = %sysfunc(countw(&vars));

%let find_drawdown = %ranname();
%let dateTable = %ranname();
%let ncol = %ranname();
%let beginTable = %ranname();
%let troughTable = %ranname();
%let endTable = %ranname();

%Find_Drawdowns(&returns, asset=&asset, method=&method, dateColumn=&dateColumn, outData=&find_drawdown);

data &dateTable;
	set &returns;
	if _n_ ne 1;
run;

data &dateTable;
	set &dateTable;
	&ncol = _n_;
	keep &dateColumn &ncol;
run;

proc sql noprint;
 create table &beginTable(drop = &ncol) as
  select a.*, b.*
   from &find_drawdown as a left join &dateTable(rename=(&dateColumn=BeginDate)) as b
    on a.begin = b.&ncol;
quit;

proc sql noprint;
 create table &troughTable(drop = &ncol) as
  select a.*, b.*
   from &beginTable as a left join &dateTable(rename=(&dateColumn=TroughDate)) as b
    on a.trough = b.&ncol;
quit;

proc sql noprint;
 create table &endTable(drop = &ncol) as
  select a.*, b.*
   from &troughTable as a left join &dateTable(rename=(&dateColumn=EndDate)) as b
    on a.end = b.&ncol
	 order by return;
quit;

proc sql noprint;
	select count(*)
	into   :nrows
	from   &endTable
	where  return<0;
quit;

data &outData;
	retain BeginDate TroughDate EndDate return length peaktotrough Recovery;
	%if &TOP<&nrows %then %do;
	set &endTable(obs=&TOP);
	%end;
	%else %do;
	set &endTable;
	%end;
	if endDate = . then recovery = . ;
	format return %eval(&digits + 4).&digits;
	rename return=depth peaktotrough=toTrough;
	keep BeginDate TroughDate EndDate return length peaktotrough Recovery;
run;

proc datasets lib = work nolist;
	delete &find_drawdown &dateTable &beginTable &troughTable &endTable;
run;
quit;

%if %upcase(&printTable)= PRINT %then %do;
	proc print data= &outData noobs;
	run; 
%end;
%mend;
