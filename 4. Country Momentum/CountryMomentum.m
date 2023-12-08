% CountryMomentum: Computes the returns from equally weighted and
% momentum portfolios on country ETFs

clc
clear
close all


% Parameter selection
% Annualization factor for monthly to annual
annualizationFactor = 12;
% Number of countries held long and short (nShorts is ignored in the
% long-only version)
nLongs = 5;
nShorts = 5;
% Proportional transaction costs
tCost = 0.001;
% Momentum lookback period (start and end of window, as positive numbers;
% start must be greater than end)
lookbackStart = 12;
lookbackEnd = 1;


% Load the data and extract the dates, riskless rate, and ETF prices
% Method 1: use xlsread
% [ETFPrices, ETFDates] = xlsread('CountryData.xls');
% ETFDates = ETFDates(2 : end, 1);
% Rf = ETFPrices(:, 1) / 100;
% ETFPrices = ETFPrices(:, 2 : end);

% Alternative: use readtable
data = readtable('CountryData.xls', 'Format', 'auto', 'TreatAsEmpty', {'#N/A N/A'});
ETFDates = data.('Date');                   % Same as saying: ETFDates = data.Date;
Rf = data.('USD1MonthRate') / 100;
ETFPrices = table2array(data(:, 3 : end));  % Same as saying: ETFPrices = data{:, 3 : end};


% Size of the dataset
nMonths = length(ETFDates)
nAssets = size(ETFPrices, 2)


% Process the dates: Get numeric dates and generate a vector for the plot x-axis
datesNumeric = datenum(ETFDates);   % In case it loads as string use datenum(ETFDates, 'dd.MM.yyyy');
dates4Fig = datetime(ETFDates);     % In case it loads as string use datetime(ETFDates, 'InputFormat', 'dd.MM.yyyy');


% Compute monthly ETF (total) returns
ETFReturns = zeros(nMonths, nAssets);
ETFReturns(2 : end, :) = ETFPrices(2 : end, :) ./ ETFPrices(1 : end - 1, :) - 1;


% Compute the return earned on the riskless asset each month, accounting for
% the number of calendar days until the end of the next month. Shift the result
% down by one month so that it represents the return accrued during that month
dayCount = diff(datesNumeric);
% Same as: dayCount = datesNumeric(2 : end, 1) - datesNumeric(1 : end - 1, 1);
RfMonthly = zeros(nMonths, 1);
RfMonthly(2 : end, 1) = Rf(1 : end - 1, 1) .* dayCount / 360;

    
% Construct equally weighted and momentum portfolios
% For equally weighted portfolios, find out which country ETFs are available
% in a given month.
% For the momentum portfolios, issues arising with missing data are handled
% in the computeSortWeights function.
equalWeights = zeros(nMonths, nAssets);
momLongWeights = zeros(nMonths, nAssets);
momLSWeights = zeros(nMonths, nAssets);
firstMonth = lookbackStart + 1;
for month = firstMonth : nMonths
    % Equally weighted portfolio
    nonMissings = isfinite(ETFPrices(month, :));
    equalWeights(month, :) = nonMissings / sum(nonMissings);
    
    % Momentum portfolios, long only and long/short
    pastReturns = ETFPrices(month - lookbackEnd, :) ./ ETFPrices(month - lookbackStart, :) - 1;
    momLongWeights(month, :) = computeSortWeights(pastReturns, nLongs, 0, 1);
    momLSWeights(month, :) = computeSortWeights(pastReturns, nLongs, nShorts, 1);
end


% In order to have weights and returns in sync, one drops firstMonth months 
% from the beginning of the return series, and (firstMonth - 1) months from 
% the beginning of the portfolio weight series. We keep one extra month at  
% the end of the portfolio weights series for the turnover computations later.
dates4Fig = dates4Fig(firstMonth + 1 : end, 1);
ETFReturns = ETFReturns(firstMonth + 1 : end, :);
RfMonthly = RfMonthly(firstMonth + 1 : end, 1);
equalWeights = equalWeights(firstMonth : end, :);
momLongWeights = momLongWeights(firstMonth : end, :);
momLSWeights = momLSWeights(firstMonth : end, :);
nMonths = nMonths - firstMonth;


% Compute the strategy returns without transaction costs. 
% First, we need to replace the NaNs with zeros.
% Note that for the long/short version, we need to add the riskless asset return.
% We're using R_p = w' * R + (1 - w' * 1) * Rf for all portfolios.
% For the long-only portfolios, (1 - w' * 1) = 0 so the second term vanishes.
% For the long-short portfolio, (1 - w' * 1) = 1 so we just add Rf.
ETFReturns(isnan(ETFReturns)) = 0;
stratReturnsNoTC = zeros(nMonths, 3);
stratReturnsNoTC(:, 1) = sum(ETFReturns .* equalWeights(1 : end - 1, :), 2);
stratReturnsNoTC(:, 2) = sum(ETFReturns .* momLongWeights(1 : end - 1, :), 2);
stratReturnsNoTC(:, 3) = sum(ETFReturns .* momLSWeights(1 : end - 1, :), 2) + RfMonthly;


% Compute the strategy returns with transaction costs by subtracting
% turnover times proportional transaction costs from the returns of each strategy 
turnover = zeros(nMonths, 3);
for month = 1 : nMonths
    currentRf = RfMonthly(month, 1);
    currentRet = ETFReturns(month, :);
    turnover(month, 1) = computeTurnover(equalWeights(month, :), equalWeights(month + 1, :), currentRet, currentRf);
    turnover(month, 2) = computeTurnover(momLongWeights(month, :), momLongWeights(month + 1, :), currentRet, currentRf); 
    turnover(month, 3) = computeTurnover(momLSWeights(month, :), momLSWeights(month + 1, :), currentRet, currentRf); 
end
% This is splitting hair a little bit. We're adding the transactions in the initial month.
turnover(1, 1 : 2) = turnover(1, 1 : 2) + 1;
turnover(1, 3) = turnover(1, 3) + 2;
avgTurnover = mean(turnover)
stratReturnsTC = stratReturnsNoTC - tCost * turnover;
    

% Consolidate the returns in a single array
allTotalReturns = [stratReturnsNoTC stratReturnsTC];
allXsReturns = allTotalReturns - RfMonthly * ones(1, size(allTotalReturns, 2));


% Performance statistics (benchmark is equally weighted portfolio of all
% available countries, stored in allXsReturns(:, 1))
summarizePerformance(allXsReturns, RfMonthly, allXsReturns(:, 1), annualizationFactor, 'Country Strategies (Equally Weighted, Momentum Long Only, Momentum Long/Short), without and with transaction costs');


% Cumulative returns, using total returns and not excess returns
strategyNAV = cumprod(1 + allTotalReturns);
figure
plot(dates4Fig, strategyNAV(:, 1), 'k-', dates4Fig, strategyNAV(:, 2), 'b-', dates4Fig, strategyNAV(:, 3), 'r-')
hold on
plot(dates4Fig, strategyNAV(:, 4), 'k--', dates4Fig, strategyNAV(:, 5), 'b--', dates4Fig, strategyNAV(:, 6), 'r--'),
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('Equally Weighted', 'Momentum Long Only', 'Momentum Long/Short', 'Equally Weighted, TC', 'Mom. Long Only, TC', 'Mom. Long/Short, TC', 'Location', 'NorthWest')
