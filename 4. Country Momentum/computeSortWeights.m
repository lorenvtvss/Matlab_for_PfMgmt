function weights = computeSortWeights(sortVariable, nLongs, nShorts, longHighValues)

% Generates porfolio weights based on sortVariable. 
% The function ignores assets for which the sort variable is missing (NaN).
% All such assets get a weight of zero in the portfolio.
% nLongs and nShorts denote the number of assets held long and short. 
% When longHighValues is 1, assets that have the highest values for
% sortVariable are held long and those with the lowest values are held
% short. Otherwise the opposite holds.


% Find the assets with the highest and lowest values of the sort variable
if (longHighValues == 1)
    [~, listOfLongs] = maxk(sortVariable, nLongs);
    [~, listOfShorts] = mink(sortVariable, nShorts);   
else
    [~, listOfLongs] = mink(sortVariable, nLongs);
    [~, listOfShorts] = maxk(sortVariable, nShorts);
end

% Assign the weights to assets in the list of longs and shorts
nAssets = length(sortVariable);
weights = zeros(1, nAssets);
weights(listOfLongs) = 1 / nLongs;
weights(listOfShorts) = -1 / nShorts;
