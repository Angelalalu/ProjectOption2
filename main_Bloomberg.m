%% Read data
OptionData = csvread("spOptions_Bloomberg_02062018.csv", 1, 0);
OptionData(1:10,:)

strike_price = OptionData(:,1);
strike_price_avg = 0.5*(strike_price(1:end-1)+strike_price(2:end));

strike_price_full = [strike_price;strike_price_avg];
strike_price_full = sort(strike_price_full);
strike_price_full(1:10)

% strike_price_full = [min(strike_price):2.5:max(strike_price)]';
% % strike_price_full = strike_price;
% IndexList = []
% for i = 1:length(strike_price_full)
%     findIdx = find(strike_price == strike_price_full(i));
%     if ~isempty(findIdx)
%         IndexList = [IndexList; i];
%     end
% end

isequal(strike_price_full(IndexList), strike_price)

%% Initialize

Cvar = zeros(length(strike_price_full), 1);
IndexList = [1:2:length(strike_price_full)]';
Cvar(IndexList) = OptionData(:,2);
alpha = 0.000001;
deltaKj = strike_price_full(2:end) - strike_price_full(1:end-1);

lossFunc = @(x) LossFunction(x, Cvar, IndexList, alpha, deltaKj, inf);

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
%% Interpolation and Smooth
% xInit = pchip(strike_price_full(IndexList), Cvar(IndexList), strike_price_full);
xInit = spline(strike_price_full(IndexList), Cvar(IndexList), strike_price_full);
xInit_smooth = smooth(strike_price_full, xInit, 'lowess');
xInit_smooth = malowess(strike_price_full, xInit);
xInit_smooth = fit([strike_price_full ones(size(strike_price_full, 1), 1)], xInit, 'lowess');
xInit_smooth = xInit_smooth([strike_price_full ones(size(strike_price_full, 1), 1)]);

x_opt_25 = subsref(matfile('x_opt_25.mat'), struct('type','.','subs','x'));
xInit_smooth_25 = subsref(matfile('xInit_smooth_25.mat'), struct('type','.','subs','xInit_smooth'));

strike_price_full_25 = [min(strike_price):2.5:max(strike_price)]';
IndexList_25 = [];
for i = 1:length(strike_price_full_25)
    findIdx = find(strike_price_full == strike_price_full_25(i));
    if ~isempty(findIdx)
        IndexList_25 = [IndexList_25; i];
    end
end

[IndexList_25(1:10), strike_price_full(1:10), strike_price_full_25(IndexList_25(1:10))]

xInit_smooth = x_opt_25(IndexList_25);
xInit_smooth = xInit_smooth_25(IndexList_25);

figure()
plot(strike_price_full, xInit)
hold on
scatter(strike_price_full, xInit_smooth)




%% Read Stata Result
lowessStata = csvread("lowess_result_stata.csv", 0, 1);
xInitStata = lowessStata(:, 2);
xInit_smoothStata = lowessStata(:, 5);
xInit_diff = xInitStata - xInit;
figure()
plot(xInit_diff)

xInitStata_smoothMatlab = malowess(strike_price_full, xInitStata);
xInit_smooth_diff = xInitStata_smoothMatlab - xInit_smoothStata;

figure()
plot(strike_price_full, xInit_smooth_diff)
hold on
scatter(strike_price_full, xInitStata_smoothMatlab)
scatter(strike_price_full, xInit_smoothStata)
legend("diff", "xInitStata_smoothMatlab", "xInit_smoothStata")
%% Solve problem
options = optimoptions('fmincon','Display','iter','Algorithm','sqp', ...
    'MaxFunctionEvaluations', 1e8, 'MaxIterations', 1e6,...
    'StepTolerance', 1e-12, 'FunctionTolerance', 1e-9);
% x0 = zeros(length(strike_price_full), 1);
% stem(strike_price_full(IndexList), Cvar(IndexList))
% load('x_opt_25.mat')
% load('xInit_smooth_25.mat')

[x, fval, exitflag, output] = fmincon(lossFunc, ...
    xInit_smooth, A, b, [], [], [], [], [], options);
% save("xInit_smooth_25.mat", "xInit_smooth")
% save("x_opt_25.mat", "x")

% 
% P = CalculateDiscreteSecondDerivativeForXandDeltaK(x, deltaKj);

% P_b = P;
% isequal(P, P_b)

% ((x(3:end) - x(2:end-1)) ./ deltaKj(2:end) - ...
%     (x(2:end-1) - x(1:end-2)) ./ deltaKj(1:end-1)) ./ ...
%     (0.5*(deltaKj(2:end) + deltaKj(1:end-1)));
%% Lowess Function applied on optimalCList
f = smooth(strike_price_full, x,'lowess');
xInit2 = f;
[x2, fval, exitflag, output] = fmincon(lossFunc, ...
    xInit2, A, b, [], [], [], [], [], options);

%% Calculate P
P = CalculateDerivativesWithXandDeltaK(x, deltaKj, 2);
% P = CalculateDerivativesWithXandDeltaK(x2, deltaKj, 2);
plot(strike_price_full(1:end-2), P)

%% Plots
Plot_x_derivatives(x, xInit_smooth, deltaKj, strike_price_full)
% clf
% x = xInit_smoothStata
% lineWidth = 2;
% legend1 = "optimization result";
% legend2 = "Lowess result";
% figure()
% subplot(2, 1, 1)
% scatter(strike_price_full, x)
% hold on
% stem(strike_price_full(1:2:length(strike_price_full)), ...
%     Cvar(1:2:length(strike_price_full)))
% subplot(2, 1, 2)
% plot(strike_price_full(1:end-2), P)
% hold on
% scatter(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(x, deltaKj, 4))
% hold on
% plot(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 4), 'LineWidth', lineWidth)
% legend("l2-norm", "xInitSmooth")
% h = suptitle('Uniform grid of strike prices');
% set(h,'FontSize',20,'FontWeight','normal')
% plot(strike_price_full(1:end-2), P)
% hold on
% scatter(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(x, deltaKj, 4))
