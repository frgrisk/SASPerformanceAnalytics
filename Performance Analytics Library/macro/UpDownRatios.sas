/*---------------------------------------------------------------
* NAME: UpDownRatios.sas
*
* PURPOSE: Calculate asset up/down capture/number/percent ratios against benchmark.
*
* NOTES: In calculating up/down capture ratio, the return is compounded arithmatically.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns and benchmark.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* option - Optional. Specifies which ratio to be calculated. If not specified, all three ratios will be displayed.
		   Defaulted as blank.
* side - Optional. Specifies up/down market statistics. If not specified, both up and down market will be calculated.
		   Defaulted as blank.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with up-down ratios.  Default="UpDownRatios".
*
*
* MODIFIED:
* 6/7/2015 – RM - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro UpDownRatios(returns,
							BM=, 
							option= ,
							side= ,
							dateColumn= DATE,
							outData= UpDownRatios);

%local vars nvars upcapture downcapture upnumber downnumber uppercent downpercent i;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN UpDownRatios: (&vars);

%let nvars = %sysfunc(countw(&vars));
%let upcapture=%ranname();
%let downcapture=%ranname();
%let upnumber=%ranname();
%let downnumber=%ranname();
%let uppercent=%ranname();
%let downpercent=%ranname();
%let all=%ranname();
%let i=%ranname();

/*Up Capture*/
data &upcapture;
	set &returns(firstobs=2) end=eof;
	array vars[*] &vars;
	array sum[&nvars] (&nvars*0);

	do &i=1 to &nvars;
		if &BM<=0 then vars[&i]=0;
		sum[&i]=sum[&i]+vars[&i];
		vars[&i]=sum[&i];
	end;
	if eof then output;
	keep &vars;
run;

data &upcapture;
	format _stat_ $32.;
	set &upcapture;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=vars[&i]/&BM;
	end;
	_stat_="Up Capture";
	drop &i;
run;

/*Down Capture*/
data &downcapture;
	set &returns(firstobs=2) end=eof;
	array vars[*] &vars;
	array sum[&nvars] (&nvars*0);

	do &i=1 to &nvars;
		if &BM>0 then vars[&i]=0;
		sum[&i]=sum[&i]+vars[&i];
		vars[&i]=sum[&i];
	end;
	if eof then output;
	keep &vars;
run;

data &downcapture;
	format _stat_ $32.;
	set &downcapture;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=vars[&i]/&BM;
	end;
	_stat_="Down Capture";
	drop &i;
run;

/*Up Number*/
data &upnumber;
	set &returns(firstobs=2) end=eof;
	array vars[*] &vars;
	array sum[&nvars] (&nvars*0);

	do &i=1 to &nvars;
		if vars[&i]>0 and &BM>0 then do;
			sum[&i]=sum[&i]+1;
		end;
		vars[&i]=sum[&i];
	end;
	if eof then output;
	keep &vars;
run;

data &upnumber;
	format _stat_ $32.;
	set &upnumber;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=vars[&i]/&BM;
	end;
	_stat_="Up Number";
	drop &i;
run;

/*Down Number*/
data &downnumber;
	set &returns(firstobs=2) end=eof;
	array vars[*] &vars;
	array sum[&nvars] (&nvars*0);

	do &i=1 to &nvars;
		if vars[&i]<0 and &BM<0 then do;
			sum[&i]=sum[&i]+1;
		end;
		vars[&i]=sum[&i];
	end;
	if eof then output;
	keep &vars;
run;

data &downnumber;
	format _stat_ $32.;
	set &downnumber;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=vars[&i]/&BM;
	end;
	_stat_="Down Number";
	drop &i;
run;


/*Up Percent*/
data &uppercent;
	set &returns(firstobs=2) end=eof;
	array vars[*] &vars;
	array sum[&nvars] (&nvars*0);
	retain BMsum 0;
	if &BM>0 then BMsum=BMsum+1;
	do &i=1 to &nvars;
		if vars[&i]>&BM and &BM>0 then do;
			sum[&i]=sum[&i]+1;
		end;
		vars[&i]=sum[&i];
	end;
	&BM=BMsum;
	if eof then output;
	keep &vars;
run;

data &uppercent;
	format _stat_ $32.;
	set &uppercent;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=vars[&i]/&BM;
	end;
	&BM=0;
	_stat_="Up Percent";
	drop &i;
run;

/*Down Percent*/
data &downpercent;
	set &returns(firstobs=2) end=eof;
	array vars[*] &vars;
	array sum[&nvars] (&nvars*0);
	retain BMsum 0;
	if &BM<0 then BMsum=BMsum+1;
	do &i=1 to &nvars;
		if vars[&i]>&BM and &BM<0 then do;
			sum[&i]=sum[&i]+1;
		end;
		vars[&i]=sum[&i];
	end;
	&BM=BMsum;
	if eof then output;
	keep &vars;
run;

data &downpercent;
	format _stat_ $32.;
	set &downpercent;
	array vars[*] &vars;

	do &i=1 to &nvars;
		vars[&i]=vars[&i]/&BM;
	end;
	&BM=0;
	_stat_="Down Percent";
	drop &i;
run;

/*output*/
data &outData;
	set 
	%if %upcase(&option)=CAPTURE or %upcase(&side)=UP %then %do;
		&upcapture
	%end;
	%if %upcase(&option)=CAPTURE or %upcase(&side)=DOWN %then %do;
		&downcapture
	%end;
	%if %upcase(&option)=NUMBER or %upcase(&side)=UP %then %do;
		&upnumber
	%end;
	%if %upcase(&option)=NUMBER or %upcase(&side)=DOWN %then %do;
		&downnumber
	%end;
	%if %upcase(&option)=PERCENT or %upcase(&side)=UP %then %do;
		&uppercent
	%end;
	%if %upcase(&option)=PERCENT or %upcase(&side)=DOWN %then %do;
		&downpercent
	%end;
	%if &option= and &side= %then %do;
		&upcapture &downcapture &upnumber &downnumber &uppercent &downpercent
	%end;
	;
run;

proc datasets lib = work nolist;
	delete &upcapture &downcapture &upnumber &downnumber &uppercent &downpercent;
run;
quit;

%mend;
