function [mu_p, sigma_p, SR_p] = computeMuSigmaSR(w, mu, Sigma, Rf)
% Computes:
% mu_p:     expected pf return
% sigma_p:  expected pf return standard deviation
% SR_p:     pf Sharpe ratio

mu_p = Rf + w' * (mu - Rf);
sigma_p = sqrt(w' * Sigma * w);
SR_p = (mu_p - Rf) / sigma_p;