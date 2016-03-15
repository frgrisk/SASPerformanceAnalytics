/*---------------------------------------------------------------
* NAME: Chart_Regression.sas
*
* PURPOSE: Create a simple regression chart with options using a returns data set.
*
* MACRO OPTIONS:
* returns - Required. Data Set containing returns with option to include risk free rate variable.
* xvar - Required.  Specifies the variable or asset to be plotted on the x-axis.
* yvar - Required.  Specifies the variable or asset to be plotted on the y-axis (a benchmark asset).
* title - Optional.  Title for Scatter Plot. [Default= xvar versus yvar Regression Plot]
* ExcessReturns - Optional.  Option to plot returns in excess of the benchmark or a risk free rate. {TRUE, FALSE} [Default= FALSE]
* Rf - Optional.  If excessReturns is true, then specifies the risk free rate as a number or as a benchmark asset {Rf= 0.05, Rf= SPY}
       [Default= 0]
* grid- Optional.  Overlay a grid aligned with the points on the x and y axis. {TRUE,FALSE} [Default= TRUE]
* transparency - Optional.  Specifies the level of transparency for data symbols. [Default= 0.35]
* color - Optional. Change the color of the scatter plot points. [Default= cornflowerblue]
* symbol - Optional. Change the symbol of the scatter plot points.
          See list of possible symbols at SAS product documentation (markerattrs symbol). [Default= circle]
* size - Optional. Change the size (in pixels) of the plot points. [Default= 6]
* loess - Optional. To overlay a loess fit to the scatter plot for comparison.  Logical, {TRUE,FALSE}. [Default= FALSE].
* cl - Optional.  If regLine= TRUE, option to create confidence limits for the regression line. {CLM, CLI}. [Default= CLI]
* degree - Optional.  If regLine= TRUE, specifies linear or quadratic fit.  For linear, degree=1, for quadratic, degree=2. [Default= 1]
* alpha - Optional. If ellipse is overlayed, specifies value of alpha for predictive bands. [Default= 0.05]
* dateColumn - Optional. Specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 1/22/2016 – CJ - Initial Creation
* 3/05/2016 – RM - Comments modification 
* 3/09/2016 - QY - parameter consistency
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro chart_regression(returns, 
							xvar=, 
							yvar=, 
							title= &xvar versus &yvar Regression Plot,
							ExcessReturns= FALSE,
							Rf= 0,
							grid= TRUE,
							transparency= 0.35,
							color= cornflowerblue,
							size= 6,
							symbol= circle,
							loess= FALSE,
							cl= CLI,
							degree= 1,
							alpha= 0.05,
							dateColumn= DATE);

%if &ExcessReturns= TRUE %then %do;
%return_excess(&returns, Rf= &Rf, dateColumn= &dateColumn, outData= &returns);
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
