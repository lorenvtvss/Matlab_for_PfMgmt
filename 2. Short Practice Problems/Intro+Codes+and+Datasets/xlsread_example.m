clc
clear

myData = xlsread('mydata.xls', 'Sheet1');

% if you want to get numeric data only
myDataSubset = xlsread('mydata.xls', 'Sheet1', 'A3:B8');

% if you want to get numeric and text data
    % e.g. headers are in text or other texts
[numeric, text] = xlsread('mydata.xls', 'Sheet1');


