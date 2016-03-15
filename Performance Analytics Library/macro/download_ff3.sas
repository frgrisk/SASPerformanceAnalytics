/*---------------------------------------------------------------
* NAME: download_ff3.sas
*
* PURPOSE: Download ff3 factors from online source.
*
* MACRO OPTIONS:
* outData - Required. Output data set.
* 
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro download_ff3(outData=ff3);
   
%local fn rsp ff;

%let fn = %ranname()._zip;
%let rsp = %ranname();
%let ff = %ranname();

filename &rsp "&fn";

proc http method="GET"
	url="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_daily_CSV.zip"
	out=&rsp;
quit;

filename &ff zip "&fn";

data &outData;
infile &ff(F-F_Research_Data_Factors_daily.CSV) delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=1 ;
   informat Date  yymmdd8.;
   informat Mkt_RF best32. ;
   informat SMB best32. ;
   informat HML best32. ;
   informat RF best32. ;
   format Date date9. ;
   format Mkt_RF best12. ;
   format SMB best12. ;
   format HML best12. ;
   format RF best12. ;
input
            Date
            Mkt_RF
            SMB
            HML
            RF
;

if ^missing(date);

array vars[4] Mkt_RF
            SMB
            HML
            RF;
do i=1 to 4;
	vars[i] = vars[i]/100;
end;
drop i;

run;

filename &rsp clear;
filename &ff clear;
%mend;
