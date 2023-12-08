function [turnover, Rp] = computeTurnover(previousWeights, newWeights, assetReturns, Rf)

% Computes turnover by comparing the previous and the new target weights 
% of the portfolio, accounting for the returns on the assets. The function 
% also computes the portfolio return excluding transaction costs, Rp. 

Rp = sum(previousWeights .* assetReturns) + (1 - sum(previousWeights)) * Rf;
valuePerAsset = previousWeights .* (1 + assetReturns);
currentWeights = valuePerAsset / (1 + Rp);
turnover = sum(abs(newWeights - currentWeights));
