function summarizePerformance(xsReturns, Rf, factorXsReturns, annualizationFactor, txt)

% Computes (annualized) performance statistics. Standard deviation, min, max, skewness 
% and kurtosis are reported for excess returns.
% 
% The returns provided in xsReturns should be excess returns, one column  
% per asset or strategy, one row per period. The column vector Rf should  
% contain the return on the riskless asset during each period. The factor 
% excess returns are used to compute factor exposures and alphas. 
%
% The annualization factor is used for the average return, standard deviation, 
% Sharpe ratio, and alpha. 
% annualizationFactor = 12: for monthly data
% annualizationFactor = 252: for daily data
% annualizationFactor = 1:  if no annualization is desired
%
% The text is used for labeling. 


% Compute total returns
nAssets = size(xsReturns, 2);
totalReturns = xsReturns + Rf * ones(1, nAssets);

% Compute the terminal value of the portfolios to get the geometric mean
% return per period
nPeriods = size(xsReturns, 1);
FinalPfValRf = prod(1 + Rf);
FinalPfValTotalRet = prod(1 + totalReturns);
GeomAvgRf = 100 * (FinalPfValRf.^(annualizationFactor / nPeriods) - 1);
GeomAvgTotalReturn = 100 * (FinalPfValTotalRet.^(annualizationFactor / nPeriods) - 1);
GeomAvgXsReturn = GeomAvgTotalReturn - GeomAvgRf;

% Regress returns on benchmark to get alpha and factor exposures
X = [ones(nPeriods, 1) factorXsReturns];
b = X \ xsReturns;
betas = b(2 : end, :);


% Based on the regression estimates, compute the total return on the passive 
% alternative and the annualized alpha
bmRet = factorXsReturns * betas + Rf * ones(1, nAssets);
FinalPfValBm = prod(1 + bmRet);
GeomAvgBmReturn = 100 * (FinalPfValBm.^(annualizationFactor / nPeriods) - 1);
alphaGeometric  = GeomAvgTotalReturn - GeomAvgBmReturn;


% Rescale the returns to be in percentage points
xsReturns = 100 * xsReturns;
totalReturns = 100 * totalReturns;


% Compute first three autocorrelations
AC1 = diag(corr(xsReturns(1 : end - 1, :), xsReturns(2 : end, :)))';
AC2 = diag(corr(xsReturns(1 : end - 2, :), xsReturns(3 : end, :)))';
AC3 = diag(corr(xsReturns(1 : end - 3, :), xsReturns(4 : end, :)))';


% Report the statistics
disp(['Performance Statistics for ' txt]);
ArithmAvgTotalReturn = annualizationFactor * mean(totalReturns)
ArithmAvgXsReturn = annualizationFactor * mean(xsReturns)
StdXsReturns = sqrt(annualizationFactor) * std(xsReturns)
SharpeArithmetic = ArithmAvgXsReturn ./ StdXsReturns
GeomAvgTotalReturn
GeomAvgXsReturn
SharpeGeometric = GeomAvgXsReturn ./ StdXsReturns
MinXsReturn = min(xsReturns)
MaxXsReturn = max(xsReturns)
SkewXsReturn = skewness(xsReturns)
KurtXsReturn = kurtosis(xsReturns)
alphaArithmetic = annualizationFactor * 100 * b(1, :)
alphaGeometric
betas
Autocorrelations = [AC1; AC2; AC3]
