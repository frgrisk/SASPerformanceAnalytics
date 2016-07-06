/*---------------------------------------------------------------
* NAME: create_hash.sas
*
* PURPOSE: Declare a hash object to store and retrieve data.
*
* MACRO OPTIONS:
* name - Required. Specifies the name of the hash object. {ie. name = my_hash}
* key - Required. Lookup keys to initialize hash object. {ie. key = id}
* data_vars - Required. Specifies the data variables which is to be munipulated. {ie. data_vars = salary}
* dataset - Required. Name of the data set. {ie. dataset = "my_data_set"}
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/
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
