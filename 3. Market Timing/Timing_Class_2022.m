clc
clear

% Parameters
lag = 0;
cap = 2;

% Load
factorData = readtable('FFDaily.xls');

% Extract data from table
Dates = datetime(factorData.Date, 'ConvertFrom', 'yyyymmdd');
f_xs_returns = factorData(:, 2 : 4);
f_xs_returns = f_xs_returns{:, :} / 100;
Rf = factorData.RF / 100;
nObs = length(Rf);
nFactors = size(f_xs_returns, 2);
f_total_returns = f_xs_returns + Rf;


% Compute cumulative returns
f_returns_cum = cumprod(1 + f_total_returns);
xs_returns_cum = cumprod(1 + f_xs_returns);

for i = 1 : 3
    figure
    semilogy(Dates, f_returns_cum(:, i), 'k-', Dates, xs_returns_cum(:, i), 'b--')
end

% Identify first and last day of each month
numericDates = factorData.Date;
yearMonth = round(numericDates / 100);
monthChange = diff(yearMonth); % similar to yearMonth(1 : nObs - 1, 1) - yearMonth(2 : nObs, 1);
lastDayList = find(monthChange);
firstDayList = lastDayList + 1;
lastDayList = [lastDayList; nObs];
firstDayList = [1; firstDayList];

% Aggregate returns from daily to monthly
nMonths = length(firstDayList);
monthlyRf = zeros(nMonths, 1);
monthlyTotalReturns = zeros(nMonths, nFactors);
for month = 1 : nMonths
    first = firstDayList(month);
    last = lastDayList(month);
    monthlyRf(month, 1) = prod(1 + Rf(first : last, 1)) - 1;
    monthlyTotalReturns(month, :) = prod(1 + f_total_returns(first : last, :)) - 1;
    %monthlyRf(month, 1) = prod(1 + Rf(firstDayList(month) : lastDayList(month), 1)) - 1;

end
monthlyXsReturns = monthlyTotalReturns - monthlyRf;

% Compute monthly variances
monthlyVar = zeros(nMonths, nFactors);
for month = 1 : nMonths
    first = max(firstDayList(month) - lag, 1);
    last = lastDayList(month) - lag;
    monthlyVar(month, :) = var(f_xs_returns(first : last, :));
end

% Compute portfolio weights
% In-sample
monthlyWeights = mean(monthlyVar) ./ monthlyVar;
% OOS
monthlyWeightsOOS = zeros(nMonths, nFactors);
for month = 1 : nMonths
    trailingVar = mean(monthlyVar(1 : month, :), 1);
    monthlyWeightsOOS(month, :) = min(trailingVar ./ monthlyVar(month, :), cap);
end

% Compute strategy returns
strategyXsReturns = monthlyWeights(1 : end - 1, :) .* monthlyXsReturns(2 : end, :);
strategyXsReturnsOOS = monthlyWeightsOOS(1 : end - 1, :) .* monthlyXsReturns(2 : end, :);

% Rescale in-sample strategy
scaling = std(monthlyXsReturns(2 : end, :)) ./ std(strategyXsReturns);

monthlyWeights = monthlyWeights .* scaling;
strategyXsReturns = monthlyWeights(1 : end - 1, :) .* monthlyXsReturns(2 : end, :);

% Performance statistics
strategyTotalReturns = strategyXsReturns + monthlyRf(2 : end, 1);
strategyTotalReturnsOOS = strategyXsReturnsOOS + monthlyRf(2 : end, 1);
allTotalReturns = [monthlyTotalReturns(2 : end, :) strategyTotalReturns strategyTotalReturnsOOS];

nYears = length(allTotalReturns) / 12
portfolioStats(allTotalReturns, monthlyRf(2 : end, 1), monthlyXsReturns(2 : end, :), nYears)
% ReturnSeries should be total returns
% Assuming we are passing in daily data



