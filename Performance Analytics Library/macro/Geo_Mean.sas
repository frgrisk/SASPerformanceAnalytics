/*---------------------------------------------------------------
* NAME: Geo_Mean.sas
*
* PURPOSE: Calculate the geometric mean of an asset.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* dateColumn - Date column in Data Set. Default=DATE
* outGeo - output Data Set with geometric mean. [Default= _geoMean]
* MODIFIED:
* 7/21/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro geo_mean(returns, 	 
					dateColumn=Date,
					outGeo= _geoMean);
%local lib ds z;

/***********************************
*Figure out 2 level ds name of returns
************************************/
%let lib = %scan(&returns,1,%str(.));
%let ds = %scan(&returns,2,%str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;


/*******************************
*Get numeric fields in data set
*******************************/
proc sql noprint;
select name
	into :z separated by ' '
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

proc transpose data=&returns out=_temp;
by &dateColumn;
var &z;
run;

proc sort data=_temp;
by _name_;
run;

proc sql noprint;
create table &outGeo as
select exp(mean(log(1+col1)))-1 as GeoMean,
	   _name_
	from _temp
	where col1^=.
	group by _name_;

proc transpose data= &outGeo out= &outGeo;
id _name_;
run;

data &outGeo;
	retain _name_ &z;
set &outGeo;
run;

proc datasets lib= work nolist;
delete &returns _temp;
run;
quit;
%mend;