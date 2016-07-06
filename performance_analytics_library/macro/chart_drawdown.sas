/*---------------------------------------------------------------
* NAME: Chart_Drawdown.sas
*
* PURPOSE: A chart displaying drawdowns through time, given a return data set.
*
* Note: Multiple assets can be assigned in this macro. For example, drawdowns of IBM/GE/DOW can be 
*		shown on the chart at the same time.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* asset - Required. Name of the variable to plot drawdown chart for. Asset names are separated by space.
*		  {e.g. asset=IBM GE DOW}
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.  
           [Default=DISCRETE]
* title - Optional.  Title for chart. [Default= Drawback Chart for &asset]
* grid - Optional. Overlay grid lines on the returns axis. [Default= TRUE] 
* Interval - Optional.  Specifies the frequency of grid lines overlayed on the returns axis. [Default= -0.1 (-10%)]
* linecolor - Optional. Specifies the color of the lines. See SAS COLOR NAMES for reference. 
*             {e.g. for three assets, linecolor=GOLD BLACK RED} [Default: automatically assigned by SAS] 
* legend_pos - Optional. Position of key legend. See SAS KEYLEGEND statement for more information. [Default= BOTTOMLEFT]
* dateColumn - Optional. Specifies the date column for returns in the data set. [Default= DATE]
*
* MODIFIED:
* 6/01/2016 – RM - Initial Creation 
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Chart_Drawdown(returns,
							asset=,
							method= DISCRETE,
							title= Drawback Chart for &asset,
							grid= TRUE,
							Interval= -0.1,  
							linecolor= ,
							legend_pos= BOTTOMRIGHT,
							dateColumn= DATE);

%local vars i Nasset nDate nDrawdown ret_drawdowns both ;
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Chart_Drawdown: (&asset);
%let Nasset= %sysfunc(countw(&asset));
%let i= %ranname();

%let ret_drawdowns = %ranname();
%let nDate = %ranname();
%let nDrawdown = %ranname();
%let both = %ranname();

%Drawdowns(&returns, method= &method, dateColumn= DATE, outData=&ret_drawdowns);

data &nDrawdown;
	set &ret_drawdowns;
	&nDrawdown = _n_;
run;

data &nDate;
	set &returns;
	&nDate = _n_;
	keep &dateColumn &nDate;
run;

proc sql noprint;
 create table &both(drop=&nDrawdown &nDate) as 
  select a.*, b.*
   from &nDrawdown as a, &nDate as b
    where a.&nDrawdown = b.&nDate;
quit;

proc sgplot data=&both;
    %do &i=1 %to &Nasset;
	series x = &dateColumn y = %sysfunc(scan(&asset,&&&i))
		/
		%if &linecolor ^=   %then %do;
		lineattrs=(color=%sysfunc(scan(&linecolor,&&&i)))
		%end;
		;
	%end;
	title "&title";
	xaxis label = 'Date' type = time;
	yaxis label = 'Drawdown' 
		%if &grid= TRUE %then %do;
		grid values= (0 to -10 by &interval) valueshint valuesformat= best12.
	    %end;
	;
keylegend/ border position= &legend_pos title= "Asset Name";
run;

proc datasets lib=work nolist;
	delete &nDate &nDrawdown &ret_drawdowns &both;
run;

%mend Chart_Drawdown;
