% FXScoringTiming: Computes the returns from a scoring model using
% carry and 1-month momentum to rank currencies. 
% In addition, times exposure based on the VIX level.

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
% Long-term average VIX level
avgVIX = 20;

% Load the data, compute the returns on the futures contracts, and plot 
% the returns on the different currencies (steps 1 - 7 from the currency
% carry/momentum example).
prepareFXData;


% Load the VIX data and drop the header row from the dates
[VIXPrices, VIXDates] = xlsread('VIX.xls');
VIXDates = VIXDates(2 : end, 1);

% Generate a numeric date for VIX data. We need to do this because the 
% market holidays are not the same for equity options and currency futures.
datesNumericVIX = datenum(VIXDates, 'mm/dd/yyyy');
[yrVIX, mthVIX, dyVIX] = datevec(datesNumericVIX);
datesVIX = 10000 * yrVIX + 100 * mthVIX + dyVIX;

% Use interest rates and past returns to give an overall score to currencies
% and construct the portfolio based on the overall score.
% First, generate arrays listing the first and last trading day of each month
% We need two arrays, one for currencies, one for VIX.
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);
[firstDayListVIX, lastDayListVIX] = getFirstAndLastDayInPeriod(datesVIX, 2);
nMonths = length(firstDayList)
if (length(firstDayListVIX) ~= nMonths)
    disp('Warning: FX and VIX data do not have the same number of months');
end
% Array for the x-axis in the monthly plots
dates4FigMonthly = dates4Fig(lastDayList);
carryScore = zeros(nMonths, nAssets);
momScore = zeros(nMonths, nAssets);
totalScore = zeros(nMonths, nAssets);
equalWeightsRaw = ones(nMonths, nAssets) / nAssets;
equalWeightsTimed = ones(nMonths, nAssets) / nAssets;
pfWeightsRaw = zeros(nMonths, nAssets);
pfWeightsTimed = zeros(nMonths, nAssets);
scale = zeros(nMonths, 1);

% Second, compute the return in the month, honoring any trading lag, and
% obtain the carry and momentum scores by sorting on interest rates and 
% past returns. Then compute the overall score and equal weight assets with
% a positive total score and those with a negative total score.
for m = 1 : nMonths
    first = firstDayList(m);
    last = lastDayList(m);
    monthlyRet = prod(1 + dailyXsReturns(max(first - lag, 1) : last - lag, :));
    
    % Compute carry and momentum scores
    carryScore(m, :) = getScore(intRates(last - lag, :), nLongs, nShorts, 1);
    momScore(m, :) = getScore(monthlyRet, nLongs, nShorts, 1);
    
    % Compute total score and form the portfolio
    totalScore(m, :) = carryScore(m, :) + momScore(m, :);
    pfWeightsRaw(m, :) = computeScoreWeights(totalScore(m, :));

    % Timing component
    lastVIX = lastDayListVIX(m) - lag;
    scale(m) = avgVIX / VIXPrices(lastVIX);
    equalWeightsTimed(m, :) = scale(m) * equalWeightsRaw(m, :);
    pfWeightsTimed(m, :) = scale(m) * pfWeightsRaw(m, :);
end

% Drop the first month from the return series and the last month from the
% portfolio weights series to have weights and returns in sync
dates4FigMonthly = dates4FigMonthly(2 : nMonths, 1);
monthlyXsReturns = monthlyXsReturns(2 : nMonths, :);
monthlyTotalReturns = monthlyTotalReturns(2 : nMonths, :);
monthlyRf = monthlyRf(2 : nMonths, 1);
equalWeightsRaw = equalWeightsRaw(1 : nMonths - 1, :);
equalWeightsTimed = equalWeightsTimed(1 : nMonths - 1, :);
pfWeightsRaw = pfWeightsRaw(1 : nMonths - 1, :);
pfWeightsTimed = pfWeightsTimed(1 : nMonths - 1, :);
nMonths = nMonths - 1;


% Compute the strategy returns
allXsReturns = zeros(nMonths, 4);
allXsReturns(:, 1) = sum(monthlyXsReturns .* equalWeightsRaw, 2);
allXsReturns(:, 2) = sum(monthlyXsReturns .* equalWeightsTimed, 2);
allXsReturns(:, 3) = sum(monthlyXsReturns .* pfWeightsRaw, 2);
allXsReturns(:, 4) = sum(monthlyXsReturns .* pfWeightsTimed, 2);
allTotalReturns = allXsReturns + monthlyRf * ones(1, size(allXsReturns, 2));
xsReturnCorrels = corrcoef(allXsReturns)


% Performance statistics
summarizePerformance(allXsReturns, monthlyRf, allXsReturns(:, 1), annualizationFactor, 'EW, EW Timed, Scoring, Scoring Timed');

% Equity lines, using total returns and not excess returns
monthlyStrategyNAV = cumprod(1 + allTotalReturns);
figure
semilogy(dates4FigMonthly, monthlyStrategyNAV(:, 1), 'k-', dates4FigMonthly, monthlyStrategyNAV(:, 2), 'b--', dates4FigMonthly, monthlyStrategyNAV(:, 3), 'r:', dates4FigMonthly, monthlyStrategyNAV(:, 4), 'm-.')
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('EW Constant Exposure', 'EW Timed', 'Scoring Constant Exposure', 'Scoring Timed', 'Location', 'SouthEast')set(gcf, 'Position', [200, 200, 800, 600])