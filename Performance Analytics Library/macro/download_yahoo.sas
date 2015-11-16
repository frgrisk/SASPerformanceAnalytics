%macro download_yahoo(symbol,from,to,keepPrice=0,LogReturn=1,PriceColumn=adj_close);
/*Builde URL for CSV from Yahoo! Finance*/
data _null_;
format s $128.;

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

put FROM= date9. TO= date9.;

to_d = day(to);
to_m = month(to)-1;
to_y = year(to);

from_d = day(from);
from_m = month(from)-1;
from_y = year(from);
s = catt("'http://ichart.finance.yahoo.com/table.csv?s=&symbol",
		'&d=',put(to_m,z2.),
		'&e=',to_d,
		'&f=',put(to_y,4.),
		'&g=d&a=',put(from_m,z2.),
		'&b=',from_d,
		'&c=',put(from_y,4.),
		'&ignore=.csv',
		"'");
call symput("s",s);
sym = tranwrd("&symbol","-","_");
call symputx("symbol_name",sym,"g");
run;

%put URL: &s;
/*SAS Filename to point to the URL*/
filename in url &s;

/*Use PROC IMPORT to download and parse the CSV*/
proc import file=in dbms=csv out=&symbol_name(rename=(&PriceColumn=&symbol_name)) replace;
run;

/*Clear the filename to the url*/
filename in clear;

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