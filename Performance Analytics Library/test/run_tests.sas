ods html close;
ods listing close;

options mprint notes;

%let dir= C:\Users\CJohnston\Documents\SASPerformanceAnalytics\Performance Analytics Library;
*%let dir=C:\\Users\\dpazzula\\Documents\\VOR\\SAS_Perf_Anly;


libname input "&dir";

/*Include SASPerformanceAnalytics*/
%include "&dir\macro\*.sas" /nosource;

/*Include test macros*/
%include "&dir\test\macros\*.sas" /nosource;

/*Read tests in from Excel*/
proc import file="&dir\test\tests.xlsx"
		    out=tests
			dbms=xlsx
			replace;
run;

/*Loop and run tests*/
%macro loop_tests();
%local i n;
proc sql noprint;
select count(*) 
	into :n TRIMMED 
	from tests;

%do i=1 %to &n;
	%local test&i;
	%local desc&i;
	%local macro&i;
%end;

select test, description, macro
	into :test1 - :test&n,
	     :desc1 - :desc&n,
		 :macro1 - :macro&n
	from tests;

drop table test_results;
quit;


%do i=1 %to &n;
	%put CALLING &&macro&i;
	%&&macro&i;

	data _temp;
		format test $50. Description $200. Pass $5. Notes $200.;
		test = "&&test&i";
		description = "&&desc&i";
		pass = "&pass";
		notes = "&notes";
	run;

	proc append base=test_results data=_temp force;
	run;

%end;
%mend;

%loop_tests;

/*Export Test Results to Excel*/
proc export data=test_results
			outfile="&dir\_test_results.xlsx"
			dbms=xlsx
			replace;
run;
