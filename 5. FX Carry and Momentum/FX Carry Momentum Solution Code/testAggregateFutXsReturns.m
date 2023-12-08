% testAggregateFutXsReturns
% This file is used to test the computation of total and excess
% returns on futures over multiple periods.

clc
clear


% For the first period, the cumulative return on the riskless asset should
% be zero and the cumulative total and excess returns on the futures 
% should be 21%. For the second period, the cumulative return on the riskless 
% asset and the total and excess returns on the first asset should match    
% those in the Excel file (TR 35.90%, XsR 20.15%, Rf 15.75%), 
% and the excess return on the second asset should be zero.
testDates = [102 103 104 202 203 204]';
testReturns = [-0.2, 0.375, 0.10, -0.2, 0.375, 0.10; 
               -0.2, 0.375, 0.10, 0, 0, 0]';
testRf = [0 0 0 0.05 0.06 0.04]'; 
[TR, XsR, CumRf] = aggregateFutXsReturns(testReturns, testRf, testDates, 2)