% Solution to the market timing homework
clc
clear
close all

% Parameter selection
% Trading lag. 0 means same-day trading, 1 means one day between
% computations and trading
lag = 1;
% Cap for exposure
cap = 2;
% Annualization factor for monthly to annual
annualizationFactor = 12;
% Whether to load the monthly returns from file or compute them
monthlyDataFromFile = 1;


% Load the data
data = xlsread('FFDaily.xls','Sheet1','A2:E25316');
dates = data(:, 1);
nDays = length(dates)
xsReturns = data(:, 2 : 4) / 100;
nAssets = size(xsReturns, 2);
Rf = data(:, 5) / 100;
totalReturns = xsReturns + Rf * ones(1, nAssets);


% Plot cumulative returns using daily returns, both for total and excess returns
% First generate an array for the x-Axis on the plots
dates4Fig = datetime(dates, 'ConvertFrom', 'YYYYMMDD');
% Compute cumulative returns
cumTotalReturns = cumprod(1 + totalReturns);
cumXsReturns = cumprod(1 + xsReturns);
% Plot them
subplot(2, 1, 1), semilogy(dates4Fig, cumTotalReturns(:, 1), 'k-', dates4Fig, cumTotalReturns(:, 2), 'b--', dates4Fig, cumTotalReturns(:, 3), 'r:'), 
    ylabel('Cumulative Total Return'), 
    legend('BM Market', 'BM Size', 'BM Value', 'Location', 'NorthWest')
subplot(2, 1, 2), semilogy(dates4Fig, cumXsReturns(:, 1), 'k-', dates4Fig, cumXsReturns(:, 2), 'b--', dates4Fig, cumXsReturns(:, 3), 'r:'), 
    xlabel('Year'), ylabel('Cumulative Excess Return'), 
    legend('BM Market - Rf', 'BM Size', 'BM Value', 'Location', 'NorthWest') 
set(gcf, 'Position', [200, 200, 800, 600])    

% Obtain monthly return variances to construct portfolio weights
% First, generate arrays listing the first and last day of each month
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);
% Array for the x-axis in the monthly plots
monthlyDates4Fig = dates4Fig(lastDayList);
nMonths = length(firstDayList)
monthlyVar = zeros(nMonths, nAssets);
% Second, compute the return variance from daily returns
for month = 1 : nMonths
    first = max(firstDayList(month) - lag, 1);
    last = lastDayList(month) - lag;
    monthlyVar(month, :) = var(xsReturns(first : last, :));    
end


% Obtain monthly returns. Here, two options
% 1) Load from file
if (monthlyDataFromFile)
    monthlyData = xlsread('FFMonthly.xls', 'Sheet1', 'A2:E1155');
    monthlyDates = monthlyData(:, 1);
    monthlyXsReturns = monthlyData(:, 2 : 4) / 100;
    monthlyRf = monthlyData(:, 5) / 100;
    monthlyTotalReturns = monthlyXsReturns + monthlyRf * ones(1, nAssets);
else
% 2) Aggregate the daily returns 
    monthlyTotalReturns = aggregateReturns(totalReturns, dates, 2);
    monthlyRf = aggregateReturns(Rf, dates, 2);
    monthlyXsReturns = monthlyTotalReturns - monthlyRf * ones(1, nAssets);
end


% Drop the first month from the return series and the last month from the
% variance series to have weights and returns in sync
monthlyDates4Fig = monthlyDates4Fig(2 : nMonths, 1);
monthlyVar = monthlyVar(1 : nMonths - 1, :);
monthlyXsReturns = monthlyXsReturns(2 : nMonths, :);
monthlyTotalReturns = monthlyTotalReturns(2 : nMonths, :);
monthlyRf = monthlyRf(2 : nMonths, 1);
nMonths = nMonths - 1;


% Compute the strategy weights and returns
% In-sample strategy
% Generate the monthly portfolio weights, scaled using avg variance for now 
monthlyWeights = (ones(nMonths, 1) * mean(monthlyVar)) ./ monthlyVar;
monthlyStrategyXsReturns = monthlyXsReturns .* monthlyWeights;

% Rescale the in-sample strategy to match the benchmark unconditional standard deviations
benchmarkStd = std(monthlyXsReturns);
strategyStd = std(monthlyStrategyXsReturns);
scaling = benchmarkStd ./ strategyStd;
monthlyWeights = monthlyWeights .* (ones(nMonths, 1) * scaling);
monthlyStrategyXsReturns = monthlyXsReturns .* monthlyWeights;
monthlyStrategyTotalReturns = monthlyStrategyXsReturns + monthlyRf * ones(1, nAssets);

% Out-of-sample weights and returns
monthlyWeightsOOS = zeros(nMonths, nAssets);
for month = 1 : nMonths
    % Note that one has to use mean( , 1) to make sure the mean is computed columnwise for month = 1 
    monthlyWeightsOOS(month, :) = min(mean(monthlyVar(1 : month, :), 1) ./ monthlyVar(month, :), cap);
end
monthlyStrategyXsReturnsOOS = monthlyXsReturns .* monthlyWeightsOOS;
monthlyStrategyTotalReturnsOOS = monthlyStrategyXsReturnsOOS + monthlyRf * ones(1, nAssets);


% Performance statistics
allMonthlyXsReturns = [monthlyXsReturns, monthlyStrategyXsReturns, monthlyStrategyXsReturnsOOS];
summarizePerformance(allMonthlyXsReturns, monthlyRf, monthlyXsReturns, annualizationFactor, 'Benchmark (3 cols) / Strategy (3 cols) / Strategy OOS (3 cols)');


% Equity lines, using total returns and not excess returns
monthlyBenchmarkNAV = cumprod(1 + monthlyTotalReturns);
monthlyStrategyNAV = cumprod(1 + monthlyStrategyTotalReturns);
monthlyStrategyNAVOOS = cumprod(1 + monthlyStrategyTotalReturnsOOS);
figure
semilogy(monthlyDates4Fig, monthlyBenchmarkNAV(:, 1), 'k-', monthlyDates4Fig, monthlyBenchmarkNAV(:, 2), 'b-', monthlyDates4Fig, monthlyBenchmarkNAV(:, 3), 'r-')
hold on
semilogy(monthlyDates4Fig, monthlyStrategyNAV(:, 1), 'k--', monthlyDates4Fig, monthlyStrategyNAV(:, 2), 'b--', monthlyDates4Fig, monthlyStrategyNAV(:, 3), 'r--'),
semilogy(monthlyDates4Fig, monthlyStrategyNAVOOS(:, 1), 'k-.', monthlyDates4Fig, monthlyStrategyNAVOOS(:, 2), 'b-.', monthlyDates4Fig, monthlyStrategyNAVOOS(:, 3), 'r-.'),
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('BM Market', 'BM Size', 'BM Value', 'Timed Market', 'Timed Size', 'Timed Value', 'Timed Market OOS', 'Timed Size OOS', 'Timed Value OOS', 'Location', 'NorthWest')
hold off
set(gcf, 'Position', [200, 200, 800, 600])    

