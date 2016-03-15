/*---------------------------------------------------------------
* NAME: to_character.sas
*
* PURPOSE: Converts a series of variable from numeric to character.
*
*
* MACRO OPTIONS:
* datain - Required. Data set that contains the data of interest. 
* dataout - Required. Output data set.
* vars - Required. Speficies the variable to be manipulated, separated by single space.
* formats - Required. The desired formats of the variables, also separated by single space.
* n - Required. Total number of variables to be converted. 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro to_character(datain=,dataout=,vars=,formats=,n=);
%local i var fmt;
%do i=1 %to &n;
       %local temp&i;
       %let temp&i = %ranname();
%end;
 
data &dataout(
       rename=(
       %do i=1 %to &n;
             %let var = %scan(&vars,&i,%str( ));
             &&temp&i = &var
       %end;
));
set &datain;
 
%do i=1 %to &n;
       %let var = %scan(&vars,&i,%str( ));
       %let fmt = %scan(&formats,&i,%str( ));
       &&temp&i = strip(put(&var,&fmt));
       label &&temp&i = "&var";
       drop &var;
%end;
run;
%mend;
