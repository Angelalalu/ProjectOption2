%% Read data
OptionData = csvread("spOptions_Bloomberg_02062018.csv", 1, 0);
OptionData(1:10,:)

strike_price = OptionData(:,1);
strike_price_avg = 0.5*(strike_price(1:end-1)+strike_price(2:end));

strike_price_full = [strike_price;strike_price_avg];
strike_price_full = sort(strike_price_full);
strike_price_full(1:10)

IndexList = [1:2:length(strike_price_full)]';

max(strike_price)
min(strike_price)

% strike_price_full = [min(strike_price):2.5:max(strike_price)]';
strike_price_full = strike_price;
IndexList = []
for i = 1:length(strike_price_full)
    findIdx = find(strike_price == strike_price_full(i));
    if ~isempty(findIdx)
        IndexList = [IndexList; i];
    end
end

isequal(strike_price_full(IndexList), strike_price)
%% Initialize
Cvar = zeros(length(strike_price_full), 1);
Cvar(IndexList) = OptionData(:,2);
alpha = 0.000001;
deltaKj = strike_price_full(2:end) - strike_price_full(1:end-1);

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
    'MaxFunctionEvaluations', 1e8, 'MaxIterations', 1e6,...
    'StepTolerance', 1e-12, 'FunctionTolerance', 1e-9);
lossFunc = @(x) LossFunction(x, Cvar, IndexList, alpha, deltaKj);
% x0 = zeros(length(strike_price_full), 1);
xInit = pchip(strike_price_full(IndexList), Cvar(IndexList), strike_price_full);
xInit_smooth = smooth(strike_price_full, xInit, 'lowess');
figure()
plot(strike_price_full, xInit)
hold on
scatter(strike_price_full, xInit_smooth)
% stem(strike_price_full(IndexList), Cvar(IndexList))



[x, fval, exitflag, output] = fmincon(lossFunc, ...
    xInit, A, b, [], [], [], [], [], options);
P = CalculateDerivativesWithXandDeltaK(x, deltaKj, 2);
% 
% P = CalculateDiscreteSecondDerivativeForXandDeltaK(x, deltaKj);

% P_b = P;
% isequal(P, P_b)

% ((x(3:end) - x(2:end-1)) ./ deltaKj(2:end) - ...
%     (x(2:end-1) - x(1:end-2)) ./ deltaKj(1:end-1)) ./ ...
%     (0.5*(deltaKj(2:end) + deltaKj(1:end-1)));
%% Lowess Function applied on optimalCList
f = smooth(strike_price_full, x, 'lowess');
xInit2 = f;
[x2, fval, exitflag, output] = fmincon(lossFunc, ...
    xInit2, A, b, [], [], [], [], [], options);

%% Calculate P
P = CalculateDerivativesWithXandDeltaK(x2, deltaKj, 2);
plot(strike_price_full(1:end-2), P)

%% Smooth 1d
x1d_smooth = smooth(strike_price_full(1:end-1), ...
    CalculateDerivativesWithXandDeltaK(x, deltaKj, 1), 'lowess');

x1d = CalculateDerivativesWithXandDeltaK(x, deltaKj, 1);
x2d_smooth = smooth(strike_price_full(1:end-2), ...
    CalculateDerivativesWithXandDeltaK(x, deltaKj, 2), 'lowess');
sht = [x1d, x1d_smooth];
sht(1:20, :)
%% Plots
% clf
lineWidth = 2;
figure()
subplot(5, 1, 1)
% scatter(strike_price_full, x)
% hold on
scatter(strike_price_full, x)
hold on
plot(strike_price_full, xInit_smooth, 'LineWidth', lineWidth)
legend("l2-norm", "xInitSmooth")
% hold on
% scatter(strike_price_full(1:end-1), x1d_smooth)
subplot(5, 1, 2)
scatter(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(x, deltaKj, 1))
hold on
plot(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 1), 'LineWidth', lineWidth)
legend("l2-norm", "xInitSmooth")
% stem(strike_price_full(1:2:length(strike_price_full)), ...
%     Cvar(1:2:length(strike_price_full)))
subplot(5, 1, 3)
scatter(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(x, deltaKj, 2))
hold on
plot(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 2), 'LineWidth', lineWidth)
legend("l2-norm", "xInitSmooth")
% hold on
% plot(strike_price_full(1:end-2), x2d_smooth)
subplot(5, 1, 4)
scatter(strike_price_full(1:end-3), CalculateDerivativesWithXandDeltaK(x, deltaKj, 3))
hold on
plot(strike_price_full(1:end-3), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 3), 'LineWidth', lineWidth)
legend("l2-norm", "xInitSmooth")
subplot(5, 1, 5)
scatter(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(x, deltaKj, 4))
hold on
plot(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 4), 'LineWidth', lineWidth)
legend("l2-norm", "xInitSmooth")
% plot(strike_price_full(1:end-2), P)
% hold on
% scatter(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(x, deltaKj, 4))
