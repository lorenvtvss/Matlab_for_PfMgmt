% FX Carry Momentum

clc
clear
close all


% Parameter selection
% Annualization factor for monthly to annual
annualizationFactor = 12;
% Number of countries held long and short (nShorts is ignored in the
% long-only version)
nLongs = 3;
nShorts = 3;
% Trading lag
lag = 0;

% Momentum lookback period (start and end of window, as positive numbers;
% start must be greater than end)
%lookbackStart = 12;
%lookbackEnd = 1;


% Load the data and extract the dates, riskless rate, and ETF prices
fileName = 'FXCarryMomentumData.xls'; 
tickerTable = readtable(fileName, 'Sheet', 'FrontMonthTickers');%'Format', 'auto', 'TreatAsEmpty', {'#N/A N/A'});
frontTable = readtable(fileName, 'Sheet', 'FrontMonthPrices');
backTable = readtable(fileName, 'Sheet', 'BackMonthPrices');
intTable = readtable(fileName, 'Sheet', 'InterestRates');

tickerTable = table2timetable(tickerTable);
frontTable = table2timetable(frontTable);
backTable = table2timetable(backTable);
intTable = table2timetable(intTable);

mergedTable = synchronize(tickerTable, frontTable, backTable, intTable);

tickers = table2array(mergedTable(:, 1 : 7));
frontPrices = table2array(mergedTable(:, 8 : 14));
backPrices = table2array(mergedTable(:, 15 : 21));
intRates = table2array(mergedTable(:, 22 : end));

% Extract USD rate
Rf = intRates(:, end) / 100;
intRates = intRates(:, 1 : end - 1) / 100;

% Size of the dataset
nDays = length(Rf);
nAssets = size(frontPrices, 2)



% Process the dates: Get numeric dates and generate a vector for the plot x-axis
datesNumeric = datenum(mergedTable.Date);
dates4Fig = datetime(mergedTable.Date);

% Compute the return earned on the riskless asset, accounting for
% the number of calendar days between two trading days. Shift the result
% down by one month so that it represents the return accrued on that day
dayCount = diff(datesNumeric);
% Same as: dayCount = datesNumeric(2 : end, 1) - datesNumeric(1 : end - 1, 1);
RfScaled = zeros(nDays, 1);
RfScaled(2 : end, 1) = Rf(1 : end - 1, 1) .* dayCount / 360;

% Compute daily futures (excess) returns
futuresReturns = zeros(nDays, nAssets);
frontReturns = frontPrices(2 : end, :) ./ frontPrices(1 : end - 1, :) - 1;
frontBackReturns = frontPrices(2 : end, :) ./ backPrices(1 : end - 1, :) - 1;
rollover = 1 - strcmp(tickers(2 : end, :), tickers(1 : end - 1, :));

futuresReturns(2 : end, :) = rollover .* frontBackReturns + (1 - rollover) .* frontReturns;

% Compute monthly returns
[yr, mth, dy] = datevec(datesNumeric);
dateList = 10000 * yr + 100 * mth + dy;
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dateList, 2);

dates4FigMonthly = dates4Fig(lastDayList);

nMonths = length(firstDayList);
monthlyRf = zeros(nMonths, 1);
monthlyTotalReturns = zeros(nMonths, nAssets);
for month = 1 : nMonths
    first = firstDayList(month);
    last = lastDayList(month);
    nDaysThisMonth = last - first + 1;
    
    monthlyRf(month) = prod(1 + RfScaled(first : last)) - 1;
    
    scaledPrices = cumprod(1 + futuresReturns(first : last, :));
    MTM = zeros(nDaysThisMonth, nAssets);
    MTM(1, :) = scaledPrices(1, :) - 1;
    MTM(2 : end, :) = scaledPrices(2 : end, :) - scaledPrices(1 : end - 1, :);
    cash = ones(1, nAssets);
    for day = first : last
        cash = cash * (1 + RfScaled(day)) + MTM(day - first + 1, :);
    end
    monthlyTotalReturns(month, :) = cash - 1;    
end
monthlyXsReturns = monthlyTotalReturns - monthlyRf;



% Construct equally weighted, carry and momentum portfolios
equalWeights = ones(nMonths, nAssets) / nAssets;
carryWeights = zeros(nMonths, nAssets);
momWeights = zeros(nMonths, nAssets);
firstMonth = 1;
for m = firstMonth : nMonths
    first = firstDayList(m); 
    last = lastDayList(m);
    
    % Carry portfolio
    carryWeights(m, :) = computeSortWeights(intRates(last - lag, :), nLongs, nShorts, 1);
    
    % Momentum portfolios, long only and long/short
    pastReturns = prod(1 + futuresReturns(max(first - lag, 1) : last - lag, :));
    momWeights(m, :) = computeSortWeights(pastReturns, nLongs, nShorts, 1);
end


% In order to have weights and returns in sync, one drops firstMonth months 
% from the beginning of the return series, and (firstMonth - 1) months from 
% the beginning and one month from the end of the portfolio weight series. 
dates4FigMonthly = dates4FigMonthly(firstMonth + 1 : end, 1);
monthlyTotalReturns = monthlyTotalReturns(firstMonth + 1 : end, :);
monthlyXsReturns = monthlyXsReturns(firstMonth + 1 : end, :);
monthlyRf = monthlyRf(firstMonth + 1 : end, 1);
equalWeights = equalWeights(firstMonth : end - 1, :);
carryWeights = carryWeights(firstMonth : end - 1, :);
momWeights = momWeights(firstMonth : end - 1, :);
nMonths = nMonths - firstMonth;


% Compute the strategy returns 
stratXsReturns = zeros(nMonths, 4);
stratXsReturns(:, 1) = sum(monthlyXsReturns .* equalWeights, 2);
stratXsReturns(:, 2) = sum(monthlyXsReturns .* carryWeights, 2);
stratXsReturns(:, 3) = sum(monthlyXsReturns .* momWeights, 2);
stratXsReturns(:, 4) = (stratXsReturns(:, 2) + stratXsReturns(:, 3)) / 2;
stratTotalReturns = stratXsReturns + monthlyRf;


    

% Consolidate the returns in a single array
allTotalReturns = stratTotalReturns;
allXsReturns = stratXsReturns;


% Performance statistics (benchmark is equally weighted portfolio of all
% available currencies, stored in allXsReturns(:, 1))
summarizePerformance(allXsReturns, monthlyRf, allXsReturns(:, 1), annualizationFactor, 'Country Strategies (Equally Weighted, Momentum Long Only, Momentum Long/Short), without and with transaction costs');


% Equity lines, using total returns and not excess returns
strategyNAV = cumprod(1 + allTotalReturns);
figure
plot(dates4FigMonthly, strategyNAV(:, 1), 'k-', dates4FigMonthly, strategyNAV(:, 2), 'b-')
hold on
plot(dates4FigMonthly, strategyNAV(:, 3), 'k--', dates4FigMonthly, strategyNAV(:, 4), 'b--'),
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('Equally Weighted', 'Carry', 'Momentum', 'Combination', 'Location', 'NorthWest')
