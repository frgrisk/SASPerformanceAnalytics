/*---------------------------------------------------------------
* NAME: Find_Drawdowns.sas
*
* PURPOSE: Calculate the drawdown levels in a timeseries
*
* NOTES: 
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns with option to include risk free rate variable.
* method - Optional. Specifies either DISCRETE or LOG chaining method {DISCRETE, LOG}.    
*          Default=DISCRETE
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outData - Optional. Output Data Set with drawdowns.  Default="drawdowns".
*
* MODIFIED:
* 5/27/2016 – QY - Initial Creation
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro Find_Drawdowns(returns,
							assetName=,
							method= DISCRETE,
							dateColumn= DATE,
							outData= FindDrawdowns);

%local vars nvar ret_drawdown ret_drawdown2;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn);
%put VARS IN Find_Drawdowns: (&vars);

%let nvar = %sysfunc(countw(&vars));

/*%let first_drawdown= %ranname();*/
%let ret_drawdown= %ranname();
%let ret_drawdown2= %ranname();
/*%let both= %ranname();*/

%Drawdowns(&returns, method= &method, dateColumn= DATE, outData=&ret_drawdown)

/*data &first_drawdown;*/
/*	set &ret_drawdown(keep=&dateColumn &assetName obs=1);*/
/*	first_sign = sign(&assetName);*/
/*	first_sofar = &assetName;*/
/*	from = 1;*/
/*	to = 1;*/
/*	dmin = 1;*/
/*	first_index = 1;*/
/*run;*/
/**/
/*data &both;*/
/*	set &first_drawdown &ret_drawdown(keep=&dateColumn &assetName);*/
/*run;*/

data &ret_drawdown &ret_drawdown2;
	set &ret_drawdown(firstobs=2) end=eof;
	
	retain prior_sign sofar from 1 to 1 dmin 1 index 1;
					
	if _n_ = 1 then do;
		prior_sign = sign(&assetName);
		sofar = &assetName;
	end;

	current_sign=sign(&assetName);

	if current_sign = prior_sign then do;
		if &assetName < sofar then do;
			sofar = &assetName;
			dmin = _n_;
		end;
		to = _n_+1;
	end;
	else do;
		return = sofar;
		begin = from;
		trough = dmin;
		end = to;

		from = _n_;
		sofar = &assetName;
		to = _n_+1;
		dmin = _n_;
		index = index+1;
		prior_sign = current_sign;
	end;
	
	if eof then do;
		output &ret_drawdown2;
	end;

	length = end - begin + 1;
	peaktotrough = trough - begin + 1;
	recovery = end - trough;

	output &ret_drawdown;
run;

data &ret_drawdown2;
	set &ret_drawdown2;
	return = sofar;
	begin = from;
	trough = dmin;
	end = to;
	length = end - begin + 1;
	peaktotrough = trough - begin + 1;
	recovery = end - trough;

	keep return begin trough end length peaktotrough recovery;
run;

data &outData;
	set &ret_drawdown;

	retain lag_index 0;
	if lag_index ne index then do;
		output;
	end;
	lag_index = index;
	keep return begin trough end length peaktotrough recovery;
run;

data &outData;
	set &outData &ret_drawdown2;
run;

data &outData;
	set &outData;
	if return ne . then do;
		output;
	end;
run;

proc datasets lib=work nolist;
	delete &ret_drawdown &ret_drawdown2;
run;
quit;

%mend;
