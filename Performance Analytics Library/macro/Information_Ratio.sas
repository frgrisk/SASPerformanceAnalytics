/*---------------------------------------------------------------
* NAME: Information_Ratio.sas
*
* PURPOSE: calculate the information ratio of a portfolio given returns and a benchmark asset or index.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* BM- required.  Names the benchmark asset or index from the data set.
* scale- optional the number of periods in a year (ie daily scale= 252, monthly scale= 12, quarterly scale= 4).
* dateColumn - Date column in Data Set. Default=DATE
* outInformationRatio - output Data Set with information ratio.  Default="Info_Ratio".
*
* MODIFIED:
* 7/13/2015 – CJ - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Information_Ratio(returns,
							BM=,
							scale= 1,
							dateColumn=DATE,
							outInformationRatio=Info_Ratio);



%local lib ds nv ret ap te;


/***********************************
*Figure out 2 level ds name of RETURNS
************************************/
/*%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
%let ds=&lib;
%let lib=work;
%end;
%put lib:&lib ds:&ds;

proc sql noprint;
select name
into :ret separated by ' '
     from sashelp.vcolumn
where libname = upcase("&lib")
 and memname = upcase("&ds")
 and type = "num"
 and upcase(name) ^= upcase("&dateColumn")
and upcase(name) ^= upcase("&bm");
quit;
*/

%let ret = %get_number_column_names(_table=&returns,_exclude=&dateColumn &bm);
%put RET IN Information_Ratio: (&ret);

%let nv = %sysfunc(countw(&ret));
%let te = %ranname();
%let ap = %ranname();


%ActivePremium(&returns,bm=&bm,scale=&scale,dateColumn=&dateColumn,outActivePremium=&ap)
%TrackingError(&returns,bm=&bm,scale=&scale,dateColumn=&dateColumn,outTrackingError=&te,annualized=TRUE)

data &outInformationRatio;
format _stat_ $32.;
set &te &ap(in=&ap);
array vars[&nv] &ret;

_stat_ = "Information_Ratio";

do i=1 to dim(vars);
	vars[i] = vars[i]/lag(vars[i]);
end;

if &ap;
drop i;
run;

proc datasets lib= work nolist;
delete &te &ap;
run;
quit;
%mend;