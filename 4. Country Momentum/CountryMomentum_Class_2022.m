% Solution to the country momentum, version written in class
clc
clear
close all

% Parameter selection
% Lookback period
lookbackStart = 12;
lookbackEnd = 1;
% Number of longs and shorts
nLongs = 5;
nShorts = 5;
% Proportional transaction cost
tCost = 0.001;
% Annualization factor for monthly to annual
annualizationFactor = 12;



% Load the data
ETFData = readtable('CountryData.xls', 'Format', 'auto', 'TreatAsEmpty', {'#N/A N/A'});
ETFDates = ETFData.Date;
Rf = ETFData.USD1MonthRate / 100;
ETFPrices = table2array(ETFData(:, 3 : end));

%return
%[ETFData, ETFDates] = xlsread('CountryData.xls');
%ETFDates = ETFDates(2 : end, 1);
dates = datetime(ETFDates);
numericDates = yyyymmdd(dates);

%Rf = ETFData(:, 1) / 100;
%ETFPrices = ETFData(:, 2 : end);

% Perhaps make NaNs zeros

NAVariables = find(isnan(ETFPrices));
ETFPrices(NAVariables) = 0;

% Same thing in one line
ETFPrices(isnan(ETFPrices)) = 0;

% Size of dataset
nDays = length(ETFPrices);
nAssets = size(ETFPrices, 2);


% Compute ETF Returns
Returns = ETFPrices(2 : end, :) ./ ETFPrices(1 : end - 1, :) - 1;
serialDates = datenum(dates);
dayCount = diff(serialDates);
RfMonthly = Rf(1 : end - 1) .* dayCount / 360;

   
% Form portfolio weights
nMonths = nDays;
equalWeights = zeros(nMonths, nAssets);
momLongWeights = zeros(nMonths, nAssets);
momLSWeights = zeros(nMonths, nAssets);
firstMonth = lookbackStart + 1;
for month = firstMonth : nMonths
    % Need to find which assets are around
    nonMissings = (ETFPrices(month, :) ~= 0);
    equalWeights(month, :) = nonMissings / sum(nonMissings);

    % Momentum long only
    pastReturns = ETFPrices(month - lookbackEnd, :) ./ ETFPrices(month - lookbackStart, :) - 1;
    [bestValues, bestIndex] = maxk(pastReturns, nLongs);
    momLongWeights(month, bestIndex) = 1 / nLongs;

    % Momentum Long/Short
    [worstValues, worstIndex] = mink(pastReturns, nLongs);
    momLSWeights(month, :) = momLongWeights(month, :);
    momLSWeights(month, worstIndex) = -1 / nShorts;

end

% Compute returns on portfolios
Returns(isnan(Returns)) = 0;
Returns(isinf(Returns)) = 0;
strategyReturns = zeros(nMonths - 1, 3);
% EW
% Formula for portfolio returns: R_p = w' * R + (1 - w' * 1) * Rf
strategyReturns(:, 1) = sum(Returns .* equalWeights(1 : end - 1, :), 2);
strategyReturns(:, 2) = sum(Returns .* momLongWeights(1 : end - 1, :), 2);
strategyReturns(:, 3) = sum(Returns .* momLSWeights(1 : end - 1, :), 2) + RfMonthly;

% Account for transaction costs: need to compute turnover
turnover = zeros(nMonths, 3);
for month = 1 : nMonths - 1
    currentRf = RfMonthly(month, 1);
    currentReturns = Returns(month, :);
    turnover(month, 1) = computeTurnover(equalWeights(month, :), equalWeights(month + 1, :), currentReturns, currentRf);
    turnover(month, 2) = computeTurnover(momLongWeights(month, :), momLongWeights(month + 1, :), currentReturns, currentRf);
    turnover(month, 3) = computeTurnover(momLSWeights(month, :), momLSWeights(month + 1, :), currentReturns, currentRf);
end

strategyReturnsNet = strategyReturns - tCost * turnover(1 : end - 1, :);

allTotalReturns = [strategyReturns strategyReturnsNet];
allXsReturns = allTotalReturns - RfMonthly;

% Performance statistics
summarizePerformance(allXsReturns(13 : end, :), RfMonthly(13 : end), allXsReturns(13 : end, 1), annualizationFactor, 'EW, Momentum Long, Momentum L/S, without and with TC');

return

% Equity lines, using total returns and not excess returns
monthlyNAV = cumprod(1 + allTotalReturns);
return

% Plot (skipped in class)
figure
semilogy(monthlyDates4Fig, monthlyBenchmarkNAV(:, 1), 'k-', monthlyDates4Fig, monthlyBenchmarkNAV(:, 2), 'b-', monthlyDates4Fig, monthlyBenchmarkNAV(:, 3), 'r-')
hold on
semilogy(monthlyDates4Fig, monthlyStrategyNAV(:, 1), 'k--', monthlyDates4Fig, monthlyStrategyNAV(:, 2), 'b--', monthlyDates4Fig, monthlyStrategyNAV(:, 3), 'r--'),
semilogy(monthlyDates4Fig, monthlyStrategyNAVOOS(:, 1), 'k-.', monthlyDates4Fig, monthlyStrategyNAVOOS(:, 2), 'b-.', monthlyDates4Fig, monthlyStrategyNAVOOS(:, 3), 'r-.'),
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('BM Market', 'BM Size', 'BM Value', 'Timed Market', 'Timed Size', 'Timed Value', 'Timed Market OOS', 'Timed Size OOS', 'Timed Value OOS', 'Location', 'NorthWest')
hold off
set(gcf, 'Position', [200, 200, 800, 600])    

