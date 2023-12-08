function NPV = NPVFunction(R,t,C)
% R: return vector
% t: years vector
% C: CF vector

d = (1+R').^(-t);	
NPV = C*d';
