% testComputeSortWeights
% This file is used to test the computation of the portfolio weights.

clc
clear

% Inputs
sortVar = [1 3 5 NaN 7 2 4 6 NaN]
nLongs = 3;
nShorts = 3;

% Case 1: Assets with high values of the sort variable are held long
longHighValues = 1
testWeights1 = computeSortWeights(sortVar, nLongs, nShorts, longHighValues)
testWeights1NoShorts = computeSortWeights(sortVar, nLongs, 0, longHighValues)
testWeights1NoLongs = computeSortWeights(sortVar, 0, nShorts, longHighValues)

% Case 2: Assets with high values of the sort variable are held short
longHighValues = 0
testWeights2 = computeSortWeights(sortVar, nLongs, nShorts, longHighValues)
testWeights2NoShorts = computeSortWeights(sortVar, nLongs, 0, longHighValues)
testWeights2NoLongs = computeSortWeights(sortVar, 0, nShorts, longHighValues)

% Case 3: Flip the sign of the sort variable. This should give the same answer as 
% in Case 1 (where we had longHighValues = 1)
sortVarNeg = -sortVar
testWeights3 = computeSortWeights(sortVarNeg, nLongs, nShorts, longHighValues)
testWeights3NoShorts = computeSortWeights(sortVarNeg, nLongs, 0, longHighValues)
testWeights3NoLongs = computeSortWeights(sortVarNeg, 0, nShorts, longHighValues)

diff13 = sum(abs(testWeights1 - testWeights3))
diff13NoShorts = sum(abs(testWeights1NoShorts - testWeights3NoShorts))
diff13NoLongs = sum(abs(testWeights1NoLongs - testWeights3NoLongs))
