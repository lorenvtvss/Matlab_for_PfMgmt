clc
close all
clear

% example with for loop
x = (0 : 0.01 : 1)';
K = length(x);
y = zeros(1, K);
for k = 1 : K
   %if (x(k) == 0.5)
   %    continue;
   %end
   y(k) = x(k)^2;
end
plot(x, y), xlabel('x value'), ylabel('y=x^2 value'), axis([0, 1, 0, 1])

% example with .^
figure
x = (0 : 0.01 : 1)';
y = x.^2;
plot(x, y), xlabel('x value'), ylabel('y=x^2 value'), axis([0, 1, 0, 1])
