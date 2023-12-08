function portfolioStats(ReturnSeries, Rf, factorXsReturns, nYears)
% ReturnSeries should be total returns
% Assuming we are passing in monthly data


% Compute annualized return
finalPfVal = prod(1 + ReturnSeries);
annualizedReturn = finalPfVal.^(1 / nYears) - 1
finalPfValRf = prod(1 + Rf);
annualizedRf = finalPfValRf.^(1 / nYears) - 1

% Annualized Std
annualizedStd = std(ReturnSeries) * sqrt(12)

% Sharpe Ratio 
SR = (annualizedReturn - annualizedRf) ./ annualizedStd

% Worst and best return
worst = min(ReturnSeries)
best = max(ReturnSeries)

% Skewness and kurtosis
skew = skewness(ReturnSeries)
kurt = kurtosis(ReturnSeries)

% Regression of portfolio excess returns on factor excess returns
% inv(X'X) * X'y
X = [ones(length(factorXsReturns) , 1) factorXsReturns];
y = ReturnSeries - Rf;
b = X \ y;
dailyAlpha = b(1, :);
betas = b(2 : end, :)
benchmarkReturns = Rf + factorXsReturns * betas;
finalBmVal = prod(1 + benchmarkReturns);
annualizedBenchmark = finalBmVal.^(1 / nYears) - 1;
annualizedAlpha = annualizedReturn - annualizedBenchmark

% Autocorrelations
AC1 = diag(corr(ReturnSeries(1 : end - 1, :), ReturnSeries(2 : end, :)))'




