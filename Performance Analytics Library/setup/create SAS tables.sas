%let stocks=IBM GE DOW GOOGL SPY;

/*%let dir=C:\Users\dpazzula\Documents\VOR\SASPerformanceAnalytics\Performance Analytics Library;*/
%let dir= C:\Users\CJohnston\Documents\SASPerformanceAnalytics\Performance Analytics Library;

%include "&dir\macro\*.sas" /nosource;

libname out "&dir\test";

%get_Stocks(&stocks,from=31DEC2004,to=01JAN2015,keepPrice=1, priceColumn= adj_close)

proc export outfile="&dir\test\prices.csv"
	        data=prices
			dbms=csv
			replace;
run;

proc import file="&dir\test\edhec.csv"
            out=edhec
			dbms=csv
			replace;
run;

data WORK.MANAGERS    ;
infile "&dir\test\managers.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
   informat Date yymmdd10. ;
   informat HAM1 best32. ;
   informat HAM2 best32. ;
   informat HAM3 best32. ;
   informat HAM4 best32. ;
   informat HAM5 best32. ;
   informat HAM6 best32. ;
   informat EDHEC_LS_EQ best32. ;
   informat SP500_TR best32. ;
   informat US_10Y_TR best32. ;
   informat US_3m_TR best32. ;
   format Date yymmdd10. ;
   format HAM1 best12. ;
   format HAM2 best32. ;
   format HAM3 best12. ;
   format HAM4 best12. ;
   format HAM5 best32. ;
   format HAM6 best32. ;
   format EDHEC_LS_EQ best32. ;
   format SP500_TR best12. ;
   format US_10Y_TR best12. ;
   format US_3m_TR best12. ;
input
            Date
            HAM1
            HAM2 
            HAM3
            HAM4
            HAM5 
            HAM6 
            EDHEC_LS_EQ 
            SP500_TR
            US_10Y_TR
            US_3m_TR
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

proc copy in=work outlib=out;
select prices managers edhec;
run;
