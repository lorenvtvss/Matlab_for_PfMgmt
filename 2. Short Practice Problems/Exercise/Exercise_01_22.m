%%%% Exercise 1 %%%%

%% 1 Present Value
%%% a)
C = [-1600 1500 1000 1500 -2000 -500];
r = 0.04;
T = 5;
t = (0:T);          % start at zero until T
d = (1+r).^(-t);

NPV = sum(d.*C);
NPV1 = sum(C.*d);   % .*: don't do the inner product, than sum (together: inner product)
NPV2 = C*d' ;       % inner product (NPV = NPV2)


%%% b)
%%% FIRST WAY
RVector = (0:0.001:0.5);    
% create function NPV in new script file
subplot(3,1,1), plot(RVector, NPVFunction(RVector,t,C))
    % plot(xvalue, yvalue)
    % if you don't state xvalue it just takes 1

%%% SECOND WAY
RNew = (0:0.01:0.5);
NPPV = zeros(1, length(RNew));
for i = 1:length(RNew)
    F = (1+RNew(i)).^(t);
    NPPV(i) = sum(C./F);
end
subplot(3,1,2), plot(RNew, NPPV)

%%% THIRD WAY
d = (1+RVector').^(-t);
NPV_vec = d*C';
subplot(3,1,3), plot(RVector, NPV_vec)


%% 2 Bond Pricing and Duration
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