%macro simple_normalize(data,var,sum=1);
proc sql noprint;
%local s;
select sum(&var)/&sum format=best32. into :s from &data;
quit;

data &data;
set &data;
&var = &var/&s;
run;
%mend;
