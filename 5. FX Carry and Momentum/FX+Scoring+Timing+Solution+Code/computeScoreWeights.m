function weights = computeScoreWeights(score)

% Generates portfolios such that all assets with a positive score get
% a positive weight and those with a negative score get a negative weight.
% The long and short legs each sum to 100% exposure. Within each leg, the
% assets are equally weighted.

nAssets = length(score);

% Identify the longs
longList = (score > 0);
nLongs = sum(longList);

% Identify the shorts
shortList = (score < 0);
nShorts = sum(shortList);

% Scaled long/short weights
weights = zeros(1, nAssets);
weights(longList) = 1 / nLongs;
weights(shortList) = -1 / nShorts;