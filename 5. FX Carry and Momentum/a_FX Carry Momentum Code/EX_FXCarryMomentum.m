%%%%% 5.a. FX Carry Momentum %%%%
% Computes the returns from currency carry trade 
% and 1-month momentum strategies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO:
% 0) EX_prepareFXData_sync.m
% - load monthly data
%       - readtable & table2timetable & synchronize them
%       - get dates
% - Compute the return earned on the riskless asset each month
%   (bcs. annual rate)
% - Perform the rollover of the futures contracts = dailyXsReturns
% - Compute monthly returns
%       - with daily futures rebalancing
%       - without daily futures reblancing
% - Plot cumulative return lines using daily excess and total returns.
%   (not required)
%
% 1) Annualized performance statistics of different pf strategie
% - Compute monthly portfolio weights for 3 strategies
%       - Identify first and last day of each month	
%       - Array for the x-axis in the monthly plots
%       - Compute return in each month, honoring any trading lag, and
%         obtain the portfolio weights by sorting on interest rates and 
%         past returns.
%       - Get weights and returns in sync
% - Annualized performance statistics **
%
% 2) Plot portfolio values of different strategies
% - Compute cumulative returns using total returns and not excess returns
% - Plot value of pf for different strategies (log y axis)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General:
% - 4 strategies:
%       - Long all foreign countries (equally weighted)
%       - Momentum: long 3 currencies with best return in prev. month
%                   short 3 currencies with worst return
%       - Carry: long 3 currencies with highest interest rate
%                short 3 currencies with lowest interest rate
%       - Combined: 50/50 momentum and carry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 0) Loading Data

% Parameter selection
annualizationFactor = 12;   % Annualization factor for monthly to annual
lag = 1;                    % 0: same-day trading; 1: one-day lag
nLongs = 3;                 % Number of currencies held long
nShorts = 3;                % Number of currencies held short

% Setting to compute monthly futures excess returns
% rebalanceDaily = 1 if the futures positions are rebalanced daily.
% rebalanceDaily = 0 if the futures positions are held constant during
% the month. In this case we account for the daily MTM gains/losses.
rebalanceDaily = 0;

% Loads the FX data, computes the daily and monthly returns on the futures contracts
% Plots the returns on the different currencies 
EX_prepareFXData_sync;


%% 1) Annualized performance statistics of different pf strategie

%%% Compute monthly portfolio weights for 3 strategies
% Use interest rates and past returns to construct the portfolio weights

% Identify first and last trading day of each month
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);
nMonths = length(firstDayList)

% Array for the x-axis in the monthly plots
dates4FigMonthly = dates4Fig(lastDayList);


% Compute the return in the month, honoring any trading lag, and
% obtain the portfolio weights by sorting on interest rates and past returns.
equalWeights = ones(nMonths, nAssets) / nAssets;
carryWeights = zeros(nMonths, nAssets);
momWeights = zeros(nMonths, nAssets);

for m = 1 : nMonths
    first = max(firstDayList(m) - lag, 1);
    last = lastDayList(m) - lag;
    monthlyRet = prod(1 + dailyXsReturns(first : last, :));
    carryWeights(m, :) = computeSortWeights(intRates(last, :), nLongs, nShorts, 1); % takes last day of month IR for each currency
    momWeights(m, :) = computeSortWeights(monthlyRet, nLongs, nShorts, 1);
end

% Get weights and returns in sync
% Drop the first month from the return series and the last month from the
% portfolio weights series 
dates4FigMonthly = dates4FigMonthly(2 : nMonths, 1);
monthlyXsReturns = monthlyXsReturns(2 : nMonths, :);
monthlyTotalReturns = monthlyTotalReturns(2 : nMonths, :);
monthlyRf = monthlyRf(2 : nMonths, 1);
equalWeights = equalWeights(1 : nMonths - 1, :);
carryWeights = carryWeights(1 : nMonths - 1, :);
momWeights = momWeights(1 : nMonths - 1, :);
nMonths = nMonths - 1;


%%% Compute the strategy returns
allXsReturns = zeros(nMonths, 4);
allXsReturns(:, 1) = sum(monthlyXsReturns .* equalWeights, 2);
allXsReturns(:, 2) = sum(monthlyXsReturns .* carryWeights, 2);
allXsReturns(:, 3) = sum(monthlyXsReturns .* momWeights, 2);
allXsReturns(:, 4) = (allXsReturns(:, 2) + allXsReturns(:, 3)) / 2;
allTotalReturns = allXsReturns + monthlyRf * ones(1, size(allXsReturns, 2));
xsReturnCorrels = corrcoef(allXsReturns)

%%% Compute Performance statistics
summarizePerformance(allXsReturns, monthlyRf, allXsReturns(:, 1), annualizationFactor, 'Currency (EW, Carry, Momentum, 50/50 Combination)');


%% 2) Plot portfolio values of different strategies

% Compute cumulative returns using total returns and not excess returns
monthlyStrategyNAV = cumprod(1 + allTotalReturns);

% Plot using log y axis
figure
semilogy(dates4FigMonthly, monthlyStrategyNAV(:, 1), 'k-', ...
    dates4FigMonthly, monthlyStrategyNAV(:, 2), 'b--', ...
    dates4FigMonthly, monthlyStrategyNAV(:, 3), 'r:', ...
    dates4FigMonthly, monthlyStrategyNAV(:, 4), 'm-.')
xlabel('Year')
ylabel('Portfolio Value') 
legend('EW', 'Carry', 'Momentum', '50/50 Combination', 'Location', 'SouthEast')
%set(gcf, 'Position', [200, 200, 800, 600])
saveas(gcf,'Portfolio_Values.png')




