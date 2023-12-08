% like that it closes and clears all every time i run it
clear
close all
clc

% Trading lag in days
lag = 1;
% Exposure cap
cap = 2;

% Load the data
dataTable = readtable('FFDaily.xls');
data = table2array(dataTable);      % convert data to array
dates = data(:, 1);                 % first column = dates
xsReturns = data(:, 2 : 4) / 100;   % /100 because returns are given in percent
Rf = data(:, 5) / 100;
totalReturns = xsReturns + Rf;      % xs = excess return

%%% 1)
% Plot cumulative returns
cumulativeXsReturns = cumprod(1 + xsReturns);
cumulativeTotalReturns = cumprod(1 + totalReturns);

dates4Fig = datetime(dates, 'ConvertFrom', 'YYYYMMDD');

% smilogy -> logarithmic y-axis
subplot(2, 1, 1), semilogy(dates4Fig, cumulativeXsReturns(:, 1), 'k-', dates4Fig, cumulativeXsReturns(:, 2), 'b--', dates4Fig, cumulativeXsReturns(:, 3), 'r-.');
subplot(2, 1, 2), semilogy(dates4Fig, cumulativeTotalReturns(:, 1), 'k-', dates4Fig, cumulativeTotalReturns(:, 2), 'b--', dates4Fig, cumulativeTotalReturns(:, 3), 'r-.');

%%% 2)
% Compute monthly returns
% Find first and last day of each month
truncatedDate = round(dates / 100); % because dates are numbers -> YYYYMM
monthChange = truncatedDate(2 : end) - truncatedDate(1 : end - 1); % marks last day of each month (year change -> not 1 but also not 0)
lastDayList = find(monthChange); % find indices of all non-zero
firstDayList = 1 + lastDayList; % here we're missing the first day of the first month
firstDayList = [1; firstDayList]; % therefore we insert 1 at the top of the list (stack it)
lastDayList = [lastDayList; length(dates)]; % lastDayList doesn't contain the last day of ds since it has value 0 because it can't be compared to t+1. Therefore we add the index of the last element manually

nMonths = length(lastDayList) % or firstDayList, doesn't matter 
monthlyRf = zeros(nMonths, 1);
monthlyTotalReturns = zeros(nMonths, 3);
for month = 1 : nMonths
    first = firstDayList(month);
    last = lastDayList(month);
    monthlyRf(month, 1) = prod(1 + Rf(first : last)) - 1; % see formula AM 
    monthlyTotalReturns(month, :) = prod(1 + totalReturns(first : last, :)) - 1;
end
monthlyXsReturns = monthlyTotalReturns - monthlyRf; % this works for market

% For size and value since they are long-short:
% Compound the long, compound the short and then compute the monthly long-short as the
% monthly long minus the monthly short (long/short info not given here)
% way above: good approximation


% Compute monthly variances
monthlyVariances = zeros(nMonths, 3);
for month = 1 : nMonths
    first = firstDayList(month);
    last = lastDayList(month);
    monthlyVariances(month, :) = var(xsReturns(max(first - lag, 1) : last - lag, :)); % max bcs first month - lag = problem
end
% use excess returns for variance, bcs total have riskless (but you get
% pretty much the same, first just correcter)

% Compute portfolio weights
% -> we have to rescale weight (1/var) bcs else you're levered too highly 
% -> slightest market move and you'd blow up
% one scaling possibility: avg.var/var
monthlyWeights = mean(monthlyVariances) ./ monthlyVariances; % it's cheating but since we do in-sample strategy we cheat anyway
monthlyWeightsOOS = zeros(nMonths, 3);
for month = 1 : nMonths
    monthlyWeightsOOS(month, :) = min(mean(monthlyVariances(1 : month, :), 1) ./ monthlyVariances(month, :), cap); % min with cap=2: we want max exposure of 2!
end                                                                % without the 1 it would just give out a single number instead of a vector

% compute returns
% we need weights of this month to calculate return of next month
strategyXsReturns = monthlyWeights(1 : end - 1, :) .* monthlyXsReturns(2 : end, :);
strategyTotalReturns = strategyXsReturns + monthlyRf(2 : end, :);

strategyXsReturnsOOS = monthlyWeightsOOS(1 : end - 1, :) .* monthlyXsReturns(2 : end, :);
strategyTotalReturnsOOS = strategyXsReturnsOOS + monthlyRf(2 : end, :);

% Rescale the weights for in-sample strategy
% -> match on excess returns because we look at risk an rf no risk (but could
%    be argued)
benchmarkStd = std(monthlyXsReturns(2 : end, :)); % 2+ because else I have one month exttra for benchmark
strategyStd = std(strategyXsReturns); % 2+ not needed because already accounted for
scaling = benchmarkStd ./ strategyStd % scaling factor
monthlyWeights = monthlyWeights .* scaling; % matrix*vector algebraically wrong -> should turn vector into matrix with: ones(nMonths-1,1)*scaling

% recalculate returns (rescale excsess returns not total returns!)
strategyXsReturns1 = monthlyWeights(1 : end - 1, :) .* monthlyXsReturns(2 : end, :);
strategyXsReturns2 = strategyXsReturns .* scaling;

strategyTotalReturns = strategyXsReturns1 + monthlyRf(2 : end, :);

% Performance statistics
allTotalReturns = [monthlyTotalReturns(2 : end, :), strategyTotalReturns, strategyTotalReturnsOOS]; 
allXsReturns = [monthlyXsReturns(2 : end, :), strategyXsReturns1, strategyXsReturnsOOS]; 

% Annualized return
FinalPfValue = prod(1 + allTotalReturns); % take total returns!
nYears = (nMonths - 1) / 12;
annualizedReturn = FinalPfValue.^(1 / nYears) - 1 
FinalRf = prod(1 + monthlyRf(2 : end, 1));
annualizedRf = FinalRf.^(1 / nYears) - 1
% Annualized std
annualizedStd = sqrt(12) * std(allXsReturns)
% Sharpe ratio
SR_Geom = (annualizedReturn - annualizedRf) ./ annualizedStd
SR_Arithm = (12 * mean(allXsReturns)) ./ annualizedStd

% Worst and best month
worst = min(allXsReturns)
best = max(allXsReturns)

% Skewness, kurtosis
skew = skewness(allXsReturns)
kurt = kurtosis(allXsReturns)

% Alpha: regress strategy excess returns (y) on factor excess returns + constant (X)
X = [ones(nMonths - 1, 1), monthlyXsReturns(2 : end, :)]; % [vector of 1's, returns]
b = inv(X' * X) * X' * allXsReturns; % does all 9 regression in one matrix

% b = coefficient matrix (betas)
% -> b = [beta1             beta1            beta1           ...                               ]
%        [uncond.s(market)  uncond.s(market) uncond.s(market) timing(market) timing(market) ...]
%        [uncond.s(size)    uncond.s(size)   uncond.s(size)   timing(size)   timing(size)   ...]
%        [uncond.s(value)   uncond.s(value)  uncond.s(value)  timing(value)  timing(value)  ...]
% -> changing exposure to market, size and value over time
% -> higer values on diagonal
% -> +: long, -: short

% Alternative: b = X \ allXsReturns;

monthlyAlpha = b(1, :) % 1st row in coefficient matrix (intercept)
betas = b(2 : end, :)

% annualized Alphas
alpha_Arithm = 12 * monthlyAlpha

bmTotalRet = monthlyXsReturns(2 : end, :) * betas + monthlyRf(2 : end, 1);
FinalBmValue = prod(1 + bmTotalRet);
annualizedBmReturn = FinalBmValue.^(1 / nYears) - 1
alpha_Geom = annualizedReturn - annualizedBmReturn








