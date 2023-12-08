% prepareFXData: Loads the FX data and computes daily and monthly returns

% Load the four tabs of the file
fileName = 'FXCarryMomentumData.xls';
tickerTable = readtable(fileName, 'Sheet', 'FrontMonthTickers');
frontTable = readtable(fileName, 'Sheet', 'FrontMonthPrices');
backTable = readtable(fileName, 'Sheet', 'BackMonthPrices');
intTable = readtable(fileName, 'Sheet', 'InterestRates');


% Convert the tables to timetables and sync them
% Note: in case the dates are loaded as strings, you would first
% convert the first column of each table to dates using the following:

% dateFormat = 'dd.MM.yyyy';
% tickerTable.Date = datetime(tickerTable.Date, 'InputFormat', dateFormat);
% frontTable.Date = datetime(frontTable.Date, 'InputFormat', dateFormat);
% backTable.Date = datetime(backTable.Date, 'InputFormat', dateFormat);
% intTable.Date = datetime(intTable.Date, 'InputFormat', dateFormat);
tickerTable = table2timetable(tickerTable);
frontTable = table2timetable(frontTable);
backTable = table2timetable(backTable);
intTable = table2timetable(intTable);
% all tables have same dates
mergedTable = synchronize(tickerTable, frontTable, backTable, intTable);


% Generate arrays with the different variables
tickers = table2array(mergedTable(:, 1 : 7));
frontPrices = table2array(mergedTable(:, 8 : 14));
backPrices = table2array(mergedTable(:, 15 : 21));
intRates = table2array(mergedTable(:, 22 : 29));


% Extract the USD interest rate since it will be our riskless rate, and drop
% it from the main interest rates array so it has the same size as the others 
Rf = intRates(:, end) / 100; 
intRates = intRates(:, 1 : end - 1) / 100;


% Size of the dataset
nDays = length(frontPrices);
nAssets = size(frontPrices, 2);


% Extract dates for the x-axis of the figures and generate numeric dates 
% in the format YYYYMMDD so that we can reuse the functions we developed previously.
dates4Fig = mergedTable.Date;       % mergedTable.Date is already datetime
datesNumeric = datenum(dates4Fig);
dates = yyyymmdd(dates4Fig);
% An alternative is to say: [yr, mth, dy] = datevec(datesNumeric); 
%                           dates = 10000 * yr + 100 * mth + dy;


% Rescale the riskless rate to account for the number of calendar days 
% until the next trading day and shift it down by one trading day so that 
% it represents the return accrued on that day
dayCount = diff(datesNumeric);
% Same as: dayCount = datesNumeric(2 : end, 1) - datesNumeric(1 : end - 1, 1);
RfScaled = zeros(nDays, 1);
RfScaled(2 : end, 1) = Rf(1 : end - 1, 1) .* dayCount / 360;


% Perform the rollover of the futures contracts
% test with the next line
%dailyFutReturns = rolloverFutures(frontPrices(3902 : 3906, :), backPrices(3902 : 3906, :), tickers(3902 : 3906, :));
dailyXsReturns = rolloverFutures(frontPrices, backPrices, tickers);
dailyTotalReturns = dailyXsReturns + RfScaled * ones(1, nAssets);


% Obtain monthly returns, with or without rebalancing
if (rebalanceDaily)
    monthlyRf = aggregateReturns(RfScaled, dates, 2);
    monthlyTotalReturns = aggregateReturns(dailyTotalReturns, dates, 2);
    monthlyXsReturns = monthlyTotalReturns - monthlyRf * ones(1, nAssets);    
else
    [monthlyTotalReturns, monthlyXsReturns, monthlyRf] = aggregateFutXsReturns(dailyXsReturns, RfScaled, dates, 2);
end


% Plot cumulative return lines using daily excess and total returns.
% This was not required in the question but it's a good idea to look at the data.

% Compute cumulative returns
cumXsReturns = cumprod(1 + dailyXsReturns);
cumTotalReturns = cumprod(1 + dailyTotalReturns);

% Plot them
figure
subplot(2, 1, 1), plot(dates4Fig, cumXsReturns(:, 1), 'k-', dates4Fig, cumXsReturns(:, 2), 'b-', dates4Fig, cumXsReturns(:, 3), 'r-')
hold on
plot(dates4Fig, cumXsReturns(:, 4), 'k--', dates4Fig, cumXsReturns(:, 5), 'b--', dates4Fig, cumXsReturns(:, 6), 'r--')
plot(dates4Fig, cumXsReturns(:, 7), 'k:'),
    xlabel('Year'), ylabel('Cumulative Excess Return'), 
    legend('EUR', 'JPY', 'GBP', 'AUD', 'CHF', 'CAD', 'NZD', 'Location', 'NorthWest')

subplot(2, 1, 2), plot(dates4Fig, cumTotalReturns(:, 1), 'k-', dates4Fig, cumTotalReturns(:, 2), 'b-', dates4Fig, cumTotalReturns(:, 3), 'r-')
hold on
plot(dates4Fig, cumTotalReturns(:, 4), 'k--', dates4Fig, cumTotalReturns(:, 5), 'b--', dates4Fig, cumTotalReturns(:, 6), 'r--')
plot(dates4Fig, cumTotalReturns(:, 7), 'k:'),
    xlabel('Year'), ylabel('Cumulative Total Return'), 
    legend('EUR', 'JPY', 'GBP', 'AUD', 'CHF', 'CAD', 'NZD', 'Location', 'NorthWest')

saveas(gcf,'Cumulative_future_return.png')
