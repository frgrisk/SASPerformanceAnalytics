# SAS-Performance-Analytics
`PerformanceAnalytics` provides a package of SAS macros for portfolio performance analysis and risk evaluation. This library incorporates function that exist in the `R Performance Analytics` package, but had no equivalent in SAS. This package aims to replicate the R package with a few minor tweaks to improve functionality, but otherwise adhering very closely to `R Performance Analytics`. 

The package consists of more than 100 macros to conduct portfolio performance analysis and investment risk analysis, create summary tables and charts of related statistics. Users have the flexibility to select needed time frequencies, compounding methods along with other options. 

Most of the macros require a return Data Set as input, rather than prices (prices data can be transformed into returns data with [return_calculate.sas](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/return_calculate.sas)). Various calculations with regards to return data are available. For example, [return_accumulate](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/return_accumulate.sas) accumulates asset daily return in either log or discrete compounding methods, [return_annualized](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/return_annualized.sas) calculates annual return given the historical return data. Also, common metrics can be calculated. Those metrics include Sharpe Ratio, Information Ratio, coefficients from CAPM and FF3 model, upside and downside risk, Pain Ratio, Ulcer Index, etc. 

Not only does the package calculates statistics as needed, it also contains macros to visualize the results as tables and graphs. Macros with the prefix of `chart_` and `table_` help the users generate reports. Based on user preference, the graph color, title, legend position and other features can be adjusted. User needs to refer to [SAS documentation](http://support.sas.com/documentation/index.html) to find available argument values for those options, which are detailed in each of the macros.

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

3. Create stock return data set

 [`create_sas_tables.sas`](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/setup/create%20SAS%20tables.sas) under folder `setup` provides an example of downloading stock price and return data from online sources. 
 Please make sure you have Python 3.5.0 or any version greater than 3.5.0 installed, package `requests`, `re`, and `datetime` are required, and Python must be on PATH to be executed through SAS. 
 This code is only excutable after the above steps are finished, or SAS does not recognize [`get_stocks.sas`](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/get_stocks.sas) macro.
   `dir` in this file needs to be changed to your own directory as well.


## Features

The package has been tested on SAS 9.4. It should be compatible with other versions of SAS.
General tasks of the library include:
* Performance analysis
* Risk analysis
* Summary tabular data
* Charts and graphs


## Usage
As described above, the following code needs to be executed to include all the macros. Meanwhile, the prices data set sample is created in temporary `work` library.
```sas
libname input "&dir";
%include "&dir\macro\*.sas" /nosource;

data prices;
set input.prices;
run;
```
After the package is included, the returns can be calculated by calling [return_calculate.sas](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Library/macro/return_calculate.sas). Based on the input option, the output Data Set is `returns`.
```sas
%return_calculate(prices, updateInPlace=FALSE, outData=returns);
```

Now that we have the returns Data Set `returns`, we are free to use most of the macros in the package. Below are several examples.

* Calculate cumulative return:
```sas
%return_cumulative(returns, method= DISCRETE, dateColumn= Date, outData= cumulative_returns);
```

* Calculate asset Alpha and Beta from CAPM model (the ETF `SPY` is chosen as the benchmark):
```sas
%capm_alpha_beta(returns, BM= SPY, Rf= 0.01/252);
```

* Create a chart of cumulative return. The cumulating method is log. `WealthIndex` option adds a line of returns of 1 dollar over time: 
```sas
%chart_cumulativereturns(returns, method=LOG, WealthIndex=TRUE);
```

* Create a table of annualized return, annualized standard deviation, annualized Sharpe Ratio. `scale` is chosen based on data frequency.
```sas
%table_annualized_returns(returns, Rf= 0.01/252, scale=252);
```


## Documentation

Take a look at the [documentation file](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/Performance%20Analytics%20Doc.docx).
This documentation is bundled with the project, which makes it readily
available for offline reading and provides a useful reference for using the library.


## Contributing

This package aims to be accessible by public users to meet their various needs. We've tested the macros and compared the results with the R equivalent, to ensure the change of every macro input arguments would generate the desired output. There still might be some aspects that have not been covered. Any feedback and contribution are welcomed to help better calibrate this package. 

## License

SAS Performance Analytics is licensed under the [MIT license](https://github.com/FinancialRiskGroup/SASPerformanceAnalytics/blob/master/LICENSE).


