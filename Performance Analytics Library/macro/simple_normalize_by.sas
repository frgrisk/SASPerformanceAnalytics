
%macro simple_normalize_by(data,var,by);
proc summary data=&data;
by &by;
var &var;
output out=_temp_summary_by sum=__total;
run;

data &data(drop=__total rc);
set &data;
format __total best.;
if _n_ = 1 then do;
	%create_hash(lk,&by,__total,"_temp_summary_by");
end;

__total = &var;
rc = lk.find();

&var = &var / __total;
run;

proc datasets lib=work nolist noprint;
delete _temp_summary_by;
quit;

%mend;
