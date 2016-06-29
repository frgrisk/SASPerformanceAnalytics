/*---------------------------------------------------------------
* NAME: download_FRED.sas
*
* PURPOSE: Download economic data from FRED.
*
* NOTES: This macro downloads specified economic data from FRED.
*
* MACRO OPTIONS:
* symbol - Required. Sticker of one stock. {ie.symbol=DGS10}
* from - Required. Starting date (inclusive). {ie. 31DEC2004} [Default = 1 year before today's date]
* to - Required. Ending data (inclusive). {ie. 01JAN2015} [Default = 1 day before today's date]
* 
* MODIFIED:
* 06/24/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro download_FRED(symbol,from=,to=);
/*Builde URL for CSV from FRED*/

data _null_;
	format s $128.;
	s = catt("'https://research.stlouisfed.org/fred2/series/&symbol/downloaddata/&symbol..csv'");
	call symput("s",s);
	sym = tranwrd("&symbol","-","_");
	call symputx("symbol_name",sym,"g");
run;

%put URL: &s;

/*SAS Filename to point to the URL*/
filename in url &s;

/*Use PROC IMPORT to download and parse the CSV*/
proc import file=in dbms=csv out=&symbol_name(rename=(value=&symbol_name)) replace;
run;

/*Clear the filename to the url*/
filename in clear;

/*Ensure data are sorted*/
proc sort data=&symbol_name(keep=date &symbol_name);
by date;
run;

data _null_;
	%if "&from" = "" %then %do;
		from = intnx('year',today(),-1,'same');
		call symputx("from",put(from,date9.));
	%end;

	%if "&to" = "" %then %do;
		to = today()-1;
		call symputx("to",put(to,date9.));
	%end;
run;

data &symbol_name;
	set &symbol_name;
	where date between "&from"d and "&to"d;
run;

%put DATE: &from-&to;

%mend;
