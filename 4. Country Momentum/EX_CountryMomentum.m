 %%%%% 4. Carry Momentum with Transaction Costs%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO:
% - load monthly data
%
% 1) Annualized performance statistics of different pf strategie
% - Compute monthly returns
%       - Compute monthly ETF (total) returns
%       - Compute the return earned on the riskless asset each month
%         (bcs. annual rate)
% - Compute monthly portfolio weights for 3 strategies...
%       - ...for equally weighted and momentum portfolios
%       - Get weights and returns in sync
% - Compute monthly strategy returns
%       - w/o TC
%       - with TC
%       - Consolidate returns in a single array
% - Annualized performance statistics **
%
% 2) Plot portfolio values of different strategies
% - Compute portfolio values using total returns and not excess returns
% - Plot value of pf for different strategies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General:
% - selects countries based on their past returns
%     - prices of country ETF (USD, adj. for dividends)
%     - one-month USD interest rate (annual rate)
%     - changing number of countries over time
% - long-short pfs of many assets
% - 3 strategies (all equally weighted):
%     - all country ETFs available on trade date
%     - long the five country ETFs that had the highest returns from 
%       12 months to one month before portfolio formation
%     - long the top five countries and short the bottom five
% - monthly rebalancing
% - monthly returns for perf. statistics
% - no trading lag
% - data: March 1996 through October 2022
%     - first pf: end of March 1997 (1y look-back)
% - impact of TC on returns, 2 Cases:
%     - returns w/o TC
%     - returns (one-way) proportional TC of c=0.001 (0.1%)
%     -> return in each period - c * turnover at the end of that period
%     -> turnover: |w - ^w|'1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Loading Data

% Parameter selection
annualizationFactor = 12; % Annualization factor for monthly to annual
nLongs = 5;               % Number of countries held long 
nShorts = 5;              % Number of countries held short
tCost = 0.001;            % Proportional transaction costs

lookbackStart = 12;       % Momentum lookback period (start and end of window, as positive numbers;
lookbackEnd = 1;          % start must be greater than end)

% Load the data and extract the dates, riskless rate, and ETF prices
data = readtable('CountryData.xls', 'Format', 'auto', 'TreatAsEmpty', {'#N/A N/A'});
ETFDates = data.('Date');                   % Same as saying: ETFDates = data.Date;
Rf = data.('USD1MonthRate') / 100;
ETFPrices = table2array(data(:, 3 : end));  % Same as saying: ETFPrices = data{:, 3 : end};

% Size of the dataset
nMonths = length(ETFDates)
nAssets = size(ETFPrices, 2)

% Process the dates: Get numeric dates and generate a vector for the plot x-axis
% datesNumeric = datenum(ETFDates, 'dd.MM.yyyy');   
% dates4Fig = datetime(ETFDates, 'InputFormat', 'dd.MM.yyyy');     
datesNumeric = datenum(ETFDates);   
dates4Fig = datetime(ETFDates);   

% Perhaps make NaNs zeros
%ETFPrices(isnan(ETFPrices)) = 0;
%-> no because we use "isfinite" later!


%% 1) Annualized performance statistics of different pf strategie

%%% Compute monthly returns

% Compute monthly ETF returns (=Total Returns!)
ETFReturns = zeros(nMonths, nAssets);
ETFReturns(2 : end, :) = ETFPrices(2 : end, :) ./ ETFPrices(1 : end - 1, :) - 1;

% Compute the return earned on the riskless asset each month
% because one-month USD interest rate is an annual rate
% accounting for the number of calendar days until the end of the 
% next month. Shift the result down by one month so that it represents 
% the return accrued during that month
dayCount = diff(datesNumeric);
% Same as: dayCount = datesNumeric(2 : end, 1) - datesNumeric(1 : end - 1, 1);
RfMonthly = zeros(nMonths, 1);
RfMonthly(2 : end, 1) = Rf(1 : end - 1, 1) .* dayCount / 360;

%%% Compute monthly portfolio weights for 3 strategies

% Construct equally weighted and momentum portfolios
% For equally weighted portfolios, find out which country ETFs are available
% in a given month.
% For the momentum portfolios, issues arising with missing data are handled
% in the computeSortWeights function.
equalWeights = zeros(nMonths, nAssets);
momLongWeights = zeros(nMonths, nAssets);
momLSWeights = zeros(nMonths, nAssets);

firstMonth = lookbackStart + 1;
for month = firstMonth : nMonths    % 13:320  
    % Equally weighted portfolio
    nonMissings = isfinite(ETFPrices(month, :));
    equalWeights(month, :) = nonMissings / sum(nonMissings);
    % Momentum portfolios, long only and long/short
    pastReturns = ETFPrices(month - lookbackEnd, :) ./ ETFPrices(month - lookbackStart, :) - 1; % ETF return in last year
    momLongWeights(month, :) = computeSortWeights(pastReturns, nLongs, 0, 1);
    momLSWeights(month, :) = computeSortWeights(pastReturns, nLongs, nShorts, 1);
end

% Get weights and returns in sync
% -> drop firstMonth (13) months from the beginning of the return series, 
% -> drop (firstMonth - 1 = 12) months from the beginning of the 
%    portfolio weight series. 
% -> We keep one extra month at the end of the portfolio weights series 
%    for the turnover computations later.
dates4Fig = dates4Fig(firstMonth + 1 : end, 1);
ETFReturns = ETFReturns(firstMonth + 1 : end, :);
RfMonthly = RfMonthly(firstMonth + 1 : end, 1);
equalWeights = equalWeights(firstMonth : end, :);
momLongWeights = momLongWeights(firstMonth : end, :);
momLSWeights = momLSWeights(firstMonth : end, :);
nMonths = nMonths - firstMonth;

%%% Compute monthly strategy returns

% w/o TC

% First, we need to replace the NaNs with zeros.
% Note that for the long/short version, we need to add the riskless asset return.
% We're using R_p = w' * R + (1 - w' * 1) * Rf for all portfolios.
% For the long-only portfolios, (1 - w' * 1) = 0 so the second term vanishes.
% For the long-short portfolio, (1 - w' * 1) = 1 so we just add Rf.
% (ETFReturns = Total Returns!)
ETFReturns(isnan(ETFReturns)) = 0;
stratReturnsNoTC = zeros(nMonths, 3);
stratReturnsNoTC(:, 1) = sum(ETFReturns .* equalWeights(1 : end - 1, :), 2);
stratReturnsNoTC(:, 2) = sum(ETFReturns .* momLongWeights(1 : end - 1, :), 2);
stratReturnsNoTC(:, 3) = sum(ETFReturns .* momLSWeights(1 : end - 1, :), 2) + RfMonthly;

% with TC

% -> returns of each strategy - turnover * proportional transaction costs 
turnover = zeros(nMonths, 3);
for month = 1 : nMonths
    currentRf = RfMonthly(month, 1);
    currentRet = ETFReturns(month, :);
    turnover(month, 1) = computeTurnover(equalWeights(month, :), equalWeights(month + 1, :), currentRet, currentRf);
    turnover(month, 2) = computeTurnover(momLongWeights(month, :), momLongWeights(month + 1, :), currentRet, currentRf); 
    turnover(month, 3) = computeTurnover(momLSWeights(month, :), momLSWeights(month + 1, :), currentRet, currentRf); 
end
% Adding the transactions in the initial month (This is splitting hair a little bit)
turnover(1, 1 : 2) = turnover(1, 1 : 2) + 1; % equally & long-only
turnover(1, 3) = turnover(1, 3) + 2;         % long-short
avgTurnover = mean(turnover)
stratReturnsTC = stratReturnsNoTC - tCost * turnover;
    
% Consolidate the returns in a single array
allTotalReturns = [stratReturnsNoTC stratReturnsTC];
allXsReturns = allTotalReturns - RfMonthly * ones(1, size(allTotalReturns, 2));


%%% Annualized performance statistics **

% benchmark is equally weighted portfolio of all available countries, 
% stored in allXsReturns(:, 1))
summarizePerformance(allXsReturns, RfMonthly, allXsReturns(:, 1), annualizationFactor, 'Country Strategies (Equally Weighted, Momentum Long Only, Momentum Long/Short), without and with transaction costs');




%% 2) Plot portfolio values of different strategies

% Compute portfolio values (Cumulative returns) using total returns 
% and not excess returns
strategyNAV = cumprod(1 + allTotalReturns);

% Plot value of pf for different strategies
figure
plot(dates4Fig, strategyNAV(:, 1), 'k-', ...
    dates4Fig, strategyNAV(:, 2), 'b-', ...
    dates4Fig, strategyNAV(:, 3), 'r-')
hold on
plot(dates4Fig, strategyNAV(:, 4), 'k--', ...
    dates4Fig, strategyNAV(:, 5), 'b--', ...
    dates4Fig, strategyNAV(:, 6), 'r--')
xlabel('Year')
ylabel('Portfolio Value') 
legend('Equally Weighted', 'Momentum Long Only', 'Momentum Long/Short', 'Equally Weighted, TC', 'Mom. Long Only, TC', 'Mom. Long/Short, TC', 'Location', 'NorthWest')
saveas(gcf,'Portfolio_Values.png')
