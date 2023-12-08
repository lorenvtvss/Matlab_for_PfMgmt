x = 0 : 0.01 : 1;
y = x.^2;
y1 = (x + 1).^2;
plot(x, y, 'r-', x, y1, 'b--'), title('My Title Here'), xlabel('This is X'), ylabel('This is Y = X^2'), axis([0 1 0 2])

% equivalent
figure
plot(x, y, 'g')
hold on
plot(x, y1, 'r')
hold off
