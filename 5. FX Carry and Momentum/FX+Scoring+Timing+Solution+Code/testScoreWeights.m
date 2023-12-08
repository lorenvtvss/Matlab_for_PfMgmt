% testScoreWeights
% This file is used to test the computation of the individual scores
% and of the portfolio weights.

clc
clear


% Scores
scoringVar = [1 3 5 7 2 4 6]
nLongs = 3;
nShorts = 3;

longHighValues = 1
testScores1 = getScore(scoringVar, nLongs, nShorts, longHighValues)
testScores1NoShorts = getScore(scoringVar, nLongs, 0, longHighValues)
testScores1NoLongs = getScore(scoringVar, 0, nShorts, longHighValues)

longHighValues = 0
testScores2 = getScore(scoringVar, nLongs, nShorts, longHighValues)
testScores2NoShorts = getScore(scoringVar, nLongs, 0, longHighValues)
testScores2NoLongs = getScore(scoringVar, 0, nShorts, longHighValues)


% Weights
% Long/short case
scores1 = [1 -3 2 3 0 -2 0]
testWeights1 = computeScoreWeights(scores1)
% Case without longs
scores2 = [-1 -3 -2 -3 0 -2 0]
testWeights2 = computeScoreWeights(scores2)
% Case without shorts
scores3 = [0 1 3 0 2 3 1 0 0]
testWeights3 = computeScoreWeights(scores3)