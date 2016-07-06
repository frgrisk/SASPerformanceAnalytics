/*---------------------------------------------------------------
* NAME: Chart_Scatter.sas
*
* PURPOSE: Create a simple correlation plot matrix with options using a returns data set.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* xvar - Required.  Specifies the variable or asset to be plotted on the x-axis.
* yvar - Required.  Specifies the variable or asset to be plotted on the y-axis.
* title - Optional.  Title for Scatter Plot. [Default= xvar versus yvar Scatter]
* grid - Optional.  Overlay a grid aligned with the points on the x and y axis. {TRUE,FALSE} [Default= FALSE]
* transparency - Optional.  Specifies the level of transparency for data symbols. [Default= 0.35]
* color - Optional. To change the color of the scatter plot points [Default= cornflowerblue]
* symbol - Optional. To change the symbol of the scatter plot points. 
           See list of possible symbols at SAS product documentation (markerattrs symbol). [Default= circle]
* size - Optional. To change the size (in pixels) of the plot points. [Default= 6]
* regLine - Optional. Overlay a regression line on the scatter plot. {TRUE, FALSE}. [Default= FALSE]
* cl - Optional.  If regLine= TRUE, option to create confidence limits for the regression line. {CLM, CLI}. [Default= CLI]
* degree - Optional.  If regLine= TRUE, specifies linear or quadratic fit.  For linear, degree=1, for quadratic, degree=2. [Default= 1]
* ellipse - Optional. Add a predictive ellipse to scatter plots. {True, False}. [Default= FALSE]
* EllipseType - Optional. If ellipse is overlayed, specifies type. {mean, predicted}. [Default= predicted] 
* alpha - Optional. If ellipse is overlayed, specifies value of alpha for predictive bands. [Default= 0.05]
* dateColumn - Optional. Specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 1/20/2016 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro chart_scatter(returns, 
							xvar=, 
							yvar=, 
							title= &xvar versus &yvar Scatter,
							grid= TRUE,
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
							dateColumn= DATE);


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
