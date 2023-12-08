%%%%% 5.b. FX Carry and Momemntum: Scoring and Timing %%%%
% Computes the returns from a scoring model using
% carry and 1-month momentum to rank currencies. 
% In addition, times exposure based on the VIX level.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO:
% 0) EX_prepareFXData_sync.m (same as in 5a.)
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
% - Load the VIX data
%       - Load the VIX data and convert the table to timetable 
%       - Synchronize with the currency data and fill the NaNs
%       - Generate a numeric date for VIX data
% - Compute monthly portfolio weights for 4 strategies
%       - Identify first and last trading day of each month
%       - Array for the x-axis in the monthly plots
%       - Compute scores and returns
%       - Get weights and returns in sync
%       - Compute the strategy returns
% - Annualized performance statistics **
%
% 2) Plot portfolio values of different strategies
% - Compute cumulative returns using total returns and not excess returns
% - Plot value of pf for different strategies (log y axis)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General: Extensions
% - 4 Strategies:
%       1 Long all foreign currencies, with total exposure of 1 always (EW)
%       2 Timed EW strategy: rescales the weights from strategy (1) using 
%         the ratio 20/VIX (VIX level at time of construction)
%       3 Scoring strategy: long currencies with a positive overall score 
%         and short those with a negative overall score, 
%         with total long and short exposures of 1 and -1 always
%         -> Score 1: top and bottom 3 currencies at end of each month 
%                     based on the level of interest rates get a carry score 
%                     of +1 and –1
%         -> Score 2: same for momentum
%       4 Scoring timed strategy: rescales the weights from strategy (3) 
%         using the ratio 20/VIX (VIX level at time of construction)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 0) Loading Data

% Parameter selection
annualizationFactor = 12;   % Annualization factor for monthly to annual
lag = 1;                    % 0: same-day trading; 1: one-day lag
nLongs = 3;                 % Number of currencies held long
nShorts = 3;                % Number of currencies held short
avgVIX = 20;                % Long-term average VIX level

% Setting to compute monthly futures excess returns
% rebalanceDaily = 1 if the futures positions are rebalanced daily.
% rebalanceDaily = 0 if the futures positions are held constant during
% the month. In this case we account for the daily MTM gains/losses.
rebalanceDaily = 0;

% Loads the FX data, computes the daily and monthly returns on the futures contracts
% Plots the returns on the different currencies 
EX_prepareFXData_sync;


%% 1) Annualized performance statistics of different pf strategie

%%% Load the VIX data

% Load the VIX data and convert the table to timetable so we can synchronize
VIXTable = readtable('VIX.xls');
VIXTable = table2timetable(VIXTable);
% In case the dates are loaded as strings, you would convert them to dates
% using the following:
% VIXTable.Date = datetime(VIXTable.Date, 'InputFormat', 'dd.MM.yyyy');

% Synchronize with the currency data and fill the NaNs
mergedTableWithVIX = synchronize(mergedTable, VIXTable, 'first');
mergedTableWithVIX = fillmissing(mergedTableWithVIX, 'previous');
VIXPrices = mergedTableWithVIX.VIXIndex;

% Generate a numeric date for VIX data
% We need to do this because the market holidays are not the same for 
% equity options and currency futures.
datesVIX = yyyymmdd(VIXTable.Date);

%%% Compute monthly portfolio weights for 4 strategies

% Use interest rates and past returns to give an overall score to currencies
% and construct the portfolio based on the overall score.

% Identify first and last trading day of each month
% We need an array for VIX to make sure we have the same number of months.
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);
[firstDayListVIX, lastDayListVIX] = getFirstAndLastDayInPeriod(datesVIX, 2);
nMonths = length(firstDayList)
if (length(firstDayListVIX) ~= nMonths)
    disp('Warning: FX and VIX data do not have the same number of months');
end

% Array for the x-axis in the monthly plots
dates4FigMonthly = dates4Fig(lastDayList);

% Compute the return in the month, honoring any trading lag, and
% obtain the carry and momentum scores by sorting on interest rates and 
% past returns. Then compute the overall score and equal weight assets with
% a positive total score and those with a negative total score.
carryScore = zeros(nMonths, nAssets);
momScore = zeros(nMonths, nAssets);
totalScore = zeros(nMonths, nAssets);
equalWeightsRaw = ones(nMonths, nAssets) / nAssets;
equalWeightsTimed = ones(nMonths, nAssets) / nAssets;
pfWeightsRaw = zeros(nMonths, nAssets);
pfWeightsTimed = zeros(nMonths, nAssets);
scale = zeros(nMonths, 1);

for m = 1 : nMonths
    first = max(firstDayList(m) - lag, 1);
    last = lastDayList(m) - lag;
    monthlyRet = prod(1 + dailyXsReturns(first : last, :));
    
    % Compute carry and momentum scores
    carryScore(m, :) = getScore(intRates(last, :), nLongs, nShorts, 1);
    momScore(m, :) = getScore(monthlyRet, nLongs, nShorts, 1); % highest return during last month
    
    % Compute total score and form the portfolio
    totalScore(m, :) = carryScore(m, :) + momScore(m, :);
    pfWeightsRaw(m, :) = computeScoreWeights(totalScore(m, :));

    % Timing component
    scale(m) = avgVIX / VIXPrices(last);
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

%%% Performance statistics
summarizePerformance(allXsReturns, monthlyRf, allXsReturns(:, 1), annualizationFactor, 'EW, EW Timed, Scoring, Scoring Timed');


%% 2) Plot portfolio values of different strategies

% Compute cumulative returns using total returns and not excess returns
monthlyStrategyNAV = cumprod(1 + allTotalReturns);

% Plot
figure
semilogy(dates4FigMonthly, monthlyStrategyNAV(:, 1), 'k-', ...
    dates4FigMonthly, monthlyStrategyNAV(:, 2), 'b--', ...
    dates4FigMonthly, monthlyStrategyNAV(:, 3), 'r:', ...
    dates4FigMonthly, monthlyStrategyNAV(:, 4), 'm-.')
xlabel('Year'), ylabel('Portfolio Value') 
legend('EW Constant Exposure', 'EW Timed', 'Scoring Constant Exposure', 'Scoring Timed', 'Location', 'SouthEast')
%set(gcf, 'Position', [200, 200, 800, 600])
saveas(gcf,'Portfolio_Values.png')
