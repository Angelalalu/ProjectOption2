%% Read data
OptionDataFull = csvread("spOptions_Bloomberg_SeparateDate.csv", 1, 0);

yearIdx = 3;
monthIdx = 4;
dayIdx = 5;

OptionDataIdx = find(OptionDataFull(:,yearIdx) == 2018 & ...
                     OptionDataFull(:,monthIdx) == 1 & ...
                     OptionDataFull(:,dayIdx) == 25);
                        
OptionData = OptionDataFull(OptionDataIdx, :);
% OptionData = csvread("spOptions_Bloomberg_02062018.csv", 1, 0);

%% Add midpoints of strike prices
strike_price = OptionData(:,1);
strike_price_avg = 0.5*(strike_price(1:end-1)+strike_price(2:end));

strike_price_full = [strike_price;strike_price_avg];
strike_price_full = sort(strike_price_full);

IndexList = [1:2:length(strike_price_full)]'; % Indices of real strike prices
%% Initialize
Cvar = zeros(length(strike_price_full), 1);
Cvar(IndexList) = OptionData(:,2);
alpha = 0.000001;
deltaKj = strike_price_full(2:end) - strike_price_full(1:end-1);

%% Interpolation and Smooth
strike_price_full_25 = [min(strike_price):5:max(strike_price)]';
IndexList_25 = [];
for i = 1:length(strike_price_full_25)
    findIdx = find(strike_price_full == strike_price_full_25(i));
    if ~isempty(findIdx)
        IndexList_25 = [IndexList_25; i];
    end
end

IndexList_25_R = [];
for i = 1:length(strike_price_full_25)
    findIdx = find(strike_price == strike_price_full_25(i));
    if ~isempty(findIdx)
        IndexList_25_R = [IndexList_25_R; i];
    end
end

[IndexList_25_R(1:10), strike_price(1:10), strike_price_full_25(IndexList_25_R(1:10))]
[IndexList_25(1:10), strike_price_full(1:10), strike_price_full_25(IndexList_25(1:10))]

Cvar_25 = zeros(length(strike_price_full_25), 1);
Cvar_25(IndexList_25_R) = OptionData(:,2);

xInit_25 = spline(strike_price_full_25(IndexList_25_R), Cvar_25(IndexList_25_R), strike_price_full_25);
xInit_smooth_25_Func = fit([strike_price_full_25 ones(size(strike_price_full_25, 1), 1)], xInit_25, 'lowess');
xInit_smooth_25 = xInit_smooth_25_Func([strike_price_full_25 ones(size(strike_price_full_25, 1), 1)]);

deltaKj_25 = strike_price_full_25(2:end) - strike_price_full_25(1:end-1);
Plot_x_derivatives(xInit_smooth_25, xInit_smooth_25, deltaKj_25, strike_price_full_25);
%%% Create A, b for 25

A1_25 = diag(-ones(length(strike_price_full_25), 1), 0) + ...
    diag(ones(length(strike_price_full_25) - 1, 1), 1);
A1_25 = A1_25(1:end-1,:);
b1_25 = zeros(length(strike_price_full_25)-1, 1);

A2_25 = diag([deltaKj_25; 0; 0], 0) + ...
    diag(-[0;deltaKj_25] - [deltaKj_25; 0], 1) + ...
    diag([0; deltaKj_25(1:end-1)], 2);
A2_25 = -A2_25(2:end-2,2:end);
b2_25 = zeros(length(strike_price_full_25)-2, 1);

A_25 = [A1_25; A2_25];
b_25 = [b1_25; b2_25];

%%% Optimization for 25
options = optimoptions('fmincon','Display','iter','Algorithm','sqp', ...
    'MaxFunctionEvaluations', 1e8, 'MaxIterations', 1e6,...
    'StepTolerance', 1e-12, 'FunctionTolerance', 1e-9);
lossFunc_25 = @(x) LossFunction(x, Cvar_25, IndexList_25_R, alpha, deltaKj_25);
[x_25, fval, exitflag, output] = fmincon(lossFunc_25, ...
    xInit_smooth_25, A_25, b_25, [], [], [], [], [], options);

Plot_x_derivatives(x_25, xInit_smooth_25, deltaKj_25, strike_price_full_25);

xInit_smooth = xInit_smooth_25(IndexList_25);
xInit_smooth = x_25(IndexList_25);
%% Create A, b
A1 = diag(-ones(length(strike_price_full), 1), 0) + ...
    diag(ones(length(strike_price_full) - 1, 1), 1);
A1 = A1(1:end-1,:);
b1 = zeros(length(strike_price_full)-1, 1);

A2 = diag([deltaKj; 0; 0], 0) + ...
    diag(-[0;deltaKj] - [deltaKj; 0], 1) + ...
    diag([0; deltaKj(1:end-1)], 2);
A2 = -A2(2:end-2,2:end);
b2 = zeros(length(strike_price_full)-2, 1);

A = [A1; A2];
b = [b1; b2];

%% Solve problem
options = optimoptions('fmincon','Display','iter','Algorithm','sqp', ...
    'MaxFunctionEvaluations', 1e8, 'MaxIterations', 1e6,...
    'StepTolerance', 1e-12, 'FunctionTolerance', 1e-9);
lossFunc = @(x) LossFunction(x, Cvar, IndexList, alpha, deltaKj);

[x, fval, exitflag, output] = fmincon(lossFunc, ...
    xInit_smooth, A, b, [], [], [], [], [], options);

%% Plots
% clf
lineWidth = 2;
legend1 = "optimization result";
legend2 = "Lowess result";

figure()
subplot(5, 1, 1)
scatter(strike_price_full, x)
hold on
plot(strike_price_full, xInit_smooth, 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 2)
scatter(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(x, deltaKj, 1))
hold on
plot(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 1), 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 3)
plot(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(x, deltaKj, 2))
hold on
plot(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 2), 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 4)
scatter(strike_price_full(1:end-3), CalculateDerivativesWithXandDeltaK(x, deltaKj, 3))
hold on
plot(strike_price_full(1:end-3), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 3), 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 5)
scatter(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(x, deltaKj, 4))
hold on
plot(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 4), 'LineWidth', lineWidth)
legend(legend1, legend2)

h = suptitle('Optimization vs Lowess');
set(h,'FontSize',20,'FontWeight','normal')