/*---------------------------------------------------------------
* NAME: download_yahoo.sas
*
* PURPOSE: Download price data of stocks from yahoo and calculate return.
*
* NOTES: This macro downloads price data. The price output data set is named symbol_p. {ie. IBM_p}
*        On 18 May 2017 the ichart data API of Yahoo! Finance was discontinued and it does not seem
*        like it is coming back. Yahoo! now tries to block automatic requests by requiring 
*        a combination of a cookie and a crumb token. 
*        The following method comes from stackoverflow:
*		 https://stackoverflow.com/questions/44030983/yahoo-finance-url-not-working
*        To make it work, please ensure you have Python successfully installed.
*
* MACRO OPTIONS:
* symbol - Required. Sticker of one stock. {ie.symbol=IBM}
* from - Optional. Starting date (inclusive). {ie. 31DEC2004} [Default = 1 year before today's date]
* to - Optional. Ending data (inclusive). {ie. 01JAN2015} [Default = 1 day before today's date]
* interval - Optional. Specify interval of price data. {ie. mo/wk/d} [Default = mo]
* keepPrice - Optional. Specify whether to keep the price data. {0,1} [Default = 0]
* LogReturn - Optional. Compound or single returns. {0,1} [Default = 1]
* PriceColumn - Optional. Specify the kind of price to be kept. [Default = adj_close]
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro download_yahoo(symbol,from,to,interval=mo,keepPrice=0,LogReturn=1,PriceColumn=adj_close);
/*Builde URL for CSV from Yahoo! Finance*/
%local _crumb _dir;
%let _crumb = %nrbquote('.*"CrumbStore":\{"crumb":"(?P<crumb>[^"]+)"\}');
%let _dir = %sysfunc(pathname(WORK));

filename x "&_dir.\&symbol..py";

data _null_;
format s $256.;

	%if "&from" ^= "" %then %do;
		from = "&from"d;
	%end;
	%else %do;
		from = intnx('year',today(),-1,'same');
	%end;

	%if "&to" ^= "" %then %do;
		to = "&to"d;
	%end;
	%else %do;
		to = today()-1;
	%end;
	
	sDate = catt("sDate=","(",put(year(from),4.),",",strip(put(month(from),best12.)),",",strip(put(day(from),best12.)),")");
	eDate = catt("eDate=","(",put(year(to),4.),",",strip(put(month(to),best12.)),",",strip(put(day(to),best12.)),")");

	s = catt("url = ","'","https://query1.finance.yahoo.com/v7/finance/download/",
			 "&symbol","?","period1={0}","&","period2={1}","&",
			 "interval=1","&interval","&","events=history&",
			 "crumb={2}","'",".format(*data)");

	sym = tranwrd("&symbol","-","_");
	call symputx("symbol_name",sym,"g");
	
file x;
	put "import requests";
	put "import re";
	put "import datetime as dt";

	put "url = 'https://uk.finance.yahoo.com/quote/AAPL/history' ";
	put "r = requests.get(url) ";
	put "txt = r.text ";
	put "cookie = r.cookies['B']";
	put "pattern = re.compile(&_crumb)";

	put "for line in txt.splitlines():";
	put "    m = pattern.match(line)";
	put "    if m is not None:";
	put "        crumb = m.groupdict()['crumb'] ";

	put sDate;
	put eDate;
	put "dt.datetime(*sDate).timestamp()";
	put "data = (int(dt.datetime(*sDate).timestamp()),";
	put "		int(dt.datetime(*eDate).timestamp()), ";
	put "		crumb)";

	put s;
	put "data = requests.get(url, cookies={'B':cookie})";
	put "out = data.text";
	put "print(out)";
run;

filename f1 pipe "python ""&_dir.\&symbol_name..py"" ";

data &symbol_name(rename=(&PriceColumn=&symbol_name));
	informat Date yymmdd10.;
	format Date date9. Open High Low Close Adj_Close Volume best12.;
	infile f1 DLM=',' DSD missover FIRSTOBS=2;
	input Date Open High Low Close Adj_Close Volume;
	if date = . then delete;
run;


/*Clear the filename to the url*/
filename f1 clear;

/*Delete Python file*/
data _null_;
   rc=fdelete('x');
   put rc=;
run;

filename x clear;

/*Ensure data are sorted*/
proc sort data=&symbol_name(keep=date &symbol_name);
	by date;
run;

%if &keepPrice %then %do;
	data &symbol_name._p;
	set &symbol_name;
	run;
%end;

data &symbol_name;
	set &symbol_name;
	%if &LogReturn %then %do;
		&symbol_name = log(&symbol_name/lag(&symbol_name));
	%end;
	%else %do;
		&symbol_name = &symbol_name/lag(&symbol_name) - 1;
	%end;
run;
%mend;
