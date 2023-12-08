% FXCarryMomentum

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


% load the data
% here date column = column 1
fileName = 'FXCarryMomentumData.xls' ;
tickerTable = readtable(fileName, 'sheet', 'FrontMonthTickers'); % has already understood that dates are dates
frontTable = readtable(fileName, 'sheet', 'FrontMonthPrices');
backTable = readtable(fileName, 'sheet', 'BackMonthPrices');
intTable = readtable(fileName, 'sheet', 'InterestRates');

% now date column = date column (0)
tickerTable = table2timetable(tickerTable);
frontTable = table2timetable(frontTable);
backTable = table2timetable(backTable);
intTable = table2timetable(intTable);

% Synchronize Data
% just done to have same time axis for each subset, later we split it again
% if times axis don't match and you do union you will have missings
% if time axis match union is o.k.
% we use default: union (different types p.41)
mergedTable = synchronize(tickerTable, frontTable, backTable, intTable);

% check for NaN values
sum(sum(ismissing(mergedTable))); 

% extract subtables again after synchronizing
tickers = table2array(mergedTable(:, 1:7));
frontPrices = table2array(mergedTable(:, 8:14));
backPrices = table2array(mergedTable(:, 15:21));
intRates = table2array(mergedTable(:, 22:end)); % attention IR have one column more

% Extract USD rate
% USD rate as Rf for portfolio hence we extract it
% given in % therefore /100
Rf = intRates(:, end) / 100;
intRates = intRates(:, 1:end-1) / 100;

% Size of the dataset
% doesn't matter where we take it from since all in sync
nDays = length(Rf);
nAssets = size(frontPrices, 2);

% Process the dates: Get numeric dates and generate a vector for the plot x-axis
datesNumeric = datenum(mergedTable.Date);
% Date column is already datetime so transformation not really necessary
class(mergedTable.Date); % datetime
dates4Fig = datetime(mergedTable.Date);

% Compute the return earned on the riskless asset, accounting for
% the number of calendar days between two trading days. Shift the result
% down by one month so that it represents the return accrued on that day
dayCount = diff(datesNumeric);
% Same as: dayCount = datesNumeric(2 : end, 1) - datesNumeric(1 : end - 1, 1);
Rfscaled = zeros(nDays, 1);
Rfscaled(2 : end, 1) = Rf(1 : end - 1, 1) .* dayCount / 360;
% rate(monday) = rate(friday) * #days between it / 360
% interest is calender days so use 360 or 365 but not 252 trading days!!

%%% Dealing with Rollovers 
% if in index futures, on 3rd friday of december the thing expires
% (right now my frontmonth is december) hence latest on thursday night I
% need to get out of the december contract and into the march contract.
% For currencies it's not friday but usually monday or tuesday, but same.
% If you don't get out you have physical delivery two or on day later!
% -> Switching from one maturity to the next
% -> for this I have the tickers to see when it switches
% -> whenever ticker changes, compute return as
%    FrontPrice(today)/BackPrice(yesterday)
% -> we're not switching contracts like this because the contract that was
%    BackContract just before the FrontContract expired has become the new
%    FrontContract
% -> else it's: FrontPrice(today)/FrontPrice(yesterday)

% Most of return of CarryTrade is the interest rate differential
% If you back test CarryTrade and you mess up the rollover pretty much all
% your returns disappear

% Compute daily futures (excess) returns
futuresReturns = zeros(nDays, nAssets);
frontReturns = frontPrices(2 : end, :) ./ frontPrices(1 : end - 1, :) - 1;
frontBackReturns = frontPrices(2 : end, :) ./ backPrices(1 : end - 1, :) -1 ;
% identifying rollover dates
rollover = 1 - strcmp(tickers(1 : end-1, :), tickers(2 : end, :)); % like this off-set by 1

futuresReturns(2 : end, :) = rollover .* frontBackReturns + (1 - rollover) .* frontReturns;

%%% Compute monthly returns
% get first and last day of months
[yr, mth, dy] = datevec(datesNumeric);
dateList = 10000 * yr + 100 * mth + dy;
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dateList, 2);

% monthly dates for the plot
dates4FigMonthly = dates4Fig(lastDayList);

% What is cash-balance each day on which we will be earning interest?
nMonths = length(firstDayList);
monthlyRf = zeros(nMonths, 1);
monthlyTotalReturns = zeros(nMonths, nAssets);
for month = 1 : nMonths
    first = firstDayList(month);
    last = lastDayList(month);
    nDaysThisMonth = last - first + 1;
    
    monthlyRf(month) = prod(1 + Rfscaled(first : last)) - 1;
    
    % reproduce the "No rebalancing" way of excel
    
    % cumprod of price-changes supposing they start at 1
    scaledPrices = cumprod(1 + futuresReturns(first : last, :));
    % MTM (mark-to-market): change in futures
    MTM = zeros(nDaysThisMonth, nAssets);
    MTM(1, :) = scaledPrices(1, :) - 1;
    MTM(2 : end, :) = scaledPrices(2 : end, :) - scaledPrices(1 : end - 1, :);
    
    cash = ones(1, nAssets);   
    
    % ending cash + change in future + interest
    for day = first : last
        % ending cash + change in future + interest
        cash = cash * (1 + Rfscaled(day)) + MTM(day - first + 1);
    end
    
    % cash(end)/cash(beginning)-1 -> cash(beginning)=1
    monthlyTotalReturns(month, :) = cash - 1;
    
end

monthlyXsReturns = monthlyTotalReturns - monthlyRf;

% Construct equally weighted, carry and momentum portfolios
equalWeights = ones(nMonths, nAssets) / nAssets;
carryWeights = zeros(nMonths, nAssets);
momWeights = zeros(nMonths, nAssets);
firstMonth = 1;
for m = firstMonth : nMonths
    first = firstDayList(month);
    last = lastDayList(month);
    
    % Carry portfolio
    carryWeights(m, :) = computeSortWeights(intRates(last - lag, :), nLongs, nShorts, 1);
    
    % Momentum portfolios
    pastReturns = prod(1 + futuresReturns(max(first - lag, 1) : last - lag, :));
    momWeights(m, :) = computeSortWeights(pastReturns, nLongs, nShorts, 1);

end


% In order to have weights and returns in sync, one drops firstMonth months 
% from the beginning of the return series, and (firstMonth - 1) months from 
% the beginning and one month from the end of the portfolio weight series. 
% firstMonth = 1
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
stratXsReturns(:, 3) = sum(monthlyXsReturns .* momWeights, 2) + monthlyRf;
stratXsReturns(:, 4) = (stratXsReturns(:, 2) + stratXsReturns(:, 3)) / 2;

stratTotalReturns = stratXsReturns + monthlyRf;

% Consolidate the returns in a single array
allTotalReturns = stratTotalReturns;
allXsReturns = stratXsReturns;


% Performance statistics (benchmark is equally weighted portfolio of all
% available countries, stored in allXsReturns(:, 1))
summarizePerformance(allXsReturns, monthlyRf, allXsReturns(:, 1), annualizationFactor, 'Strategies (Equally Weighted, Carry, Momentum)');


% Equity lines, using total returns and not excess returns
strategyNAV = cumprod(1 + allTotalReturns);
figure
plot(dates4FigMonthly, strategyNAV(:, 1), 'k-', dates4FigMonthly, strategyNAV(:, 2), 'b-')
hold on
plot(dates4FigMonthly, strategyNAV(:, 3), 'k--', dates4FigMonthly, strategyNAV(:, 4), 'b--'),
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('Equally Weighted', 'Carry', 'Momentum', 'Combination', 'Location', 'NorthWest')
