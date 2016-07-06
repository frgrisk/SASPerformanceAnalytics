/*---------------------------------------------------------------
* NAME: Chart_CaptureRatios.sas
*
* PURPOSE: A chart displaying capture ratios against a benchmark.
*
* Note: yaxis=Upside Capture ratio, xaxis=Downside Capture ratio.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns and benchmark.
* BM - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* title - Optional.  Title for chart. [Default= Drawback Chart for &asset]
* AddName - Optional. Option to add name to data points. {TRUE, FALSE} Default=TRUE.
* legend_pos - Optional. Position of key legend. See SAS KEYLEGEND statement for more information. [Default= BOTTOMLEFT]
* grid - Optional. Overlay grid lines on both axiss. [Default= TRUE] 
* xlabel - Optional. Specifies x label. Default=DownCapture
* ylabel - Optional. Specifies y label. Default=UpCapture
* transparency - Optional.  Specifies the level of transparency for data points. [Default= 0.2]
* color - Optional. Change the color of the scatter plot points. Default= cornflowerblue
* linecolor - Optional. Change the color of the reference line. Default= cornflowerblue
* linepattern - Optional. Change the pattern of the reference line. (see Line Attributes and Patterns) Default= shortdash
* linetransparency - Optional.  Specifies the level of transparency for reference line. [Default= 0.2]
* size - Optional. Change the size (in pixels) of the plot points. Default= 6
* symbol - Optional. Change the symbol of the scatter plot points. Default= circle
           See list of possible symbols at SAS product documentation (markerattrs symbol)
* dateColumn - Optional. Specifies the date column for returns in the data set. [Default= DATE]
*
* MODIFIED:
* 6/09/2016 – RM - Initial Creation 
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Chart_CaptureRatios(returns,
								BM=, 
								title=Capture Ratio,
								AddName=TRUE,
								legend_pos= BOTTOMRIGHT,
								grid= TRUE,
								xlabel= DownCapture,
								ylabel= UpCapture,
								transparency= 0.2,
								color= cornflowerblue,
								linecolor= cornflowerblue,
								linepattern= shortdash,
								linetransparency=0.2,
								size= 6,
								symbol= circle,
								dateColumn= DATE);

%local vars capture capture_t;
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN ChartCaptureRatios: (&vars);

%let capture=%ranname();
%let capture_t=%ranname();

%UpDownRatios(&returns, BM=&BM, option=CAPTURE, dateColumn=&dateColumn, outData=&capture); 

proc transpose data=&capture out=&capture_t;
run;

data &capture_t;
	set &capture_t;
	rename col1=UpCapture
		   col2=DownCapture
		   _name_=asset;
run;

PROC sgplot data = &capture_t;
	scatter x=DownCapture y=UpCapture
	/
		%if %upcase(&AddName)=TRUE %then %do;
			DATALABEL=asset
		%end;
		markerattrs = (color = &color)
		markerattrs = (symbol = &symbol size= &size)
		transparency= &transparency
	;
	%if %upcase(&grid)=TRUE %then %do;
		xaxis label = "&xlabel" grid;
		yaxis label = "&ylabel" grid;
	%end;
	lineparm x=1 y=1 slope=1/
		lineattrs=(color=&linecolor pattern=&linepattern)
		transparency=&linetransparency
		legendlabel="reference line";
	keylegend/ border position= &legend_pos;
	title "&title";
run;

proc datasets lib=work nolist;
	delete &capture &capture_t;
run;


%mend;
