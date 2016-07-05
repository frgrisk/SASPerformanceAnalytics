/*---------------------------------------------------------------
* NAME: scalar_annualized.sas
*
* PURPOSE: Annualized a scalar value.  Returns the value inline.
*
* MACRO OPTIONS:
* value  - Required. Value to be annualized
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           Default=DISCRETE
* scale  - Optional. Number of periods in a year {any positive integer, ie daily scale= 252, monthly scale= 12, quarterly scale= 4}.
           Default=1
* type   - Optional. Specifies if the value is a {VALUE, STD}.  VALUE are annualized using METHOD.  STD are annualized by sqrt(SCALE)
*
* MODIFIED:
* 03/16/2016 – DP - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro scalar_annualized(value,scale=1,method=DISCRETE,type=VALUE);
%if %upcase(&type) = VALUE %then %do;
	%if %upcase(&method) = DISCRETE %then %do;
		%sysevalf( (1+&value)**(&scale) - 1);
	%end;
	%else %if %upcase(&method) = LOG %then %do;
		%sysevalf( (&value)*(&scale));
	%end;
%end;
%else %if %upcase(&type) = STD %then %do;
	%sysevalf((&value)*%sysfunc(sqrt(&scale)));
%end;
%else %do;
	.;
%end;
%mend;
