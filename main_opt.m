%% Read data
OptionDataFull = csvread("spOptions_Bloomberg_SeparateDate.csv", 1, 0);

yearIdx = 3;
monthIdx = 4;
dayIdx = 5;

OptionDataIdx = find(OptionDataFull(:,yearIdx) == 2018 & ...
                     OptionDataFull(:,monthIdx) == 4 & ...
                     OptionDataFull(:,dayIdx) == 17);
                        
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

x = [1.74378080e03 1.50514836e03 1.32601179e03 1.20376034e03 1.13834550e03 1.13040354e03 1.12152538e03 1.10539165e03 1.08030826e03 1.06419932e03 1.04421013e03 1.02033861e03 9.92316467e02 9.60514544e02 9.32308336e02 9.09205683e02 8.91023593e02 8.70369800e02 8.47115460e02 8.21062723e02 7.93668920e02 7.68066143e02 7.43274958e02 7.18388048e02 6.93361352e02 6.80929508e02 6.68594282e02 6.56356325e02 6.44256225e02 6.32180685e02 6.20288113e02 6.08054695e02 5.95590580e02 5.83240389e02 5.70826697e02 5.58074647e02 5.43567227e02 5.27304364e02 5.10355679e02 5.00952167e02 4.99296715e02 4.97748206e02 4.95148003e02 4.91495945e02 4.86829996e02 4.84367989e02 4.81886603e02 4.79406844e02 4.76928715e02 4.71978465e02 4.67040676e02 4.62112866e02 4.57190947e02 4.52274228e02 4.47365327e02 4.42473615e02 4.37599083e02 4.35150257e02 4.32693129e02 4.30227677e02 4.27755235e02 4.22813846e02 4.17899442e02 4.13012904e02 4.08139471e02 4.03279130e02 3.98431856e02 3.93597759e02 3.88754688e02 3.86325080e02 3.83888373e02 3.81444434e02 3.78994020e02 3.74079581e02 3.69160246e02 3.64258618e02 3.59392706e02 3.54560349e02 3.49761535e02 3.44979094e02 3.40185858e02 3.37782671e02 3.35375768e02 3.32965865e02 3.30554249e02 3.25728712e02 3.20912151e02 3.18504975e02 3.16097064e02 3.13688417e02 3.11278683e02 3.08871508e02 3.06469588e02 3.04072969e02 3.01680826e02 2.99291678e02 2.96903053e02 2.94515690e02 2.92130175e02 2.89746604e02 2.87364984e02 2.84981590e02 2.82594151e02 2.80202664e02 2.77819029e02 2.75445428e02 2.73081838e02 2.70722453e02 2.68356539e02 2.65983686e02 2.63603893e02 2.61233447e02 2.58873579e02 2.56524153e02 2.54184652e02 2.51850073e02 2.49509352e02 2.47162486e02 2.44809870e02 2.42452329e02 2.40097828e02 2.37746549e02 2.35399836e02 2.33061029e02 2.30733096e02 2.28415368e02 2.26102007e02 2.23792756e02 2.21487145e02 2.19183384e02 2.16881473e02 2.14581037e02 2.12280994e02 2.09981344e02 2.07682084e02 2.05384163e02 2.03092103e02 2.00808649e02 1.98533824e02 1.96265318e02 1.94002415e02 1.91744133e02 1.89487103e02 1.87231326e02 1.84980025e02 1.82733161e02 1.80488852e02 1.78246580e02 1.76006600e02 1.73768859e02 1.71533353e02 1.69303507e02 1.67085622e02 1.64879374e02 1.62675105e02 1.60472415e02 1.58271385e02 1.56079879e02 1.53901662e02 1.51737173e02 1.49586112e02 1.47444553e02 1.45306643e02 1.43168063e02 1.41028512e02 1.38889320e02 1.36752146e02 1.34622745e02 1.32504930e02 1.30399185e02 1.28305510e02 1.26220754e02 1.24144880e02 1.22078017e02 1.20020172e02 1.17971436e02 1.15931808e02 1.13901540e02 1.11881091e02 1.09872276e02 1.07875095e02 1.05885770e02 1.03904362e02 1.01931665e02 9.99717018e01 9.80269159e01 9.60973092e01 9.41829594e01 9.22832116e01 9.03908217e01 8.85059870e01 8.66293982e01 8.47647890e01 8.29134282e01 8.10851660e01 7.92800307e01 7.74977678e01 7.57342213e01 7.39847511e01 7.22490515e01 7.05224554e01 6.88038608e01 6.70932651e01 6.53917019e01 6.37044235e01 6.20402557e01 6.04011902e01 5.87872040e01 5.71931252e01 5.56139906e01 5.40526965e01 5.25213437e01 5.10202473e01 4.95468827e01 4.81008872e01 4.66822615e01 4.52772780e01 4.38853432e01 4.25063227e01 4.11402873e01 3.97967281e01 3.84791861e01 3.71933836e01 3.59416027e01 3.47239425e01 3.35404025e01 3.23897388e01 3.12655014e01 3.01553238e01 2.90586200e01 2.79848809e01 2.69415535e01 2.59286334e01 2.49451141e01 2.39907653e01 2.30604878e01 2.21548415e01 2.12745266e01 2.04231192e01 1.95996156e01 1.88033796e01 1.80344157e01 1.72930547e01 1.65792244e01 1.58902000e01 1.52241523e01 1.45798462e01 1.33563778e01 1.22194269e01 1.11689825e01 1.02024502e01 8.90531284e00 7.78758935e00 6.18207067e00 4.89706668e00 3.85289421e00 3.05731960e00 2.50920977e00 2.03077320e00 1.53746147e00 1.36574292e00 1.05887606e00 8.77994216e01 7.14135413e01 4.99900184e01 3.52024195e01 2.62702569e01 2.01228808e01 1.85310742e01]';
length(x)
length(strike_price_full)
length(deltaKj)
%% Plots
% clf
lineWidth = 2;
legend1 = "optimization result";
legend2 = "Lowess result";

figure()
subplot(5, 1, 1)
scatter(strike_price_full, x)
hold on
% plot(strike_price_full, xInit_smooth, 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 2)
scatter(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(x, deltaKj, 1))
hold on
% plot(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 1), 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 3)
plot(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(x, deltaKj, 2))
hold on
% plot(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 2), 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 4)
scatter(strike_price_full(1:end-3), CalculateDerivativesWithXandDeltaK(x, deltaKj, 3))
hold on
% plot(strike_price_full(1:end-3), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 3), 'LineWidth', lineWidth)
legend(legend1, legend2)

subplot(5, 1, 5)
scatter(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(x, deltaKj, 4))
hold on
% plot(strike_price_full(1:end-4), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 4), 'LineWidth', lineWidth)
legend(legend1, legend2)

h = suptitle('Optimization vs Lowess');
set(h,'FontSize',20,'FontWeight','normal')