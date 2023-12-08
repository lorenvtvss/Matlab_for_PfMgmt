%% 1) Present Value %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% a) NPV
C = [-1600 1500 1000 1500 -2000 -500];
r = 0.04;
T = 5;
t = (0:T);          % start at zero until T
d = (1+r).^(-t);

NPV = d*C';


%%% b) NPV with R vector & plot
Rvector = (0:0.001:0.5);
NPVs = zeros(1,length(Rvector));

DF = (1 + Rvector' * ones(1, length(t))).^(-t);
NPVs = DF * C';

plot(Rvector, NPVs), xlabel('Discount Rate'), ylabel('Net Present Value of Project')


%% 2) Bond Pricing and Duration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% a) Bond Price
F = 1000;
c = 0.0625;     % annual interest
r = 0.05;
T = 7;
t = (1:T);

df = (1+r).^(-t);

cf = ones(1,length(t))*(c*F);
cf(end) = cf(end)+F; 

P = df*cf';


%%% b) Bond Duration
D = 1/P * (t.*df*cf');


%%% c) Bond price approximation with duration
delta_R = 0.005;
P_new = P*(1 - D*delta_R/(1+r));


%%% d) Plot exact and approximated price
R_vector = (0:0.0001:0.1);

P_exact = zeros(1,length(R_vector));
P_approx = zeros(1,length(R_vector));

% P_exact
cf_exact = ones(1,length(t))*(c*F);
cf_exact(end) = cf_exact(end)+F; 

df_exact = (1+ R_vector'*ones(1, length(t))).^(-t);
P_exact = (df_exact*cf_exact')';

% P_approx
P_approx = P * (1 - D*(R_vector - r)/(1 + r));

% Plot
figure
plot(R_vector, P_exact, 'b-', R_vector, P_approx, 'r-'),
    xlabel('Interest Rate'), ylabel('Bond Price'), 
    legend('Exact Bond Price', 'Duration Approximation')
    
saveas(gcf,'Bond_Price.png')



%% 3) Portfolio Theory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rf = 0.01;
mu = [0.05; 0.08; 0.1];         % vertical
sigma = [0.1; 0.2; 0.15];
rho = [1 0.3 0.4; 0.3 1 0.5; 0.4 0.5 1];    % correl matrix

Sigma = rho .* (sigma * sigma')             % variance-covariance matrix
SigmaInv = inv(Sigma);

nAssets = length(mu);
avgRho = 2 * sum(sum(triu(rho, 1))) / (nAssets * (nAssets  - 1));

% a) Tangency portfolio
w_t = SigmaInv*(mu-Rf);
w_t = w_t / sum(w_t);                       % standardize weights
[mu_t, sigma_t, SR_t] = computeMuSigmaSR(w_t, mu, Sigma, Rf)
%SR_t2 = sqrt((mu - Rf)' * SigmaInv * (mu - Rf))


% b) Risky-asset-only global minimum variance portfolio
w_g = SigmaInv * ones(nAssets, 1) / sum(sum(SigmaInv))
[mu_g, sigma_g, SR_g] = computeMuSigmaSR(w_g, mu, Sigma, Rf)
%SR_g2 = (ones(1, nAssets) * SigmaInv * (mu - Rf)) / sqrt(sum(sum(SigmaInv)))


% c) Risk-parity portfolio
w_rp = 1 ./ sigma;
w_rp = w_rp / sum(w_rp)
[mu_rp, sigma_rp, SR_rp] = computeMuSigmaSR(w_rp, mu, Sigma, Rf)
%scalingFactor = sqrt(nAssets / (1 + (nAssets - 1) * avgRho));
%SR_rp2 = scalingFactor * mean((mu - Rf) ./ sigma)


% d) Equally weighted portfolio
w_ew = ones(nAssets, 1) / nAssets
[mu_ew, sigma_ew, SR_ew] = computeMuSigmaSR(w_ew, mu, Sigma, Rf)
%SR_ew2 = (mean(mu) - Rf) / sqrt(mean(mean(Sigma)))
% The next line is the formulation with average variances and covariances, but too messy
%SR_ew3 = (mean(mu) - Rf) / sqrt(mean(diag(Sigma)) / nAssets +  2 * sum(sum(triu(Sigma, 1))) / (nAssets^2))
% The next line is the approximation with average correlation; not perfect but pretty close
%SR_ew4 = scalingFactor * (mean(mu) - Rf) / sqrt(mean(diag(Sigma)))



%% 4) Bootstrap %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% WHEN: # bond prices = # interest rates
t = (1 : 4)';
rates = zeros(length(t),1)
coupons = [50 50 1050 0; 60 1060 0 0; 70 70 1070 0; 80 80 80 1080];
prices = [1041.2 1070 1098 1137]';

discountfactor = inv(coupons) * prices
rates = discountfactor.^(-1./t) - 1



%% 5) Regression %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% WHEN: # bond prices > # interest rates
t = (1 : 4)';
rates = zeros(length(t),1)
coupons = [50 50 1050 0; 60 1060 0 0; 70 70 1070 0; 80 80 80 1080];
prices = [1041.2 1070 1098 1137]';

AdditionalCoupons = [55 55 1055 0; 
                    65 1065 0 0; 
                    75 75 1075 0; 
                    85 85 85 1085];
C_Q5 = [coupons; AdditionalCoupons];
AdditionalPrices = [1058; 1088; 1112; 1153];
Prices_Q5 = [prices; AdditionalPrices];

discountfactor_Q5 = inv(C_Q5' * C_Q5) * C_Q5' * Prices_Q5  
R_Q5 = discountfactor_Q5.^(-1./t) - 1



%% 6) Simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
n = 100000;
X = zeros(n, 1);
Y = zeros(n, 1);

% a) Mean and Variance of the two Vectors
X = rand(n, 1);
averageX = mean(X)
varianceX = var(X)
Y = rand(n, 1);
averageY = mean(Y)
varianceY = var(Y)

% b) Estimating Pi
Z = X.^2 + Y.^2;
inUnitCircle = (Z < 1);
PiEstimate = 4 * mean(inUnitCircle)



%% 7) Simulation of Security Prices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
up = 1.2;
down = 0.9;
p_up = 0.7;
p_down = 0.3;

InitialPrice = 1;
StrikePrice = 1.1;

n_periods = 10;
n_paths = 100000;

%%% Slow Alternative
% Generate the stock price series
tic
stockPrice = InitialPrice * ones(n_paths, 1);

% First loop: Go through all simulation runs
for m = 1 : n_paths        
    % Second loop: Go through all periods
    for n = 1 : n_periods          
        rn = rand;          % uniform distribution in the interval (0,1)                    
        if (rn < p_up)      % With 70% chance, price goes up
            stockPrice(m) = stockPrice(m) * up;
        else
            stockPrice(m) = stockPrice(m) * down;
        end
    end
end
toc


%%% Fast Alternative
% draw all random numbers for one period at once
tic
stockPrice = InitialPrice * ones(n_paths, 1);
for n = 1 : n_periods
    isUp = (rand(n_paths, 1) < p_up);
    % Fast alternative to stockPrice = stockPrice .* (isUp * u + (1 - isUp) * d)
    stockPrice = stockPrice .* (isUp * (up - down) + down); 
end
toc


% a) Price of the security
avgPrice = mean(stockPrice)
varPrice = var(stockPrice)

% b) Option price
optionPrice = max(stockPrice - StrikePrice, 0);
avgOptionPrice = mean(optionPrice)
varOptionPrice = var(optionPrice)








