%% Read data
OptionData = csvread("spOptions_Bloomberg_02062018.csv", 1, 0);
OptionData(1:10,:)

strike_price = OptionData(:,1);
strike_price_avg = 0.5*(strike_price(1:end-1)+strike_price(2:end));

strike_price_full = [strike_price;strike_price_avg];
strike_price_full = sort(strike_price_full);
strike_price_full(1:10)

test_data = (strike_price_full - 3500) .^2;
test_data(1:10)
test_data_2ndd = CalculateDerivativesWithXandDeltaK(test_data, deltaKj, 2)

%% Initialize

Cvar = zeros(length(strike_price_full), 1);
IndexList = [1:2:length(strike_price_full)]';
Cvar(IndexList) = test_data([1:2:length(strike_price_full)]');
alpha = 0.000001;
deltaKj = strike_price_full(2:end) - strike_price_full(1:end-1);

lossFunc = @(x) LossFunction(x, Cvar, IndexList, alpha, deltaKj);

%% Create A, b
A1 = diag(-ones(length(strike_price_full), 1), 0) + ...
    diag(ones(length(strike_price_full) - 1, 1), 1);
A1 = A1(1:end-1,:);
b1 = zeros(length(strike_price_full)-1, 1);
size(A1)
size(b1)

% size([deltaKj; 0; 0])
% size(-[0;deltaKj] - [deltaKj; 0])
% size([0; deltaKj(1:end-1)])
A2 = diag([deltaKj; 0; 0], 0) + ...
    diag(-[0;deltaKj] - [deltaKj; 0], 1) + ...
    diag([0; deltaKj(1:end-1)], 2);
A2 = -A2(2:end-2,2:end);
b2 = zeros(length(strike_price_full)-2, 1);
size(A2)
size(b2)

A = [A1; A2];
b = [b1; b2];
size(A)
size(b)

%% Solve problem
options = optimoptions('fmincon','Display','iter','Algorithm','sqp', ...
    'MaxFunctionEvaluations', 1e8, 'MaxIterations', 1e6, ...
    'StepTolerance', 1e-12);
% x0 = zeros(length(strike_price_full), 1);
% xInit = test_data;
xInit = pchip(strike_price_full(IndexList), Cvar(IndexList), strike_price_full);
% figure()
% plot(strike_price_full, xInit)
% hold on
% scatter(strike_price_full(IndexList), Cvar(IndexList))
[x, fval, exitflag, output] = fmincon(lossFunc, ...
    xInit, A, b, [], [], [], [], [], options);

% 
% P = CalculateDiscreteSecondDerivativeForXandDeltaK(x, deltaKj);

% P_b = P;
% isequal(P, P_b)

% ((x(3:end) - x(2:end-1)) ./ deltaKj(2:end) - ...
%     (x(2:end-1) - x(1:end-2)) ./ deltaKj(1:end-1)) ./ ...
%     (0.5*(deltaKj(2:end) + deltaKj(1:end-1)));
%% Calculate P
P = CalculateDerivativesWithXandDeltaK(x, deltaKj, 2);
P2 = CalculateDerivativesWithXandDeltaK(test_data, deltaKj, 2);

%% Plots
figure()
subplot(2, 1, 1)
plot(strike_price_full, x)
hold on
stem(strike_price_full(1:2:length(strike_price_full)), ...
    Cvar(1:2:length(strike_price_full)))
subplot(2, 1, 2)
plot(strike_price_full(1:end-2), P)
hold on
scatter(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(x, deltaKj, 4))
