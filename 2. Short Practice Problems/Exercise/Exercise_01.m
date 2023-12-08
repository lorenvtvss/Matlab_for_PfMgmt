% see also solutions

%%%% 1 Present Value
%%% a)
C = [-1600 1500 1000 1500 -2000 -500];
R = 0.04;
T = 5;
t = (0:T);      % start at zero until T
d = (1+R).^(-t);	% creates vector of d's
NPV = sum(C.*d); % .*: don't do the inner product, than sum (together: inner product)
NPV2 = C*d' ;    % inner product (NPV = NPV2)

%%% b)

%%% FIRST WAY
RVector = (0:0.001:0.5);    
% create function NPV in new script file
subplot(3,1,1), plot(RVector, NPVFunction(RVector,t,C));
    % plot(xvalue, yvalue)
    % if you don't state xvalue it just takes 1

%%% SECOND WAY
RNew = (0:0.01:0.5);
NPPV = zeros(1, length(RNew));
for i = 1:length(RNew)
    F = (1+RNew(i)).^(t);
    NPPV(i) = sum(C./F);
end
subplot(3,1,2), plot(RNew, NPPV);

%%% THIRD WAY
d = (1+RVector').^(-t);
NPV_vec = d*C';
subplot(3,1,3), plot(RVector, NPV_vec);


%%%% 2 Bond Pricing and Duration
%%% a) Bond Price
FaceValue = 1000;
R = 0.05;
C = 0.0625*FaceValue;
t = (1:7);                % first payment of bond is in 1 year
d = (1+R).^(-t);
P = sum(d.*C) + FaceValue * d(end); % CF in T is coupon + FaceValue

%%% b) Duration
D = (sum(t.*d.*C) + t(end)*d(end)*FaceValue)/P;

%%% c) Approximate Bond Price
DeltaR = 0.005;
PApprox = P*(1-D*DeltaR / (1+R));

%%% d) Exact and approx. price depending on interest rate
RVec = (0:0.001:0.1);
CVector = C*ones(1,length(t));
CVector(end) = CVector(end) + FaceValue;
DeltaRVec = RVec - R;                   % vector with all the shift of 5%
PApprox = P*(1-D*DeltaRVec / (1+R));
PExact = NPVFunction(RVec, t, CVector);

figure;                                  % give me a figure
plot(RVec, PExact, 'k-', RVec, PApprox, 'b--');

%%%% 3 Portfolio Theory
Rf = 0.01;
mu = [0.05;0.08;0.1]; % column vector
sigma = [0.1;0.2;0.15];
rho = [1 0.3 0.4;0.3 1 0.5; 0.4 0.5 1]; % correaltion matrix

Sigma = (sigma*sigma').*rho; % var-covar matrix
inv(Sigma);

%%% a) Tangency Pf.
w_t = inv(Sigma)*(mu-Rf);
w_t = w_t/sum(w_t); % relative scale stays the same but sum of elements = 1
mu_t1 = sum(w_t.*mu);
mu_t2 = w_t'*mu ;
mu_t3 = w_t'*(mu-Rf)+Rf; % same result, different calc
sigma_t = sqrt(w_t'*Sigma*w_t);
SR_t = (mu_t-Rf)/sigma_t;

%%% b) Risky-asset-only global minimum variance Pf.
nAssets = length(mu);
SigmaInv = inv(Sigma);
w_g = SigmaInv*ones(nAssets,1); % faster
w_g = w_g/sum(w_g); 
w_g2 = SigmaInv*ones(nAssets,1)/sum(sum(SigmaInv)); % formula AM
[mu_g, sigma_g, SR_g] = computeMuSigmaSR(w_g, mu, Sigma, Rf); % using formula

%%% c) Risk-parity Pf.
w_rp = 1./sigma;
w_rp = w_rp/sum(w_rp);
[mu_rp, sigma_rp, SR_rp] = computeMuSigmaSR(w_rp, mu, Sigma, Rf); 

%%% d) Equally weighted Pf.
w_ew = ones(nAssets,1)/nAssets; % else it gives you just a number
[mu_ew, sigma_ew, SR_ew] = computeMuSigmaSR(w_ew, mu, Sigma, Rf); 


%%%% 4 Bootstrap
C = [50 50 1050 0; 60 1060 0 0; 70 70 1070 0; 80 80 80 1080];
P = [1041.2 1070 1098 1137]';
CInv = inv(C);
d = CInv*P;
t = (1:4);
R = (d'.^(-1./t))-1;

%%%% 5 Regression
AdditionalC = [55 55 1055 0; 65 1065 0 0; 75 75 1075 0; 85 85 85 1085];
C_Q5 = [C; AdditionalC];
AdditionalPrices = [1058; 1088; 1112; 1153];
P_Q5 = [P; AdditionalPrices];
d_Q5 = inv(C_Q5'*C_Q5) * C_Q5'*P_Q5
R_Q5 = d_Q5.^(-1./t')-1 % t': bcs d col vecotr and t row vector


%%%% 6 Simulation
%%% a)
X = rand(100000, 1);
avgX = mean(X)
varX = var(X) 

Y = rand(100000, 1);
avgX = mean(Y)
varX = var(Y)
% var should be 1/12 so it makes sense
% mean should be 1/2 so it makes sense

%%% b)
% method 1 (slow)
count = 0;
for m = 1:100000
    r = sqrt(X(m)^2 + Y(m)^2); % sqrt has long computation time
    if (r <= 1)
        count = count+1;
    end
end
piGuess = 4*count/100000;

% method 2 (faster)
count = 0;
for m = 1:100000
    rSq = X(m)^2 + Y(m)^2; % checking if sqrt(x) of sth is <1 is the same as checking if x<1
    if (r <= 1)
        count = count+1;
    end
end
piGuess = 4*count/100000;

% method 3 (fastest)
Z = X.^2 + Y.^2;
inUnitCircle = (Z < 1); % indicator: 1 when you're in unitcircle, 0 if not
piGuess2 = 4*mean(inUnitCircle);


%%%% 7 Simulation of Security Prices
%%% a)
nDraws = 100000;
nPeriods = 10;
q = 0.7;
u = 1.2;
d = 0.9;
InitialPrice = 1;
StrikePrice = 1.1;

pVec = zeros(nDraws, 1);
z = rand(nDraws, nPeriods);
for j = 1:nDraws
    s = InitialPrice;
    for k = 1:nPeriods
        if (z(j,k) <= q)
            s = s*u;
        else
            s = s*d;
        end
    end
    pVec(j) = s;
end

avgP = mean(pVec)
varP = var(pVec)

%%% b)
optionPrice = max(pVec - StrikePrice, 0);

avgOP = mean(optionPrice)
varOP = var(optionPrice)
    





