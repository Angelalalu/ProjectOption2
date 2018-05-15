%% Read Data
%       2           4        5
% secid,date,exdate,best_bid,best_offer,volume,
%                                        12
% impl_volatility,delta,gamma,vega,theta,strike_price,
%                   15                               20      21
% newdate,newexdate,date_length,low,high,open,return,cp_flag,close
spOptionData = csvread("spOptionData179.csv", 1, 0);
size(spOptionData)

spOptionData(1:10,:)

dividendList = [50, 49.42, 47.13, 45.67]; % 2018, 2017, 2016, 2015

dateLenColIdx = 1;
bidColIdx = 2;
askColIdx = 3;
strikeColIdx = 4;
cpFlagColIdx = 5;
closePriceColIdx = 6;
dividendColIdx = 7;
annlPayoutReturnColIdx = 8;
borrowInterestRateColIdx = 9;
lendInterestRateColIdx = 10;
interestRateColIdx = 11;
dateColStartIdx = 12;
% dateLenColIdx = 1;
% bidColIdx = 2;
% askColIdx = 3;
% strikeColIdx = 4;
% cpFlagColIdx = 5;
% closePriceColIdx = 6;
% dividendColIdx = 7;
% annlPayoutReturnColIdx = 8;
% borrowInterestRateColIdx = 9;
% lendInterestRateColIdx = 10;
% interestRateColIdx = 11;
% dateColStartIdx = 12;

%% Calculate d


%% Put-call Parity




%% Call only, June 20+, 2015
dateLen = 179;
spOptionData_expiration179_idx = find(spOptionData(:,dateLenColIdx) == dateLen & ...
                                        spOptionData(:,cpFlagColIdx) == 0 & ...
                                        spOptionData(:,dateColStartIdx+1) == 6 & ...
                                        spOptionData(:,dateColStartIdx+2) > 20 & ...
                                        spOptionData(:,dateColStartIdx) == 2015);
spOptionData_expiration179_idx(1:10)
spOptionData_expiration179 = spOptionData(spOptionData_expiration179_idx,:);
spOptionData_expiration179(1:10, :)
spOptionData_expiration179(1:10, 4)
spOptionData_expiration179(1:10, end)
spOptionData_expiration179(1:10, interestRateColIdx)
spOptionData_expiration179(1:10, interestRateColIdx)
mean(spOptionData_expiration179(:, interestRateColIdx))
spOptionData_expiration179(1:10, closePriceColIdx)
spOptionData_expiration179(1:10, annlPayoutReturnColIdx)

%% Temp read 1996 data
spOptionData_expiration179 = csvread("OptionDataWDiv1996_179.csv", 1, 0);

dateLenColIdx = 7;
bidColIdx = 3;
askColIdx = 4;
strikeColIdx = 2;
cpFlagColIdx = 1;
closePriceColIdx = 5;
dividendColIdx = 6;
annlPayoutReturnColIdx = 14;
borrowInterestRateColIdx = 15;
lendInterestRateColIdx = 16;
interestRateColIdx = 11;
dateColStartIdx = 8;

spOptionData_expiration179_idx = find(spOptionData_expiration179(:,cpFlagColIdx) == 0);
spOptionData_expiration179 = spOptionData_expiration179(spOptionData_expiration179_idx, :);

interestRate = mean(spOptionData_expiration179(:, interestRateColIdx));
closePrice = mean(spOptionData_expiration179(:, closePriceColIdx));
annlPayoutReturn = mean(spOptionData_expiration179(:, annlPayoutReturnColIdx));
spOptionData_expiration179_K = spOptionData_expiration179(:, strikeColIdx);
spOptionData_expiration179_C = (spOptionData_expiration179(:, bidColIdx) + ...
                                spOptionData_expiration179(:, askColIdx)) / 2;
C179 = spOptionData_expiration179_C / ...
    (closePrice*(annlPayoutReturn/interestRate)^(-dateLen/365));
K179 = spOptionData_expiration179_K;
<<<<<<< HEAD

%%
% ls = linspace(1,10);
% qua = ls.^2;
%
% qua = x;
% quaN1 = qua(1:end-2);
% quaL1 = qua(2:end-1);
% quaP1 = qua(3:end);
% sm = quaN1 - 2*quaL1 + quaP1;
% figure(2)
% plot(1:length(x), qua / 100)
% hold on
% plot(2:length(x)-1, sm)
% axis([0 100 -20 20])
% legend("C", "P");


%% New
%%
optimalCList = GetOptimalCList(KsampleList, C179, K179, CnegaListFunc);
save('optimalCList2015_179_May13.mat', 'optimalCList')

CnegaList = CnegaListFunc(5);
CListM1 = [CnegaList(1); optimalCList(1:end-1)];
CListP1 = [optimalCList(2:end);0];
PList = (interestRate^(dateLen/365) * (CListM1 - 2*optimalCList + CListP1)...
=======
%% Optimization Setting
clampSize = 4;
stepSize = 5;
alpha = 0.01;
KsampleList = [0:1200] * stepSize;
KsampleList = KsampleList(clampSize+1:end-clampSize);

negativeIdxList = [1:clampSize]';
CnegaListFunc = @(x) interestRate^(-dateLen/365) * ...
    (1 - negativeIdxList * (x / (closePrice * ...
    (annlPayoutReturn/interestRate)^(-dateLen/365))));
CnegaList = CnegaListFunc(200);

%%% Solve Optimization Problem
[optimalCList, Cvar, x, penaltyIdxList] = GetOptimalCList(KsampleList, C179, K179, CnegaList, alpha, clampSize);
% save('optimalCList_Clamp50_1996620_alpha0.mat', 'optimalCList')

%%% Calculate P from C
% CListM1 = [CnegaList(1); optimalCList(1:end-1)];
CListd1 = optimalCList(2:end);
CListd2 = optimalCList(1:end-1);
Cd1 = (CListd2 - CListd1) * 1;

CListP1 = optimalCList(3:end);
CListM1 = optimalCList(2:end-1);
CListN1 = optimalCList(1:end-2);

CListPP2 = optimalCList(5:end);
CListPP1 = optimalCList(4:end-1);
CListMMM = optimalCList(3:end-2);
CListNN1 = optimalCList(2:end-3);
CListNN2 = optimalCList(1:end-4);
Cd4 = CListNN2 - 4*CListNN1 + 6*CListMMM - 4*CListPP1 + CListPP2;

% [C179, K179]
% [CListP1, CListM1, CListN1, (CListN1 - 2*CListM1 + CListP1)]
% GetOmegaPrime(x, penaltyIdxList, Cvar, alpha, CnegaList, clampSize)

PList = (interestRate^(dateLen/365) * (CListN1 - 2*CListM1 + CListP1)...
>>>>>>> 3dc3415949f76d043ec6ecda29ee42e18f94e2df
        * closePrice * (annlPayoutReturn/interestRate)^(-dateLen/365))...
        / 25;

figure()
subplot(2, 1, 1)
scatter(1:length(optimalCList), optimalCList)
hold on
% plot(1:length(PList), PList)
% stem(-3:length(CnegaList)-4, CnegaList)
stem([1:length(Cvar)-clampSize] + clampSize, Cvar(1:end-clampSize))
stem([1:clampSize], CnegaList)
legend("C", "Cim", "Cnega")
title("alpha = " + num2str(alpha))
axis([1 length(Cvar) -inf inf])

subplot(2, 1, 2)
stem(1:length(optimalCList)-1, Cd1)
hold on
% scatter(1:length(PList), PList)
scatter(1:length(PList), CListN1 - 2*CListM1 + CListP1)
scatter(2:length(PList)-1, Cd4)
legend("Cd1", "P(Cd2)", "Cd4")
axis([1 length(Cvar) -inf inf])

%% Using First Order Condition
CVar = zeros(201,1);
% diag([3 3 3],0)
% diag([2 2],1)
Diag0 = diag(ones(2001,1)*(140+2*alpha),0);
Diag1 = diag(ones(2000,1)*(-112),1);
DiagN1 = diag(ones(2000,1)*(-112),-1);
Diag2 = diag(ones(1999,1)*56,2);
DiagN2 = diag(ones(1999,1)*56,-2);
Diag3 = diag(ones(1998,1)*(-16),3);
DiagN3 = diag(ones(1998,1)*(-16),-3);
Diag4 = diag(ones(1997,1)*2,4);
DiagN4 = diag(ones(1997,1)*2,-4);
coeff = Diag0+Diag1+Diag2+Diag3+Diag4+...
        DiagN1+DiagN2+DiagN3+DiagN4;

cimList = [];
for j = 1:2001
    kieqkjInd = find(K179 == KsampleList(j));
    if length(kieqkjInd)>0
        cimList = [cimList; C179(kieqkjInd(1))];
    else
        cimList = [cimList; 0];
    end
end

RHS = cimList*2*alpha;
RHS(1) = RHS(1) - dot(CnegaList, [-112;56;-16;2]);
RHS(2) = RHS(2) - dot(CnegaList(1:3), [56;-16;2]);
RHS(3) = RHS(3) - dot(CnegaList(1:2), [-16;2]);
RHS(4) = RHS(4) - CnegaList(1) * 2;

CVar = coeff \ RHS;
save('CVarListFOC2015_179.mat','CVar');
CVarM1 = [CnegaList(1); CVar(1:end-1)];
CVarP1 = [CVar(2:end);0];
PListFOC = (interestRate^(dateLen/365) * (CVarM1 - 2*CVar + CVarP1)...
        * closePrice * (annlPayoutReturn/interestRate)^(-dateLen/365))...
        / mean(KsampleList);
plot(PListFOC)


optimalCList = x;
CnegaList = CnegaListFunc(mean(KsampleList));
CListM1 = [CnegaList(1); optimalCList(1:end-1)];
CListP1 = [optimalCList(2:end);0];
PList = (interestRate^(dateLen/365) * (CListM1 - 2*optimalCList + CListP1)...
        * closePrice * (annlPayoutReturn/interestRate)^(-dateLen/365))...
        / mean(KsampleList);
x = optimalCList
figure(3)
plot(1:length(x), x)
hold on
stem(-3:length(x), [CnegaList'; Cvar])
axis([-5 700 -inf inf])
% CimList = C179(penaltyIdxList);
figure(4)
plot(1:length(x), PList)
