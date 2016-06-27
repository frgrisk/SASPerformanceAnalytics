# SAS-Performance-Analytics
PerformanceAnalytics provides a package of macro functions on SAS for portfolio performance analysis and risk evaluation. This library incorporates academic researches for its users to implement functionalities that exist in R Performance Analytics package, but had no equivalent in SAS. This package aims to recreate R equivalent in SAS with a few minor tweaks to improve functionality, but otherwise adhering very closely to R Performance Analytics. Most of the macros require a return data set as input, rather than prices (prices data can be transformed into returns data with return_calculate.sas though). Users will have the flexibility to select needed time frequencies, compounding methods along with other customizable options. 

## Installation

Follow these steps to implement the functionality.

1. Download or clone the latest stable release
   `git clone
    https://github.com/FinancialRiskGroup/SASPerformanceAnalytics`

2. Include SASPerformanceAnalytics
    After downloading the package, the following code needs to be run to create a temporary library ‘input’ every time SAS is opened, unless a permanent SAS library is otherwise saved. ‘dir’ is assigned the path of folder ‘Performance Analytics Library’. When the initiation is completed, the macros and the data sets under the library will be ready to be called.
```sas
    %let dir=C:\SVN\SAS_Perf_Anly;
    
    libname input "&dir";
    
    %include "&dir\macro\\*.sas" /nosource;
```
3. 'create SAS tables.sas' under folder setup provides an example of download stock price and return data from
   online sources. This code is only excutable after the above step, or SAS does not recognize 'get_stocks.sas'.
   'dir' in this file needs to be changed to your own directory as well.


## Features

* Full support for SAS 9.3, 9.4 and SAS Enterprise Guide 7.1


## Usage

Below is an example of calculating Sharpe Ratio from the price data set 'prices'.
```sas
libname input "&dir";

%include "&dir\macro\*.sas" /nosource;

data prices;
set input.prices;
run;
%return_calculate(prices);
%Sharpe_Ratio(prices, Rf= 0.01/252);
```


## Documentation

Take a look at the [documentation file](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Doc.docx).
This documentation is bundled with the project, which makes it readily
available for offline reading and provides a useful starting point for
any documentation you want to write about your project.


## Contributors

Dominic Pazzula, Carter Johnston, Qiyuan Yang, Ruicheng Ma


## License



## Additional information #

Please contact [mailto: frg] (mailto:mailto@frgrisk.com)
