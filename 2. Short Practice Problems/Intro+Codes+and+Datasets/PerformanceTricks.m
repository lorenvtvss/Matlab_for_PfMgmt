% Performance Improvement Examples

clc
clear


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions versus scripts %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Functions versus scripts')
N = 500000;
xVec = rand(N, 1);
y1 = zeros(N, 1);
y2 = zeros(N, 1);

% Using script: Slow and error-prone
tic
for n = 1 : N
    x = xVec(n, 1);     % input of script is x therefore I define x here
    polynomialScript;   % calling this file that contains output z
    y1(n, 1) = z;       % I order z to sth   
end
toc

% Using function: Faster
tic
for n = 1 : N
    y2(n, 1) = polynomialFunction(xVec(n, 1));
end
toc

% Single function call: Even faster
tic
y3 = polynomialFunction(xVec);
toc

% Make sure that all three produce the same answer
diff12 = sum(abs(y2 - y1))
diff13 = sum(abs(y3 - y1))

return

%%%%%%%%%%%%%%%%%%%%%%%%
% Preallocating arrays %
%%%%%%%%%%%%%%%%%%%%%%%%
disp('Preallocating arrays');
M = 1000000;

% Slow
tic
for m = 1 : M
    Vector1(m, 1) = m;  % creates for every loop a new vector with m rows
end                     
toc

% Faster
tic
Vector2 = zeros(M, 1);  % preallocate memory by defining vector size
for m = 1 : M
    Vector2(m, 1) = m;
end
toc

% Matlab shortcut
tic
Vector3 = (1 : M)';
toc

% Make sure that all three produce the same answer
diff12 = sum(abs(Vector2 - Vector1))
diff13 = sum(abs(Vector3 - Vector1))

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using matrix/vector operations %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Using matrix/vector operations')
mSize = 5000;
Matrix1 = randn(mSize, mSize);
Matrix2 = randn(mSize, mSize);
Matrix3 = zeros(mSize, mSize);

% Slow: Multiply via loop
tic
for m = 1 : mSize
    for n = 1 : mSize
        Matrix3(m, n) = Matrix1(m, n) * Matrix2(m, n);
    end
end
toc

% Faster: Use component-wise multiplication 
tic
Matrix3 = Matrix1 .* Matrix2;
toc

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Short-circuit operators %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ')
disp('Short-circuit operators')

% Slow: Use of and()
tic
for m = 1 : mSize
    for n = 1 : mSize
        if (and((Matrix1(m, n) > 2), (Matrix2(m, n)^2 > Matrix1(m, n)^3)))
            Matrix3(m, n) = Matrix2(m, n);
        end
    end
end
toc

% Faster: Use of &
tic
for m = 1 : mSize
    for n = 1 : mSize
        if ((Matrix1(m, n) > 2) & (Matrix2(m, n)^2 > Matrix1(m, n)^3))
            Matrix3(m, n) = Matrix2(m, n);
        end
    end
end
toc

% Fastest in theory: Use of &&
tic
for m = 1 : mSize
    for n = 1 : mSize
        if ((Matrix1(m, n) > 2) && (Matrix2(m, n)^2 > Matrix1(m, n)^3))
            Matrix3(m, n) = Matrix2(m, n);
        end
    end
end
toc

% Putting computation-intensive tests first slows things down
tic
for m = 1 : mSize
    for n = 1 : mSize
        if ((Matrix2(m, n)^2 > Matrix1(m, n)^3) && (Matrix1(m, n) > 2))
            Matrix3(m, n) = Matrix2(m, n);
        end
    end
end
toc

   