/*---------------------------------------------------------------
* NAME: Chart_Scatter.sas
*
* PURPOSE: Create a simple correlation plot matrix with options using a returns data set.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* xvar- required.  Specifies the variable or asset to be plotted on the x-axis.
* yvar- required.  Specifies the variable or asset to be plotted on the y-axis.
* title- required.  Title for Scatter Plot. [Default= xvar versus yvar Scatter]
* grid- option.  Overlay a grid aligned with the points on the x and y axis.
* transparency- option.  Specifies the level of transparency for data symbols.
* color- option to change the color of the scatter plot points [Default= carolina blue]
* symbol- option to change the symbol of the scatter plot points [Default= circle] See list of possible symbols at SAS product documentation (markerattrs symbol)
* size- option to change the size (in pixels) of the plot points [Default= 6]
* regLine- option to overlay a regression line on the scatter plot. {TRUE, FALSE}
* cl- option.  If regLine= TRUE, option to create confidence limits for the regression line. {CLM, CLI}
* degree- option.  If regLine= TRUE, specifies linear or quadratic fit.  For linear, degree=1, for quadratic, degree=2.
* ellipse- option to add a predictive ellipse to scatter plots [Default= FALSE] {True, False}
* ellipseType- if ellipse is overlayed, specifies type [Default= predicted] {mean, predicted}
* alpha- if ellipse is overlayed, specifies value of alpha for predictive bands [Default= 0.05]
* dateColumn- specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 1/20/2016 – CJ - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro chart_scatter(returns, 
							xvar=, 
							yvar=, 
							title= &xvar versus &yvar Scatter,
							grid= FALSE,
							transparency= 0.35,
							color= cornflowerblue,
							size= 6,
							symbol= circle,
							regLine= FALSE,
							cl= CLI,
							degree= 1,
							alpha= 0.05,
							ellipse= FALSE,
							EllipseType= predicted,
							dateColumn= Date);


PROC SGSCATTER data = &returns;
plot &yvar*&xvar
/reg
%if &grid= TRUE %then %do;
grid
%end;
  markerattrs=(color=&color size= &size symbol= &symbol)
%if &regline= TRUE %then %do;
  reg=(alpha= &alpha &cl degree=&degree)
%end;
   transparency= &transparency

%if &ellipse= TRUE %then %do;
    ellipse=(alpha= &alpha type=&EllipseType)
%end;
;
 title "&title";
run;

%mend chart_scatter;