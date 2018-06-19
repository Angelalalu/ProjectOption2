

% speDateList = ["20130102", "20130103"];
speDateList = strings(1, length(nameList));
% speDate = "20130102";

listing = dir('tempdata');
nameList = {listing.name};
for i = 4:length(nameList)
    speDateList(i) = nameList{i};
end
speDateList = speDateList(4:end);

dateVecList = [];
idx05VecList = [];
idx10VecList = [];
idx25VecList = [];
idx50VecList = [];
idx75VecList = [];
idx90VecList = [];
idx95VecList = [];
for speDate = speDateList
    [dateVec, idx05Vec, idx10Vec, idx25Vec, ...
        idx50Vec, idx75Vec, idx90Vec, idx95Vec] = ...
        OptImpRatesArticle(speDate);

    dateVecList = [dateVecList; dateVec];
    idx05VecList = [idx05VecList; idx05Vec];
    idx10VecList = [idx10VecList; idx10Vec];
    idx25VecList = [idx25VecList; idx25Vec];
    idx50VecList = [idx50VecList; idx50Vec];
    idx75VecList = [idx75VecList; idx75Vec];
    idx90VecList = [idx90VecList; idx90Vec];
    idx95VecList = [idx95VecList; idx95Vec];

end

resultTable = table(dateVecList, idx05VecList, idx10VecList, ...
    idx25VecList, idx50VecList, idx75VecList, idx90VecList, ...
    idx95VecList);

save("resultTable30.mat", "resultTable")

% figure()
% plot(resultTable.idx05VecList)
writetable(resultTable,'sp500_percentiles_matlab.csv','Delimiter',',','QuoteStrings',true)
