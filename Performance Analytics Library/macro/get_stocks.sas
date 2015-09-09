
%macro get_stocks(stocks,from,to,keepPrice=0,LogReturn=1,PriceColumn=adj_close);
%local i n;
%let n= %sysfunc(countw(&stocks));
options nosource nonotes nosource2;
%do i=1 %to &n;
	%download(%scan(&stocks,&i,%str( )),&from,&to,keepPrice=&keepPrice,LogReturn=&LogReturn,PriceColumn=&PriceColumn);
%end;
options source notes source2;

data stocks;
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

data returns;
set stocks;
/*%do i=1 %to &n;
   %let stock = %scan(&stocks,&i);
   &stock = log(&stock/lag(&stock));
%end;
drop i;*/
run;

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
