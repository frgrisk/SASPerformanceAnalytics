/*---------------------------------------------------------------
* NAME: Chart_Correlation.sas
*
* PURPOSE: Create a simple correlation plot matrix with options using a returns data set.
*
* MACRO OPTIONS:
* returns - required.  Data Set containing returns.
* title- required.  Title for histogram. [Default= asset name]
* histogram - optional.  Option to insert histograms for each asset along the diagonal of the plot matrix.
* histogramDensity - option.  Selects a type of density to overlay on histograms along the diagonal.  [Default= normal] {Normal, Kernel}
* color- option to change the color of the scatter plot points [Default= carolina blue]
* symbol- option to change the symbol of the scatter plot points [Default= circle] See list of possible symbols at SAS product documentation (markerattrs symbol)
* size- option to change the size (in pixels) of the plot points [Default= 6]
* ellipse- option to add a predictive ellipse to scatter plots [Default= FALSE] {True, False}
* ellipseType- if ellipse is overlayed, specifies type [Default= predicted] {mean, predicted}
* alpha- if ellipse is overlayed, specifies value of alpha for predictive bands [Default= 0.05]
* dateColumn- specifies the date column for returns in the data set. [Default= Date]
*
* MODIFIED:
* 1/14/2016 – CJ - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro chart_correlation(returns, 
							title= Portfolio Asset Correlations,
							histogram= FALSE,
							histogramDensity= normal,
							color= cornflowerblue,
							symbol= circle,
							size= 6, 
							ellipse= FALSE, 
							ellipseType= predicted,
							alpha= 0.05,
							dateColumn= Date);

%local vars;
/*Find all variable names excluding the date column and risk free variable*/
%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn); 
%put VARS IN return_calculate: (&vars);

PROC SGSCATTER data = &returns;
MATRIX &vars
/
%if &histogram= TRUE %then %do;
diagonal = (histogram &histogramDensity)
%end;
 markerattrs = (color = &color)
 markerattrs = (symbol = &symbol size= &size)
 %if &ellipse= TRUE %then %do;
 ellipse=(alpha= &alpha type= &ellipseType)
 %end;
 ;
 title "&title";
run;

%mend chart_correlation;