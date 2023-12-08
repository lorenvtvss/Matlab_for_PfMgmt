function NPV = NPVFunction(R,t,C)
d = (1+R').^(-t);	
NPV = C*d';
