% Class code for country momentum
clc
clear
close all

% Parameter selection
% Annualization factor for monthly to annual
annualizationFactor = 12;
% Transaction costs
c = 0.001;
% Number of longs and shorts
nLongs = 5;
nShorts = 5;
% Lookback period
lookbackStart = 12;
lookbackEnd = 1;


% Load the data
% NOTE: The behavior of the readtable command changed. In previous releases the following worked:
% dataTable = readtable('CountryData.xls', 'TreatAsEmpty', {'#N/A N/A'});
% With the latest release one should in addition specify 'Format', 'auto' in readtable

% instead of specifying 'Format', 'auto' :
% dT = readtable('CountryData.xls', 'TreatAsEmpty', {'#N/A N/A'})
% numbers = table2array(dT(:,2:25));
% strings = table2array(dT(:,26:30));
% converted = str2double(strings);
% merged = [numbers converted];

dataTable = readtable('CountryData.xls', 'Format', 'auto', 'TreatAsEmpty', {'#N/A N/A'});

% Extract the dates
dates = dataTable.('Date');
dates4Fig = datetime(dates, 'InputFormat', 'dd.MM.yyyy');
datesNumeric = datenum(dates4Fig);

% Extract Rf
Rf = table2array(dataTable(:, 2)) / 100;

% Extract ETF prices
% Given the issues with loading we faced in class we had to use the following:
%numbers = table2array(dataTable(:, 3 : 25));
%strings = table2array(dataTable(:, 26 : 30));
%converted = str2double(strings);
%ETFPrices = [numbers converted];
% Specifying 'Format', 'auto' in readtable (as is done above) resolves the formatting issue, then one can just use: 
ETFPrices = table2array(dataTable(:, 3 : 30));

nMonths = length(datesNumeric);
nAssets = size(ETFPrices, 2);

% Compute the returns
ETFReturns = zeros(nMonths, nAssets);
ETFReturns(2 : end, :) = ETFPrices(2 : end, :) ./ ETFPrices(1 : end - 1, :) - 1;

% Return on riskless asset
daysForInterest = diff(datesNumeric);
RfMonthly = zeros(nMonths, 1);
RfMonthly(2 : end, 1) = Rf(1 : end - 1, 1) .* daysForInterest / 360;

% Compute portfolio weights
equalWeights = zeros(nMonths, nAssets);
momLongWeights = zeros(nMonths, nAssets);
momLSWeights = zeros(nMonths, nAssets);
firstMonth = lookbackStart + 1;
for month = firstMonth : nMonths
    % EW
    nonMissings = isfinite(ETFPrices(month, :));
    equalWeights(month, :) = nonMissings / sum(nonMissings);
    
    % Momentum
    pastReturns = ETFPrices(month - lookbackEnd, :) ./ ETFPrices(month - lookbackStart, :) - 1;
    [~, winners] = maxk(pastReturns, nLongs);
    [~, losers] = mink(pastReturns, nShorts);
    momLongWeights(month, winners) = 1 / nLongs;
    momLSWeights(month, winners) = 1 / nLongs;
    momLSWeights(month, losers) = -1 / nShorts;  
end


% Compute returns before TC
% if this here: 
ETFReturns(isnan(ETFReturns)) = 0;
% OmitNan useless
EWReturns = 1 + sum(ETFReturns(2 : end, :) .* equalWeights(1 : end - 1, :), 2, 'OmitNaN');
MomLongReturns = 1 + sum(ETFReturns(2 : end, :) .* momLongWeights(1 : end - 1, :), 2, 'OmitNaN');
MomLSReturns = 1 + sum(ETFReturns(2 : end, :) .* momLSWeights(1 : end - 1, :), 2, 'OmitNaN') + RfMonthly(2 : end, 1);
% R_p = w' * R + (1 - w' * 1) * Rf

% Compute turnover
%EW_WeightChange = equalWeights(2 : end, :) - equalWeights(1 : end - 1, :);
EW_WeightChange = zeros(nMonths - 1, nAssets);
MomLong_WeightChange = zeros(nMonths - 1, nAssets);
MomLS_WeightChange = zeros(nMonths - 1, nAssets);
EW_Turnover = zeros(nMonths - 1, 1);
MomLong_Turnover = zeros(nMonths - 1, 1);
MomLS_Turnover = zeros(nMonths - 1, 1);
ETFReturns(isnan(ETFReturns)) = 0;
for month = firstMonth : nMonths - 1
    EW_WeightChange(month, :) = equalWeights(month + 1, :) ...
                                    - equalWeights(month, :) .* (1 + ETFReturns(month + 1, :)) / EWReturns(month, 1);
    EW_Turnover(month, 1) = sum(abs(EW_WeightChange(month, :)), 'OmitNaN');
        
    MomLong_WeightChange(month, :) = momLongWeights(month + 1, :) ...
                                    - momLongWeights(month, :) .* (1 + ETFReturns(month + 1, :)) / MomLongReturns(month, 1);
    MomLong_Turnover(month, 1) = sum(abs(MomLong_WeightChange(month, :)), 'OmitNaN');
    
    MomLS_WeightChange(month, :) = momLSWeights(month + 1, :) ...
                                    - momLSWeights(month, :) .* (1 + ETFReturns(month + 1, :)) / MomLSReturns(month, 1);
    MomLS_Turnover(month, 1) = sum(abs(MomLS_WeightChange(month, :)), 'OmitNaN');    
end


EWReturns_Net = EWReturns - c * EW_Turnover;
MomLongReturns_Net = MomLongReturns - c * MomLong_Turnover;
MomLSReturns_Net = MomLSReturns - c * MomLS_Turnover;


% Performance statistics

% call summary function 6 times or easier consolidate return in a single array
allTotalReturns = [EWReturns, MomLongReturns, MomLSReturns, EWReturns_Net, MomLongReturns_Net, MomLSReturns_Net];
allXsReturns = allTotalReturns - RfMonthly(2 : end, :);

% 1-12 all "1" -> take care of that 
allTotalReturns = allTotalReturns(13 : end, :);
allXsReturns = allXsReturns(13 : end, :);

% Net Asset Value
% EWReturns are already "1+" therefore her not +1
strategyNAV = cumprod(allTotalReturns);

% - benchmark is equally weighted portfolio of all
%   available countries, stored in allXsReturns(:, 1)
% - in RfMonthly we didn't delete the first 13 rows
% - this function assumes net returns not gross returns, since we have 
%   gross returns bcs we did EWReturns = 1+sum..., we need to subtract 1

summarizePerformance(allXsReturns-1, RfMonthly(14 : end, :), allXsReturns(:, 1)-1, annualizationFactor, 'Country Strategies (Equally Weighted, Momentum Long Only, Momentum Long/Short), without and with transaction costs');

dates4Fig = dates4Fig(14 : end);

% Equity lines, using total returns and not excess returns
% semilogy: logarithmic axis
% plot: normal axis
figure
semilogy(dates4Fig, strategyNAV(:, 1), 'k-', dates4Fig, strategyNAV(:, 2), 'b-', dates4Fig, strategyNAV(:, 3), 'r-')
hold on
semilogy(dates4Fig, strategyNAV(:, 4), 'k--', dates4Fig, strategyNAV(:, 5), 'b--', dates4Fig, strategyNAV(:, 6), 'r--'),
    xlabel('Year'), ylabel('Portfolio Value'), 
    legend('Equally Weighted', 'Momentum Long Only', 'Momentum Long/Short', 'Equally Weighted, TC', 'Mom. Long Only, TC', 'Mom. Long/Short, TC', 'Location', 'NorthWest')
hold off
set(gcf, 'Position', [200, 200, 800, 600])

%%% Interpretation:
% - Momentum worked well until 2009 then not so super anymore
% - TC tears you down qutie a lot especially for Long-Short
%   Reason: Turnover is much higher with Long-Short
% - Shortcut if you wanna know the drag down of turnover:
%   Avg_Return_before_TC - Avg_turnover * TC


