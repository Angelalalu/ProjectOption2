%% Read Data
%       2           4        5          
% secid,date,exdate,best_bid,best_offer,volume,
%                                        12
% impl_volatility,delta,gamma,vega,theta,strike_price,
%                   15                               20      21
% newdate,newexdate,date_length,low,high,open,return,cp_flag,close
spOptionData = csvread("sp500_option_prices_merged.csv");
size(spOptionData)

spOptionData(1:10,:)

dividendList = [50, 49.42, 47.13, 45.67]; % 2018, 2017, 2016, 2015
dateColIdx = 2;
bidColIdx = 4;
askColIdx = 5;
strikeColIdx = 12;
expirColIdx = 15;
cpFlagColIdx = 20;
closePriceColIdx = 21;

%% Calculate d


%% Put-call Parity




%% Call only, June 20+, 2015
spOptionData_expiration179_idx = find(spOptionData(:,end) == 179 & ...
                                        spOptionData(:,4) == 0 & ...
                                        floor(mod(spOptionData(:,2), 10000) / 100) == 6 & ...
                                        mod(spOptionData(:,2), 100) > 20 & ...
                                        floor(spOptionData(:,2) / 10000) == 2015);
spOptionData_expiration179_idx(1:10)

spOptionData_expiration179 = spOptionData(spOptionData_expiration179_idx,:);
spOptionData_expiration179(1:10, 2)
spOptionData_expiration179(1:10, 4)
spOptionData_expiration179(1:10, end)

KsampleList = [0:2000] * 5;
spOptionData_expiration179_C = (spOptionData_expiration179(:, 5) + ...
                                spOptionData_expiration179(:, 6)) / 2;
                            
% tmp = [spOptionData_expiration179_C, ...
%     spOptionData_expiration179(:, 5), ...
%     spOptionData_expiration179(:, 6)];
% tmp(1:10, :)

spOptionData_expiration179_K = spOptionData_expiration179(:, 14);

C179 = spOptionData_expiration179_C;
K179 = spOptionData_expiration179_K;

%%