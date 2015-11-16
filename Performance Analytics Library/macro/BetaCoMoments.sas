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
* 10/1/2015 - CJ - Replaced temporary variables and data sets with random names.
*				   Used "vecdiag" to convert matrix to vector form in IML rather than 
*				   conducting this step using an array data step.
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro BetaCoMoments(returns, 
						dateColumn= Date,
						outBetaCoVar= BetaM2,
						outBetaCoSkew= BetaM3, 
						outBetaCoKurt= BetaM4);

%local vars CoSkew CoKurt BetaCoSkew BetaCoKurt BetaCoVar names;


%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN CoMoments: (&vars);

%let CoSkew= %ranname();
%let CoKurt= %ranname();
%let BetaCoSkew= %ranname();
%let BetaCoKurt= %ranname();
%let BetaCoVar= %ranname();
%let anova= %ranname();
%let Names= %ranname();


%comoments(&returns, outCoSkew= &CoSkew, outCoKurt= &CoKurt);
proc iml;
use &CoSkew;
read all var _num_ into D[colname= Names];
close &CoSkew;
c= vecdiag(D);

betaskew= D/c;

create &BetaCoSkew from betaskew[rowname= Names];
append from betaskew[rowname= Names];
close &BetaCoSkew;

use &CoKurt;
read all var _num_ into F[colname= Names];
close &CoKurt;
g= vecdiag(F);

betakurt= F/g;

create &BetaCoKurt from betakurt[rowname= Names];
append from betakurt[rowname= Names];
close &BetaCoKurt;
quit;


%let lib= %scan(&returns, 1, %str(.));
%let ds= %scan(&returns, 2, %str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;

proc sql noprint;
	create table &names as 
		select name
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

proc transpose data= &BetaCoSkew out= &BetaCoSkew;
id Names;
run;

data &outBetaCoSkew(drop= _name_ rename= name= Names);
merge &Names &BetaCoSkew;
run;

proc transpose data= &BetaCoKurt out= &BetaCoKurt;
id Names;
run;

data &outBetaCoKurt(drop= _name_ rename= name= Names);
merge &Names &BetaCoKurt;
run;

proc corr data=&returns noprob outp=&anova noprint 
          nomiss
          cov; 
var &vars;
run;

proc iml;
use &anova where(_type_= "COV");
read all var _num_ into cov[colname= Names];
close &anova;
p= vecdiag(cov);

betacov= cov/p;

create &BetaCoVar from betacov[rowname= Names];
append from betacov[rowname= Names];
close &BetaCoVar;
quit;

proc transpose data= &BetaCoVar out= &BetaCoVar;
id Names;
run;

data &outBetaCoVar(drop= _name_ rename= name= Names);
merge &Names &BetaCoVar;
run;

proc transpose data= &outBetaCoVar out= &outBetaCoVar name= Names;
id Names;
run;
proc transpose data= &outBetaCoSkew out= &outBetaCoSkew name= Names;
id Names;
run;
proc transpose data= &outBetaCoKurt out= &outBetaCoKurt name= Names;
id Names;
run;

proc datasets lib= work nolist;
delete &anova &CoSkew &CoKurt &BetaCoSkew &BetaCoKurt &BetaCoVar &names;
run;
quit;
%mend;