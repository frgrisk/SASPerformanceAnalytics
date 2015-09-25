/*---------------------------------------------------------------
* NAME: BetaCoMoments.sas
*
* PURPOSE: Creates Beta covariance, coskewness and cokurtosis matrices.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* dateColumn - Date column in Data Set. Default=DATE
* outBetaCoVar - output beta covariance matrix. [Default= BetaM2]
* outBetaCoSkew - output beta co-skewness matrix. [Default= BetaM3]
* outBetaCoKurt - output beta co-kurtosis matrix. [Default= BetaM4]
* MODIFIED:
* 7/6/2015 – DP - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro BetaCoMoments(returns, 
						dateColumn= Date,
						outBetaCoVar= BetaM2,
						outBetaCoSkew= BetaM3, 
						outBetaCoKurt= BetaM4);

%local lib ds nvar;

%let lib= %scan(&returns, 1, %str(.));
%let ds= %scan(&returns, 2, %str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;


%comoments(&returns);
proc iml;
use M3;
read all var _num_ into D;
close M3;
c= diag(D);

create BetaCoSkewness from c;
append from c;
close c;

use M4;
read all var _num_ into F;
close M4;
g= diag(F);

create BetaCoKurtosis from g;
append from g;
close g;
quit;

proc sql noprint;
select name
	into :vars separated by ' '
	from sashelp.vcolumn
	where libname = upcase("work")
	  and memname = upcase("BetaCoSkewness")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

%let nvar = %sysfunc(countw(&vars));
data BetaCoSkewness(drop= i);
set BetaCoSkewness;
array vars[*] &vars;
array temp[&nvar] _temporary_;

do i=1 to dim(vars);
	vars[i]= sum(vars[i], temp[i]);
	temp[i]= vars[i];
end;

data BetaCoSkewness;
	set BetaCoSkewness end= last;
	if last;
run;

proc transpose data= BetaCoSkewness out= BetaCoSkewness;
var _all_;
run;

proc sql noprint;
create table names as
select name
	into :vars2 separated by ' '
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

data names;
set names;
n= _n_;
run;

data BetaCoSkewness;
set BetaCoSkewness;
n=_n_;
run;

data BetaCoSkewness;
merge BetaCoSkewness names;
by n;
drop _name_;
run;

proc sort data= M3;
by name;
run;

proc sort data= BetaCoSkewness;
by name;
run;

data M3;
merge M3 BetaCoSkewness;
by name;
run;

proc sort data=M3;
by n;
run;

data M3;
set M3;
rename col1= skewness;
run;

proc sql noprint;
select name 
into: ret separated by ' '
from sashelp.vcolumn
where libname = upcase("work")
	  and memname = upcase("M3")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn")
	  and upcase(name) ^= upcase("skewness");
quit;

data M3(drop=i);
		set M3 ;
		array ret[*] &ret;

	do i=1 to dim(ret);
		ret[i]= ret[i]/skewness;
	end;
run;

data M3;
set M3;
drop n;
run;

proc sql noprint;
select name
	into :vars3 separated by ' '
	from sashelp.vcolumn
	where libname = upcase("work")
	  and memname = upcase("BetaCoKurtosis")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

data BetaCoKurtosis(drop= i);
set BetaCoKurtosis;
array variables[*] &vars3;
array temp1[&nvar] _temporary_;

do i=1 to dim(variables);
	variables[i]= sum(variables[i], temp1[i]);
	temp1[i]= variables[i];
end;

data BetaCoKurtosis;
	set BetaCoKurtosis end= last;
	if last;
run;

proc transpose data= BetaCoKurtosis out= BetaCoKurtosis;
var _all_;
run;

data BetaCoKurtosis;
set BetaCoKurtosis;
n=_n_;
run;

data BetaCoKurtosis;
merge BetaCoKurtosis names;
by n;
drop _name_;
run;

proc sort data= M4;
by name;
run;

proc sort data= BetaCoKurtosis;
by name;
run;

data M4;
merge M4 BetaCoKurtosis;
by name;
run;

proc sort data=M4;
by n;
run;

data M4;
set M4;
rename col1= kurtosis;
run;

proc sql noprint;
select name 
into: ret1 separated by ' '
from sashelp.vcolumn
where libname = upcase("work")
	  and memname = upcase("M4")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn")
	  and upcase(name) ^= upcase("kurtosis");
quit;

data M4(drop=i);
		set M4;
		array ret1[*] &ret1;

	do i=1 to dim(ret1);
		ret1[i]= ret1[i]/kurtosis;
	end;
run;

ods select Cov PearsonCorr;
proc corr data=&returns noprob outp=anova
          nomiss
          cov; 
run;

proc iml;
use anova where(_type_= "COV");
read all var _num_ into cov;
close anova;
p= diag(cov);

create BetaCoVariance from p;
append from p;
close p;
quit;

proc sql noprint;
select name
	into :vars5 separated by ' '
	from sashelp.vcolumn
	where libname = upcase("work")
	  and memname = upcase("BetaCoVariance")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

data BetaCoVariance(drop= i);
set BetaCoVariance;
array vars5[*] &vars5;
array temp2[&nvar] _temporary_;

do i=1 to dim(vars5);
	vars5[i]= sum(vars5[i], temp2[i]);
	temp2[i]= vars5[i];
end;

data BetaCoVariance;
	set BetaCoVariance end= last;
	if last;
run;

proc transpose data= BetaCoVariance out= BetaCoVariance;
var _all_;
run;

data BetaCoVariance;
set BetaCoVariance;
n=_n_;
run;

data anova;
set anova;
n=_n_;
run;

data BetaCoVariance;
merge BetaCoVariance names;
by n;
drop _name_;
run;

data anova;
set anova;
rename _name_= name;
run;

proc sort data= anova;
by name;
run;

proc sort data= BetaCoVariance;
by name;
run;

data anova;
merge anova BetaCoVariance;
by name;
run;

proc sort data=anova;
by n;
run;

data anova;
set anova;
rename col1= variance;
run;

proc sql noprint;
select name 
into: ret2 separated by ' '
from sashelp.vcolumn
where libname = upcase("work")
	  and memname = upcase("anova")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn")
	  and upcase(name) ^= upcase("variance");
quit;

data anova(drop=i);
		set anova;
		array ret2[*] &ret2;

	do i=1 to dim(ret2);
		ret2[i]= ret2[i]/variance;
	end;
run;

data &outBetaCoSkew;
set M3;
drop skewness;
drop n;
run;

data &outBetaCoKurt;
set M4;
drop kurtosis;
drop n;
run;

data &outBetaCoVar;
set anova;
if _type_^= "COV" then delete;
drop _type_;
drop variance;
drop n;
run;

proc datasets lib= work nolist;
delete anova M3 M4 names BetaCoSkewness BetaCoVariance BetaCoKurtosis;
run;
quit;

%mend;