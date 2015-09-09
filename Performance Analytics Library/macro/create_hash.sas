
%macro create_hash(name,key,data_vars,dataset);
declare hash &name(dataset:&dataset);
%local i n d;
%let n=%sysfunc(countw(&key));
rc = &name..definekey(
    %do i=1 %to %eval(&n-1);
    "%scan(&key,&i)",
    %end;
    "%scan(&key,&i)"
);
%let n=%sysfunc(countw(&data_vars));
%do i=1 %to &n;
    %let d=%scan(&data_vars,&i);
    rc = &name..definedata("&d");
%end;
rc = &name..definedone();
%mend;
