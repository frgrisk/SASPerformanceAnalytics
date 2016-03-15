/*---------------------------------------------------------------
* NAME: get_number_column_names.sas
*
* PURPOSE: Extract the name of variables from a given data set, excluding some variables
*          specified by user.
*
* MACRO OPTIONS:
* _table - Required. Data set to be manipulated.
* _exclude - Name of variable to be excluded from extracting
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro get_number_column_names (_table=,_exclude=);
/*---------------------------------------------------------------------------
 * Step 0.  Open table
 * -------------------------------------------------------------------------*/
%local numvars varnum i nexc name vartype vars i incl rc;

   %let dsid = %sysfunc(open(&_table.));
   %let numvars = %sysfunc(attrn(&dsid,nvars));
   %let nexc = %sysfunc(countw(&_exclude));
   %let vars=;
/*---------------------------------------------------------------------------
 * Step 2.  Loop through variables and determine numerics and char
 * -------------------------------------------------------------------------*/

   %do varnum = 1 %to &numvars;
   	  
      %let name = %sysfunc (varname(&dsid,&varnum));
      %let vartype = %sysfunc(vartype(&dsid,&varnum));
	  /*%put &name &vartype;*/
/*---------------------------------------------------------------------------
 * Step 3.  If CHAR - get Label
 * -------------------------------------------------------------------------*/

      %if "&vartype" ne "C" %then %do;
         %let incl = 1;
		 %let i=1;
		 %do %while(&incl and &i <= &nexc);
			%if "%upcase(%scan(&_exclude,&i))" = "%upcase(&name)" %then %do;
				/*%put EXCLUDING: &name -- %scan(&_exclude,&i) &i;*/
				%let incl = %eval(&incl * 0);
			%end;
			%let i = %eval(&i + 1);
		 %end;
		 %if &incl %then %do;
		    %let vars= &vars &name;
		 %end;
      %end;
   %end;

   %let rc = %sysfunc(close(&dsid));
   
   &vars
%mend get_number_column_names;
