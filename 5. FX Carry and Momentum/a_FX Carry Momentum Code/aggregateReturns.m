function f = aggregateReturns(originalReturns, dateList, nDigits)
% Aggregates returns over time.
% The original set of returns should be ordinary returns.
% Dates should be provided as numeric in the format YYYYMMDD, YYMMDD, or
% MMDD. The desired aggregation level is defined by the number of digits  
% that are removed from the date list. 2 digits will aggregate daily returns 
% to monthly ones or monthly returns to annual ones. 4 digits will convert 
% daily returns to annual returns.

% Get the first and last day of each period
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dateList, nDigits);

% Compound the returns during the period
nPeriods = length(firstDayList);
nAssets = size(originalReturns, 2);
aggregatedReturns = zeros(nPeriods, nAssets);
for n = 1 : nPeriods
    first = firstDayList(n);
    last = lastDayList(n);
    aggregatedReturns(n, :) = prod(1 + originalReturns(first : last, :)) - 1;
end

f = aggregatedReturns;