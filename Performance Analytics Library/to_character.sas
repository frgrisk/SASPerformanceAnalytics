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