% testTurnover: Tests the turnover computations
clear

% Case 1: Portfolio is liquidated, so turnover is 100%, irrespective of returns 
w1_previous = [0.2 0.5 0.3 0 0 0];
w1_new = [0 0 0 0 0 0];
riskfree1 = 0.1 * randn;
riskyRet1 = 0.1 * randn(1, 6);
test1 = computeTurnover(w1_previous, w1_new, riskyRet1, riskfree1)


% Case 2: Portfolio changes completely, so turnover is 200%,
% irrespective of the returns on the assets.
w2_previous = [0.2 0.5 0.3 0 0 0];
w2_new = [0 0 0 0.4 0.4 0.2];
riskfree2 = 0.1 * randn;
riskyRet2 = 0.1 * randn(1, 6);
test2 = computeTurnover(w2_previous, w2_new, riskyRet2, riskfree2)


% Case 3: Portfolio changes partially, turnover is 160%,
% assuming zero return on the assets
w3_previous = [0.2 0.5 0.3 0 0 0];
w3_new = [0.2 0 0 0.4 0.4 0];
riskfree3 = 0;
riskyRet3 = zeros(1, 6);
test3 = computeTurnover(w3_previous, w3_new, riskyRet3, riskfree3)
% Case 3b: If the return on all assets are zero, turnover will be the same 
% for portfolios held long or short, so the following should give 160% as well
test3b = computeTurnover(-w3_previous, -w3_new, riskyRet3, riskfree3)


% Case 4: Portfolio weights do not change, but the second asset does well,
% triggering rebalancing trades. The value of the portfolio after the returns
% are realized is sum([0.2 0.75 0.3 0 0 0]) = 1.25. This corresponds to weights
% of [0.16 0.6 0.24 0 0 0]. So rebalancing trades of 0.04 + 0.10 + 0.06 =
% 0.2 are required, which is the turnover.
w4_previous = [0.2 0.5 0.3 0 0 0];
w4_new = w4_previous;
riskfree4 = 0;
riskyRet4 = [0 0.5 0 0 0 0];
test4 = computeTurnover(w4_previous, w4_new, riskyRet4, riskfree4)


% Case 5: Portfolio weights do not change, but the return on the riskless
% asset triggers rebalancing trades. The value of the portfolio after the 
% returns are realized is 1.2 (50% return on a riskless asset position of 40%). 
% This corresponds to weights of [0.1 0 0.2 0 0.2 0]. So rebalancing
% trades of 0.02 + 0.04 + 0.04 = 0.1 are required, which is the turnover.
w5_previous = [0.12 0 0.24 0 0.24 0];
w5_new = w5_previous;
riskfree5 = 0.5;
riskyRet5 = zeros(1, 6);
test5 = computeTurnover(w5_previous, w5_new, riskyRet5, riskfree5)