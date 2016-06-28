# SAS-Performance-Analytics
`PerformanceAnalytics` provides a package of macro functions on SAS for portfolio performance analysis and risk evaluation. This library incorporates academic researches for its users to implement functionalities that exist in R Performance Analytics package, but had no equivalent in SAS. This package aims to recreate R equivalent in SAS with a few minor tweaks to improve functionality, but otherwise adhering very closely to `R Performance Analytics`. 

The package consists of more than 100 macros to conduct portfolio performance analysis and investment risk analysis, create summary table and chart of related statistics, and facilitate the implementation with a handful of helper macros.

Most of the macros require a return data set as input, rather than prices (prices data can be transformed into returns data with [return_calculate.sas](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/return_calculate.sas) though). Various calculation in regards to return data is available. For example, accumulate asset daily return in either log or discrete compounding mehtods, calculate annual return give the return data for the past years. Also, common metrics used in industrial and acadamic field can be calculated. Those metrics include Sharpe Ratio, Information Ratio, coefficients from CAPM and FF3 model, upside and downside risk, Pain Ratio, Ulcer Index, etc. 

Not only does the package calculates numbers as needed, it also contains macros to visualized the result in forms of table, graph and chart. Macros with the prefix of `chart_` and `table_` help the users to generate report. Based on user preference, the graph color, title, legend position and other features can be adjusted. User needs to refer to SAS reference documents to find available argument values for those options, which is detailed in each of the macros.

As literature of the subject of performance and risk keeps booming and changing, new thoughts exist to be incorporated in this package in the future. 


Users will have the flexibility to select needed time frequencies, compounding methods along with other customizable options. 

## Installation

The current version is 1.01.
Follow these steps to implement the functionality.

1. Download or clone the latest stable release
   `git clone
    https://github.com/FinancialRiskGroup/SASPerformanceAnalytics`

2. Include SASPerformanceAnalytics
    After downloading the package, the following code needs to be run to create a temporary library `input` every time SAS is opened, unless a permanent SAS library is otherwise saved. `dir` is assigned the path of folder `Performance Analytics Library`. When the initiation is completed, the macros and the data sets under the library will be ready to be called.
```sas
    %let dir=<your path of library>;
    libname input "&dir";
    %include "&dir\macro\\*.sas" /nosource;
```

 [`create SAS tables.sas`](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/setup/create%20SAS%20tables.sas) under folder `setup` provides an example of download stock price and return data from
   online sources. This code is only excutable after the above steps, or SAS does not recognize [`get_stocks.sas`](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/get_stocks.sas) macro.
   `dir` in this file needs to be changed to your own directory as well.


## Features

* The package has been tested on SAS 9.4. It shoule be compatible with other versions of SAS.


## Usage
As described above, the following code needs to be executed to include all the macros. Meanwhile, the prices data set sample is created in temporary work library.
```sas
libname input "&dir";
%include "&dir\macro\*.sas" /nosource;

data prices;
set input.prices;
run;
```
After the package is included, the returns can be calculated by calling [return_calculate.sas](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/return_calculate.sas). Based on the input option, the output data set is still `prices`.

```sas
%return_calculate(prices);
```

Now that we have the returns data set `prices`, we are free to use most of the macros in the package. Below are several examples.

Calculate cumulative return:
```sas
%Return_Cumulative(prices, method= DISCRETE, dateColumn= Date, outData= cumulative_returns);
```

Calculate asset Alpha and Beta from CAPM model:
```sas
%CAPM_Alpha_Beta(prices, BM= SPY, Rf= 0.01/252);
```

Create a chart of cumulative return:
```sas
%Chart_CumulativeReturns(prices, method=LOG, WealthIndex=TRUE);
```

Create a table of annualized return, annualized standard deviation, annualized sharpe ratio:
```sas
%table_Annualized_Returns(prices, Rf= 0.01/252, scale=252);
```


## Documentation

Take a look at the [documentation file](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Doc.docx).
This documentation is bundled with the project, which makes it readily
available for offline reading and provides a useful starting point for
any documentation you want to write about your project.


## Contributing

This package aims to be accessible by public users to meet their various needs. We've tested most of the macros and compared the results with the R equivalent, to ensure the change of every macro input arguments would generate the desired output. There still might be some aspects that have not been covered. Any feedback and contribution are welcomed to be discussed to help better calibrate this package. 

## License

SAS Performance Analytics is licensed under the [MIT license](https://github.com/holinus/SASPerformanceAnalytics/blob/master/LICENSE).



Please contact [mailto: info@frgrisk.com] (mailto:info@frgrisk.com)
