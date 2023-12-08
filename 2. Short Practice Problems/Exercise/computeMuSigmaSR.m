function [mu_p, sigma_p, SR_p] = computeMuSigmaSR(w, mu, Sigma, Rf)
mu_p = Rf + w'*(mu-Rf);
sigma_p = sqrt(w'*Sigma*w);
SR_p = (mu_p-Rf)/sigma_p;