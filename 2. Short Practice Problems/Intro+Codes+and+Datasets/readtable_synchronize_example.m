clc
clear

% Load table with prices from Monday through Wednesday
MonWedTable = readtable('syncData.xls', 'Sheet', 'MonWed');
MonWedTable = table2timetable(MonWedTable);

% Load table with prices from Wednesday through Friday
WedFriTable = readtable('syncData.xls', 'Sheet', 'WedFri');
WedFriTable = table2timetable(WedFriTable);

% Perform synchronization with the different options
mergedTableUnion = synchronize(MonWedTable, WedFriTable, 'union');
mergedTableInter = synchronize(MonWedTable, WedFriTable, 'intersection');
mergedTableFirst = synchronize(MonWedTable, WedFriTable, 'first');
mergedTableLast = synchronize(MonWedTable, WedFriTable, 'last');

% Extract the dates and prices from the intersection table
mergedTableInter
Dates_Inter = mergedTableInter.Date
Prices_Inter = mergedTableInter.Price_MonWedTable








