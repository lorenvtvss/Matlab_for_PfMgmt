% Solution to the short practice problems
clc
clear
close all



% Problem 1: Net Present Values
% Input data
CF = [-1600 1500 1000 1500 -2000 -500]';
R = 0.04;
T = 5;

% Question a: Net Present Value of Project
t = (0 : T)';
DiscountFactors = (1 + R).^(-t);
NPV = DiscountFactors' * CF 

% Question b: Net Present Value as a Function of the Discount Rate
RVector = (0 : 0.001 : 0.5)';
DF = zeros(length(t), 1);
PV = zeros(length(RVector), 1);
for n = 1 : length(RVector)
   DF = (1 + RVector(n)).^(-t);
   PV(n) = CF' * DF;
end
subplot(2, 1, 1), plot(RVector, PV), xlabel('Discount Rate'), ylabel('Net Present Value of Project')

% Alternative without loop (shown in second subplot)
DF2 = (1 + RVector * ones(1, length(t))).^(-t');
PV2 = DF2 * CF;
subplot(2, 1, 2), plot(RVector, PV2), xlabel('Discount Rate'), ylabel('Net Present Value of Project')



% Problem 2: Bond pricing
% Input data
CF = 62.5 * ones(7, 1);
CF(7) = 1062.5 ;
T = 7;
R = 0.05;

% Question a: Bond Price
t = (1 : T)';
DiscountFactors = (1 + R).^(-t);
BondPrice = DiscountFactors' * CF

% Question b: Duration
Duration = sum(t .* DiscountFactors .* CF) / BondPrice

% Question c: New bond price approximated with duration
InterestRateShift = 0.005;
newBondPrice = BondPrice * (1 - Duration * InterestRateShift / (1 + R))

% Question d: Exact and approximate bond price as a function of the interest rate
RVector = (0 : 0.001 : 0.1)';
ExactBondPrice = zeros(length(RVector), 1);
ApproxBondPrice = zeros(length(RVector), 1);
for n = 1 : length(RVector)
   DiscountFactors = (1 + RVector(n)).^(-t);
   ExactBondPrice(n) = DiscountFactors' * CF;
   ApproxBondPrice(n) = BondPrice * (1 - Duration * (RVector(n) - R) / (1 + R));
end
figure
subplot(2, 1, 1), plot(RVector, ExactBondPrice, '-', RVector, ApproxBondPrice, '--'),  
	xlabel('Interest Rate'), ylabel('Bond Price'), 
    legend('Exact Bond Price', 'Duration Approximation')

% Alternative without loop (shown in second subplot)
DiscountFactors2 = (1 + RVector * ones(1, length(t))).^(-t');
ExactBondPrice2 = DiscountFactors2 * CF;
ApproxBondPrice2 = BondPrice * (1 - Duration * (RVector - R) / (1 + R));
subplot(2, 1, 2), plot(RVector, ExactBondPrice2, '-', RVector, ApproxBondPrice2, '--'),
    xlabel('Interest Rate'), ylabel('Bond Price'), 
    legend('Exact Bond Price', 'Duration Approximation')


    
% Problem 3: Portfolio Theory
% Input data
Rf = 0.01;
mu = [0.05; 0.08; 0.1];
sigma = [0.1; 0.2; 0.15];
rho = [1 0.3 0.4; 0.3 1 0.5; 0.4 0.5 1];

% Computations
% General variables
nAssets = length(mu);
avgRho = 2 * sum(sum(triu(rho, 1))) / (nAssets * (nAssets  - 1));
Sigma = rho .* (sigma * sigma')
SigmaInv = inv(Sigma);

% Question a: Tangency portfolio
w_t = SigmaInv * (mu - Rf);         % Alternative: Sigma \ (mu - Rf)
w_t = w_t / sum(w_t)
[mu_t, sigma_t, SR_t] = computeMuSigmaSR(w_t, mu, Sigma, Rf)
SR_t2 = sqrt((mu - Rf)' * SigmaInv * (mu - Rf))

% Question b: Global MVP
w_g = SigmaInv * ones(nAssets, 1) / sum(sum(SigmaInv))
[mu_g, sigma_g, SR_g] = computeMuSigmaSR(w_g, mu, Sigma, Rf)
SR_g2 = (ones(1, nAssets) * SigmaInv * (mu - Rf)) / sqrt(sum(sum(SigmaInv)))

% Question c: Risk parity
w_rp = 1 ./ sigma;
w_rp = w_rp / sum(w_rp)
[mu_rp, sigma_rp, SR_rp] = computeMuSigmaSR(w_rp, mu, Sigma, Rf)
scalingFactor = sqrt(nAssets / (1 + (nAssets - 1) * avgRho));
SR_rp2 = scalingFactor * mean((mu - Rf) ./ sigma)

% Question d: Equally weighted 
w_ew = ones(nAssets, 1) / nAssets
[mu_ew, sigma_ew, SR_ew] = computeMuSigmaSR(w_ew, mu, Sigma, Rf)
SR_ew2 = (mean(mu) - Rf) / sqrt(mean(mean(Sigma)))
% The next line is the formulation with average variances and covariances, but too messy
SR_ew3 = (mean(mu) - Rf) / sqrt(mean(diag(Sigma)) / nAssets +  2 * sum(sum(triu(Sigma, 1))) / (nAssets^2))
% The next line is the approximation with average correlation; not perfect but pretty close
SR_ew4 = scalingFactor * (mean(mu) - Rf) / sqrt(mean(diag(Sigma)))



% Problem 4: Bootstrap
% Input data
t = (1 : 4)';
C = [50 50 1050 0; 60 1060 0 0; 70 70 1070 0; 80 80 80 1080];
Prices = [1041.2 1070 1098 1137]';

% Answer to the question
d = inv(C) * Prices                 % Alternative: d = C \ Prices 
R = d.^(-1./t) - 1



% Problem 5: Regression
% Input data
AdditionalC = [55 55 1055 0; 
               65 1065 0 0; 
               75 75 1075 0; 
               85 85 85 1085];
C_Q5 = [C; AdditionalC];
AdditionalPrices = [1058; 1088; 1112; 1153];
Prices_Q5 = [Prices; AdditionalPrices];

% Answer to the question
d_Q5 = inv(C_Q5' * C_Q5) * C_Q5' * Prices_Q5   % Alternative: d_Q5 = C_Q5 \ Prices_Q5 
R_Q5 = d_Q5.^(-1./t) - 1



% Problem 6: Simulation
% Input data
nDraws = 100000;

% Question a: Mean and Variance of the two Vectors
X = rand(nDraws, 1);
averageX = mean(X)
varianceX = var(X)
Y = rand(nDraws, 1);
averageY = mean(Y)
varianceY = var(Y)

% Question b: Estimating Pi
Z = X.^2 + Y.^2;
inUnitCircle = (Z < 1);
PiEstimate = 4 * mean(inUnitCircle)



% Problem 7: Simulation of Security Prices
% Input data
nDraws = 100000;
nPeriods = 10;
q = 0.7;
u = 1.2;
d = 0.9;
InitialPrice = 1;
StrikePrice = 1.1;

% Generate the stock price series
tic
stockPrice = InitialPrice * ones(nDraws, 1);
for m = 1 : nDraws               % First loop: Go through all simulation runs
   for n = 1 : nPeriods          % Second loop: Go through all periods
      rn = rand;
      if (rn < q)                % With 70% chance, price goes up
         stockPrice(m) = stockPrice(m) * u;
      else
         stockPrice(m) = stockPrice(m) * d;
      end
   end
end
toc

% Alternative (faster): draw all random numbers for one period at once
tic
stockPrice = InitialPrice * ones(nDraws, 1);
for n = 1 : nPeriods
    isUp = (rand(nDraws, 1) < q);
    % Fast alternative to stockPrice = stockPrice .* (isUp * u + (1 - isUp) * d)
    stockPrice = stockPrice .* (isUp * (u - d) + d); 
end
toc

% Note: drawing everything at once as shown below works but is slower
%isUpMatrix = (rand(nDraws, nPeriods) < q);
%returnMatrix = isUpMatrix * (u - d) + d;
%stockPrice = InitialPrice * prod(returnMatrix, 2);

% Question a: Price of the security
avgPrice = mean(stockPrice)
varPrice = var(stockPrice)

% Question b: Option price
optionPrice = max(stockPrice - StrikePrice, 0);
avgOptionPrice = mean(optionPrice)
varOptionPrice = var(optionPrice)
