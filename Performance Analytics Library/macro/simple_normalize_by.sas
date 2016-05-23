/*---------------------------------------------------------------
* NAME: simple_normalize_by.sas
*
* PURPOSE: Calculates the weights of all values of an variable in each subgroup.
*
* Note: The input data set needs to sorted by &by variable before running this
*       macro.
*
* MACRO OPTIONS:
* data - Required. Data set that contains the data of interest. {ie. data = my_data_set}
* var - Required. Name of the variable to be manipulated.
* by - Required. Speficies the variable that divides data into subgroups.
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro simple_normalize_by(data,var,by);
/*Replace with SQL step so prior sort is not necessary*/
/*proc summary data=&data;*/
/*by &by;*/
/*var &var;*/
/*output out=_temp_summary_by sum=__total;*/
/*run;*/

proc sql noprint;
create table _temp_summary_by as
select &by, sum(&var) as __total
	from &data
	group by &by;
quit;

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
