function scores = getScore(sortVariable, nLongs, nShorts, longHighValues)

% Generates scores of +1 or -1 based on sortVariable. 
% The function ignores assets for which the sort variable is missing (NaN).
% nLongs and nShorts denote the number of assets that will get positive and
% negative scores, respectively. 
% When longHighValues is 1, assets that have the highest values for 
% sortVariable are given a positive score and those 
% with the lowest values a negative score. Otherwise the opposite holds.


% Find the assets with the highest and lowest values of the sort variable
if (longHighValues == 1)
    [~, listOfLongs] = maxk(sortVariable, nLongs);
    [~, listOfShorts] = mink(sortVariable, nShorts);   
else
    [~, listOfLongs] = mink(sortVariable, nLongs);
    [~, listOfShorts] = maxk(sortVariable, nShorts);
end

% Assign the scores to assets in the list of longs and shorts
nAssets = length(sortVariable);
scores = zeros(1, nAssets);
scores(listOfLongs) = 1;
scores(listOfShorts) = -1;
