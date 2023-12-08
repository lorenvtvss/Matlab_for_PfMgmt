%%%%% 3. Market Timing %%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO:
% - load daily data
%
% 1) Plot cumulative total and excess return of 3 factors
% - compute factor cumulative total and excess returns
% - Plot cumulative total and excess return of 3 factors (log y)
%
% 2) Annualized performance statistics of different pf strategies
%   (portfolio: End of July 1926)
%   (holding period: one month)
%   (use monthly returns to compute the performance statistics)
%
% - Obtain monthly return variances to construct portfolio weights
%       - Identify first and last day of each month
%       - Array for the x-axis in the monthly plots
%       - Compute the return variance from daily returns
% - Obtain monthly returns
%       - Load from file or Aggregate the daily returns to monthly
% - Compute portfolio weights
%       - Drop the first month from the return series and the last month from the
%         variance series to have weights and returns in sync
%       - Compute portfolio weights: IS & OOS strategy
%       - Compute strategy returns: IS & OOS strategy
%       - Rescale in-sample strategy to match the benchmark unconditional standard deviations
% - Annualized performance statistics
%
% 3) Plot portfolio values of different strategies
% - Compute portfolio values using total returns and not excess returns
% - Plot value of pf for different strategies (log y)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General:
% - use hist. var to scale investmen in factors for next month 
%   (high var -> reduce exposure) --> compute weights
% - Strategy weights: 
%       - Unconditional:    100%
%       - IS Timing:        avg.var/var.lastmonth [1/var.lastmonth] -> 2 cases
%       - OOS Timing:       avg.hist.trailing.variances/var.lastmonth -> 2 cases
%                           (exposure cap of 2)
% - 2 Cases:
%     - We can trade right away:  
%         -> use daily returns from July 1 to July 31 to estimate variance, 
%            and use this value to decide how much to invest at the close on July 31
%     - One-day trading lag:
%         -> use daily returns from June 30 to July 30 to estimate variance
%  	       and use this value to decide how much to invest on July 31
% - Calculate performance statistics:
%       - monthly strategy returns (factor returns & pf weights)
%       - rescale in-sample strategies to match BM's unconditional std.dev
%       - compute BM and strategy performance statistics for each factor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 1) Loading Data

% Parameter selection
lag = 1;    % 0: same-day trading, 1: one-day lag
cap = 2;    % OOS Timing exposure cap

monthlyDataFromFile = 0; % Whether to load the monthly returns from file or compute them
annualizationFactor = 12; % Annualization factor for monthly to annual

% Load data
data = xlsread('FFDaily.xls','Sheet1');

% Extract data 
dates = data(:, 1);
dates4Fig = datetime(dates, 'ConvertFrom', 'yyyymmdd');
f_xs_returns = data(:, 2 : 4) / 100;
Rf = data(:, 5) / 100;
f_total_returns = f_xs_returns + Rf;

nDays = length(dates);
nFactors = size(f_xs_returns, 2);

%% 2) Plot cumulative total and excess return of 3 factors

% Compute cumulative total and excess returns
f_total_returns_cum = cumprod(1 + f_total_returns);
f_xs_returns_cum = cumprod(1 + f_xs_returns);

% Plot cumulative total and excess return
subplot(2, 1, 1), semilogy(dates4Fig, f_total_returns_cum(:, 1), 'k-', dates4Fig, f_total_returns_cum(:, 2), 'b--', dates4Fig, f_total_returns_cum(:, 3), 'r:'), 
    ylabel('Cumulative Total Return'), 
    legend('BM Market', 'BM Size', 'BM Value', 'Location', 'NorthWest')
subplot(2, 1, 2), semilogy(dates4Fig, f_xs_returns_cum(:, 1), 'k-', dates4Fig, f_xs_returns_cum(:, 2), 'b--', dates4Fig, f_xs_returns_cum(:, 3), 'r:'), 
    xlabel('Year'), ylabel('Cumulative Excess Return'), 
    legend('BM Market - Rf', 'BM Size', 'BM Value', 'Location', 'NorthWest') 
%set(gcf, 'Position', [200, 200, 800, 600])   
saveas(gcf,'Cum_BM_returns.png')


%% 3) Performance statistics of different pf strategies

%%% Obtain monthly return variances to construct portfolio weights

% Identify first and last day of each month
[firstDayList, lastDayList] = getFirstAndLastDayInPeriod(dates, 2);

% Array for the x-axis in the monthly plots
monthlyDates4Fig = dates4Fig(lastDayList);

% Compute the return variance from daily returns
nMonths = length(firstDayList)
monthlyVar = zeros(nMonths, nFactors);
for month = 1 : nMonths
    first = max(firstDayList(month) - lag, 1);
    last = lastDayList(month) - lag;
    monthlyVar(month, :) = var(f_xs_returns(first : last, :));    
end

%%% Obtain monthly returns

% Two options:
% 1) Load from file 
if (monthlyDataFromFile)
    monthlyData = xlsread('FFMonthly.xls', 'Sheet1');
    monthlyDates = monthlyData(:, 1);
    monthlyXsReturns = monthlyData(:, 2 : 4) / 100;
    monthlyRf = monthlyData(:, 5) / 100;
    monthlyTotalReturns = monthlyXsReturns + monthlyRf * ones(1, nFactors);
else
% 2) Aggregate the daily returns to monthly
    monthlyTotalReturns = aggregateReturns(f_total_returns, dates, 2);
    monthlyRf = aggregateReturns(Rf, dates, 2);
    monthlyXsReturns = monthlyTotalReturns - monthlyRf * ones(1, nFactors);
end

%%% Compute portfolio weights

% Drop the first month from the return series and the last month from the
% variance series to have weights and returns in sync
monthlyDates4Fig = monthlyDates4Fig(2 : nMonths, 1);
monthlyVar = monthlyVar(1 : nMonths - 1, :);
monthlyXsReturns = monthlyXsReturns(2 : nMonths, :);
monthlyTotalReturns = monthlyTotalReturns(2 : nMonths, :);
monthlyRf = monthlyRf(2 : nMonths, 1);
nMonths = nMonths - 1;

% Compute portfolio weights: IS & OOS strategy
    % In-sample (mean/var instead of 1/var!)
monthlyWeights = (ones(nMonths, 1) * mean(monthlyVar)) ./ monthlyVar;
    % OOS
monthlyWeightsOOS = zeros(nMonths, nFactors);
for month = 1 : nMonths
    trailingVar = mean(monthlyVar(1 : month, :), 1);
    monthlyWeightsOOS(month, :) = min(trailingVar ./ monthlyVar(month, :), cap);
end

% Compute strategy returns: IS & OOS strategy
monthlyStrategyXsReturns = monthlyXsReturns .* monthlyWeights;
monthlyStrategyXsReturnsOOS = monthlyXsReturns .* monthlyWeightsOOS;
monthlyStrategyTotalReturnsOOS = monthlyStrategyXsReturnsOOS + monthlyRf * ones(1, nFactors);

% Rescale in-sample strategy to match the benchmark unconditional standard deviations
benchmarkStd = std(monthlyXsReturns);
strategyStd = std(monthlyStrategyXsReturns);
scaling = benchmarkStd ./ strategyStd;
monthlyWeights = monthlyWeights .* (ones(nMonths, 1) * scaling);
monthlyStrategyXsReturns = monthlyXsReturns .* monthlyWeights;
monthlyStrategyTotalReturns = monthlyStrategyXsReturns + monthlyRf * ones(1, nFactors);

%%% Performance statistics (for each return factor!)

% 3 strategies: [BM bzw. Factors, Strategies IS, Strategies OOS]
allMonthlyXsReturns = [monthlyXsReturns, monthlyStrategyXsReturns, monthlyStrategyXsReturnsOOS];
summarizePerformance(allMonthlyXsReturns, monthlyRf, monthlyXsReturns, annualizationFactor, 'Benchmark (3 cols) / Strategy (3 cols) / Strategy OOS (3 cols)');


%% 3) Plot portfolio values of different strategies

% Compute portfolio values using total returns and not excess returns
monthlyBenchmarkNAV = cumprod(1 + monthlyTotalReturns);
monthlyStrategyNAV = cumprod(1 + monthlyStrategyTotalReturns);
monthlyStrategyNAVOOS = cumprod(1 + monthlyStrategyTotalReturnsOOS);

% Plot
figure
semilogy(monthlyDates4Fig, monthlyBenchmarkNAV(:, 1), 'k-', ...
    monthlyDates4Fig, monthlyBenchmarkNAV(:, 2), 'b-', ...
    monthlyDates4Fig, monthlyBenchmarkNAV(:, 3), 'r-')
hold on
semilogy(monthlyDates4Fig, monthlyStrategyNAV(:, 1), 'k--', ...
    monthlyDates4Fig, monthlyStrategyNAV(:, 2), 'b--', ...
    monthlyDates4Fig, monthlyStrategyNAV(:, 3), 'r--'),
semilogy(monthlyDates4Fig, monthlyStrategyNAVOOS(:, 1), 'k-.', ...
    monthlyDates4Fig, monthlyStrategyNAVOOS(:, 2), 'b-.', ...
    monthlyDates4Fig, monthlyStrategyNAVOOS(:, 3), 'r-.')
xlabel('Year')
ylabel('Portfolio Value')
legend('BM Market', 'BM Size', 'BM Value', 'Timed Market', 'Timed Size', 'Timed Value', 'Timed Market OOS', 'Timed Size OOS', 'Timed Value OOS', 'Location', 'NorthWest')
hold off
%set(gcf, 'Position', [200, 200, 800, 600]) 
saveas(gcf,'Pf_values.png')


