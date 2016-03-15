%macro ranname();
_%sysfunc(putn(%sysfunc(round(%sysevalf(1000000*%sysfunc(ranuni(0))),1)),z6.))
%mend;