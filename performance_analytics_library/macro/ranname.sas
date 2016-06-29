/*---------------------------------------------------------------
* NAME: ranname.sas
*
* PURPOSE: Generate a random name in the form of "_123456", which consists an underscore and a 6-digit number.
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
%macro ranname();
_%sysfunc(putn(%sysfunc(round(%sysevalf(1000000*%sysfunc(ranuni(0))),1)),z6.))
%mend;
