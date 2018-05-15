OptionData = csvread("spOptions_Bloomberg_02062018.csv", 1, 0);
OptionData(1:10,:)

strike_price = OptionData(:,1);
strike_price_avg = 0.5*(strike_price(1:end-1)+strike_price(2:end));

strike_price_full = [strike_price;strike_price_avg];
strike_price_full = sort(strike_price_full);
strike_price_full(1:10)

Cvar = zeros(length(strike_price_full), 1);
IndexList = [1:2:length(strike_price_full)]';
Cvar(IndexList) = OptionData(:,2);



