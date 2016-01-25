/*---------------------------------------------------------------
* NAME: Chart_Regression.sas
*
* PURPOSE: Create a simple regression chart with options using a returns data set.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* xvar- required.  Specifies the variable or asset to be plotted on the x-axis.
* yvar- required.  Specifies the variable or asset to be plotted on the y-axis (a benchmark asset).
* title- required.  Title for Scatter Plot. [Default= xvar versus yvar Regression Plot]
* ExcessReturns- logical.  Option to plot returns in excess of the benchmark rather than returns. {TRUE, FALSE}
* Rf- option.  If excessReturns is true, then specifies the risk free rate as a number or as a benchmark asset [Rf= 0.05, Rf= SPY].
* grid- option.  Overlay a grid aligned with the points on the x and y axis.
* transparency- option.  Specifies the level of transparency for data symbols.
* color- option to change the color of the scatter plot points [Default= carolina blue]
* symbol- option to change the symbol of the scatter plot points [Default= circle] See list of possible symbols at SAS product documentation (markerattrs symbol)
* size- option to change the size (in pixels) of the plot points [Default= 6]
* loess- option to overlay a loess fit to the scatter plot for comparison.  Logical, [Default= false].
* cl- option.  If regLine= TRUE, option to create confidence limits for the regression line. {CLM, CLI}
* degree- option.  If regLine= TRUE, specifies linear or quadratic fit.  For linear, degree=1, for quadratic, degree=2.
* alpha- if ellipse is overlayed, specifies value of alpha for predictive bands [Default= 0.05]
* dateColumn- specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 1/22/2016 – CJ - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro chart_regression(returns, 
							xvar=, 
							yvar=, 
							title= &xvar versus &yvar Regression Plot,
							ExcessReturns= FALSE,
							Rf= 0,
							grid= FALSE,
							transparency= 0.35,
							color= cornflowerblue,
							size= 6,
							symbol= circle,
							loess= FALSE,
							cl= CLI,
							degree= 1,
							alpha= 0.05,
							dateColumn= Date);

%if &ExcessReturns= TRUE %then %do;
%return_excess(&returns, Rf= &Rf, dateColumn= &dateColumn, outReturn= &returns);
%end;

PROC SGSCATTER data = &returns;
plot &yvar*&xvar
/
%if &loess= TRUE %then %do;
loess=(alpha= &alpha degree=&degree &cl lineattrs= (pattern= mediumdash))
%end;

%if &grid= TRUE %then %do;
grid
%end;

markerattrs=(color=&color size= &size symbol= &symbol)
reg=(alpha= &alpha degree=&degree &cl)
transparency= &transparency;
 title "&title";
run;

%mend chart_regression;