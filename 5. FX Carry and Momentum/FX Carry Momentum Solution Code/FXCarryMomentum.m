% FXCarryMomentum: Computes the returns from currency carry trade 
% and 1-month momentum strategies

clc
clear
close all

% Parameter selection
% Annualization factor for monthly to annual
annualizationFactor = 12;
% Trading lag. 0 means same-day trading, 1 means one day between
% computations and trading
lag = 0;
% Number of currencies held long and short
nLongs = 3;
nShorts = 3;
% Setting to compute monthly futures excess returns
% rebalanceDaily = 1 if the futures positions are rebalanced daily.
% rebalanceDaily = 0 if the futures positions are held constant during
% the month. In this case we account for the daily MTM gains/losses.
rebalanceDaily = 0;


% Load the data, compute the returns on the futures contracts, and plot 
% the returns on the different currencies (steps 1 - 7 in the description
% of the solution).
prepareFXData;

    
% Use interest rates and past returns to construct the portfolio weights
% First, generate arrays listing the first and last trading day of each month
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);
nMonths = length(firstDayList)
% Array for the x-axis in the monthly plots
dates4FigMonthly = dates4Fig(lastDayList);
equalWeights = ones(nMonths, nAssets) / nAssets;
carryWeights = zeros(nMonths, nAssets);
momWeights = zeros(nMonths, nAssets);
% Second, compute the return in the month, honoring any trading lag, and
% obtain the portfolio weights by sorting on interest rates and past returns.
for m = 1 : nMonths
    first = firstDayList(m);
    last = lastDayList(m);
    monthlyRet = prod(1 + dailyXsReturns(max(first - lag, 1) : last - lag, :));
    carryWeights(m, :) = computeSortWeights(intRates(last - lag, :), nLongs, nShorts, 1);
    momWeights(m, :) = computeSortWeights(monthlyRet, nLongs, nShorts, 1);
end


% Drop the first month from the return series and the last month from the
% portfolio weights series to have weights and returns in sync
dates4FigMonthly = dates4FigMonthly(2 : nMonths, 1);
monthlyXsReturns = monthlyXsReturns(2 : nMonths, :);
monthlyTotalReturns = monthlyTotalReturns(2 : nMonths, :);
monthlyRf = monthlyRf(2 : nMonths, 1);
equalWeights = equalWeights(1 : nMonths - 1, :);
carryWeights = carryWeights(1 : nMonths - 1, :);
momWeights = momWeights(1 : nMonths - 1, :);
nMonths = nMonths - 1;


% Compute the strategy returns
allXsReturns = zeros(nMonths, 4);
allXsReturns(:, 1) = sum(monthlyXsReturns .* equalWeights, 2);
allXsReturns(:, 2) = sum(monthlyXsReturns .* carryWeights, 2);
allXsReturns(:, 3) = sum(monthlyXsReturns .* momWeights, 2);
allXsReturns(:, 4) = (allXsReturns(:, 2) + allXsReturns(:, 3)) / 2;
allTotalReturns = allXsReturns + monthlyRf * ones(1, size(allXsReturns, 2));
xsReturnCorrels = corrcoef(allXsReturns)


% Performance statistics
summarizePerformance(allXsReturns, monthlyRf, allXsReturns(:, 1), annualizationFactor, 'Currency (EW, Carry, Momentum, 50/50 Combination)');


% Equity lines, using total returns and not excess returns
monthlyStrategyNAV = cumprod(1 + allTotalReturns);
figure
semilogy(dates4FigMonthly, monthlyStrategyNAV(:, 1), 'k-', dates4FigMonthly, monthlyStrategyNAV(:, 2), 'b--', dates4FigMonthly, monthlyStrategyNAV(:, 3), 'r:', dates4FigMonthly, monthlyStrategyNAV(:, 4), 'm-.')
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('EW', 'Carry', 'Momentum', '50/50 Combination', 'Location', 'SouthEast')
set(gcf, 'Position', [200, 200, 800, 600])
