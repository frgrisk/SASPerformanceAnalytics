/*---------------------------------------------------------------
* NAME: Information_Ratio.sas
*
* PURPOSE: calculate the information ratio of a portfolio given returns and a benchmark asset or index.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* scale - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
          Default=1
* VARDEF - Optional. Specify the variance divisor, DF, degree of freedom, n-1; N, number of observations, n. {N, DF} Default= DF.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with information ratio.  Default="Info_Ratio".
*
* MODIFIED:
* 7/13/2015 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
* 5/23/2016 - QY - Add VARDEF parameter
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Information_Ratio(returns,
							BM=,
							scale= 1,
							VARDEF = DF, 
							dateColumn= DATE,
							outData= Info_Ratio);



%local nv ret ap te i;


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
%let i = %ranname();


%ActivePremium(&returns,bm=&bm,scale=&scale,dateColumn=&dateColumn,outData=&ap)
%TrackingError(&returns,bm=&bm,scale=&scale,VARDEF= &VARDEF,dateColumn=&dateColumn,outData=&te,annualized=TRUE)

data &outData(keep=_stat_ &ret);
	format _STAT_ $32.;
	set &te &ap(in=&ap);
	array vars[&nv] &ret;

	_stat_ = "Information_Ratio";

	do &i=1 to dim(vars);
		vars[&i] = vars[&i]/lag(vars[&i]);
	end;

	if &ap;
	drop &i;
run;

proc datasets lib= work nolist;
delete &te &ap;
run;
quit;
%mend;
