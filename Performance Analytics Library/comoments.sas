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
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro comoments(returns,
						dateColumn= Date, 
						outCoSkew= M3, 
						outCoKurt= M4);

%local lib ds;

%let lib= %scan(&returns, 1, %str(.));
%let ds= %scan(&returns, 2, %str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;

data &returns;
set &returns;
drop Date;
run;

proc iml;
use &returns;
read all var _num_ into T;
close &returns;

n=ncol(T);
r=nrow(T);
M3 = j(n, n*n);
begCol = 1;
endCol = n;
mean = mean(T);
idx = 1:(r-1);
meanT= mean(T);
Ti= T- meanT;
  S=j(n,n);
       	do j=1 to n;
		Tvector= Ti[idx, j];
        Tj = (T[idx,j] - mean[j]);
            do k=1 to n;    
                     Tk = (T[idx,k] - mean[k]);    
                     s[k,j]= sum(Tvector#Tj#Tk)/(r-1);
					 
            end;
     	end;
  M3[,begCol:endCol]=S;
  begCol=endCol+1;
  endCol=endCol+n;

create M3 from S;
append from S;
close M3;
quit;

proc iml;
use &returns;
read all var _num_ into T;
close &returns;

n=ncol(T);
r=nrow(T);
M4 = j(n**4,5,0);
X= j(n**4,5,0);
begCol = 1;
endCol = n;
mean = mean(T);
idx = 1:(r-1);
  S=j(n,n);
  	do i= 1 to n;
		Ti= T[idx, i]- mean[i];
    		do j=1 to n;
        		Tj = T[idx,j]- mean[j];
					do k=1 to n;
						Tk= T[idx,k]- mean[k];
            				do l=1 to n;    
                     			Tl = T[idx,l]- mean[l]; 
 								rowIndex= (i-1)*(n**3)+(j-1)*(n**2)+(k-1)*n+l;
								X[rowIndex, 1]= i;
								X[rowIndex, 2]= j;
								X[rowIndex, 3]= k;
								X[rowIndex, 4]= l;
                     			X[rowIndex, 5]= sum(Ti#Tj#Tk#Tl)/(r-1);

					 		end;
     				end;
			end;
	end;
  M4[,begCol:endCol]=X;
  begCol=endCol+1;
  endCol=endCol+n;

create M4 from X;
append from X;
close M4;
quit;

data M4;
set M4;
rename col1= i;
rename col2= j;
rename col3= k;
run;

data M4;
set M4;
if i^=j then delete;
if i^=k then delete;
if j^=k then delete;
drop i j k col4;
run;

proc iml;
use M4;
read all var _num_ into T;
close M4;

n=ncol(T);
r=nrow(T);
vshape= r##(1/2);
w= shape(T,vshape,vshape);
w_t= w`;

create M4 from w_t;
append from w_t;
close w_t;
quit;

proc sql noprint;
	create table names as 
		select name
	from sashelp.vcolumn
	where libname = upcase("&lib")
	  and memname = upcase("&ds")
	  and type = "num"
	  and upcase(name) ^= upcase("&dateColumn");
quit;

data M3;
set M3;
n= _n_;
run;

data names;
set names;
n= _n_;
run;

data M3;
merge M3 names;
by n;
drop n;
run;

proc transpose data= M3 out= &outCoSkew;
id name;
run;

data M4;
set M4;
n= _n_;
run;

data M4;
merge M4 names;
by n;
drop n;
run;

proc transpose data= M4 out= &outCoKurt;
id name;
run;

data &outCoSkew;
set &outCoSkew;
n= _n_;
run;

data &outCoKurt;
set &outCoKurt;
n= _n_;
run;

data &outCoSkew;
merge &outCoSkew names;
by n;
run;

data &outCoKurt;
merge &outCoKurt names;
by n;
run;

data &outCoSkew;
retain name;
set &outCoSkew;
drop _name_ n;
run;

data &outCoKurt;
retain name;
set &outCoKurt;
drop _name_ n;
run;

proc datasets lib= work nolist;
delete names;
run;
%mend;

