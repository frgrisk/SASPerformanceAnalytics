/*---------------------------------------------------------------
* NAME: get_stocks.sas
*
* PURPOSE: Create price and return data of stocks.
*
* NOTES: This is daily price data. Default output data set of price is "prices". Default
*        output data set of return is "returns".
*        This macro manipulates the output data set from download_yahoo.sas
*
* MACRO OPTIONS:
* stocks - Required. Tickers of the stocks. {ie.stocks=IBM GE}
* from - Optional. Starting date (inclusive). {ie. 31DEC2004} [Default = 1 year before today's date]
* to - Optional. Ending data (inclusive). {ie. 01JAN2015} [Default = 1 day before today's date]
* keepPrice - Optional. Specify whether to keep the price data. {0,1} [Default = 0]
* LogReturn - Optional. Compound or single returns. {0,1} [Default = 1]
* PriceColumn - Optional. Specify the kind of price to be kept. [Default = adj_close]
* outReturns - Optional. Output data set with returns. [Default = returns]
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro get_stocks(stocks,from,to,keepPrice=0,LogReturn=1,PriceColumn=adj_close,outReturns=returns);
%local i n;
%let n= %sysfunc(countw(&stocks));
options nosource nonotes nosource2;
%do i=1 %to &n;
	%download_yahoo(%scan(&stocks,&i,%str( )),&from,&to,keepPrice=&keepPrice,LogReturn=&LogReturn,PriceColumn=&PriceColumn);
%end;
options source notes source2;

data &outReturns;
merge &stocks;
by date;
run;

%if &keepPrice %then %do;
   data prices;
   merge
   %do i=1 %to &n;
      %scan(&stocks,&i)_p
   %end;
   ;
   by date;
   run;
%end;

proc datasets lib=work nolist;
delete &stocks 
%if &keepPrice %then %do;
   %do i=1 %to &n;
      %scan(&stocks,&i)_p
   %end;
%end;
;
quit;
%mend;
