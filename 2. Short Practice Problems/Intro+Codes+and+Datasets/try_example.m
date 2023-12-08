% example of a try/catch block
clear


x1 = [1 2]
x2 = [1 2]'
try
    x3 = x1 * x2;
    disp('Product successful');
catch
    disp('Vector dimensions do not agree: need to transpose');
    x2 = x2';
    x3 = x1 * x2;
end
x3

