/*---------------------------------------------------------------
* NAME: comoments.sas
*
* PURPOSE: Creates co-skewness and co-kurtosis matrices.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* outCoSkew - output co-skewness matrix. [Default= M3]
* outCoKurt - output co-kurtosis matrix. [Default= M4]
* MODIFIED:
* 6/29/2015 – DP - Initial Creation
* 10/1/2015 - CJ - Replaced temporary variable names with random names.  
*				   Changed method of computing Co-Kurtosis matrix to accomodate
* 				   a data set with more than 5 variables.
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro comoments(returns,
						dateColumn= Date, 
						outCoSkew= M3, 
						outCoKurt= M4);
%local vars M3 M4 names;


%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN CoMoments: (&vars);

%let M3= %ranname();
%let M4= %ranname();
%let names= %ranname();

proc iml;
use &returns;
read all var {&vars} into T[colname= names];
close &returns;

n=ncol(T);
r=nrow(T);
M3 = j(n, n*n);
begCol = 1;
endCol = n;
mean = mean(T);
idx = 1:(r-1);
Ti= T- mean(T);
  S=j(n,n);
       	do j=1 to n;
		Tv= Ti[idx, j];
        Tj = (T[idx,j] - mean[j]);
            do k=1 to n;    
                     Tk = (T[idx,k] - mean[k]);    
                     s[k,j]= sum(Tv#Tj#Tk)/(r-1);
					 
            end;
     	end;
  M3[,begCol:endCol]=S;
  begCol=endCol+1;
  endCol=endCol+n;

create &M3 from S[rowname= names];
append from S[rowname= names];
close &M3;
quit;


/*Create M4 matrix*/
proc iml;
use &returns;
read all var {&vars} into T[colname= Names];
close &returns;

n=ncol(T);
r=nrow(T);
M4 = j(n, n*n);
begCol = 1;
endCol = n;
mean = mean(T);
idx = 1:(r-1);
Ti= T- mean(T);
  S=j(n,n);
       	do j=1 to n;
		Tv= Ti[idx, j];
        Tj = (T[idx,j] - mean[j]);
		Tl = (T[idx,j] - mean[j]);
            do k=1 to n;    
                     Tk = (T[idx,k] - mean[k]);    
                     s[k,j]= sum(Tv#Tj#Tk#Tl)/(r-1);
					 
            end;
     	end;
  M4[,begCol:endCol]=S;
  begCol=endCol+1;
  endCol=endCol+n;

create &M4 from S[rowname= Names];
append from S[rowname= Names];
close &M4;
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

proc transpose data=&M3 out= &outCoSkew;
id Names;
run;

data &outCoSkew(drop= _name_ rename= name= Names);
merge &names &outCoSkew;
run;

proc transpose data= &M4 out= &outCoKurt;
id Names;
run;

data &outCoKurt(drop= _name_ rename= name= Names);
merge &names &outCoKurt;
run;

proc datasets lib= work nolist;
delete &names &M3 &M4;
run;
quit;
%mend;

