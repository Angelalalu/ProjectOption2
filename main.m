[x1, xInit_smooth_1, deltaKj_1, strike_price_full_1] = GetResult(2018, 1, 25);
Plot_x_derivatives(x1, xInit_smooth_1, deltaKj_1, strike_price_full_1)
[x2, xInit_smooth_2, deltaKj_2, strike_price_full_2] = GetResult(2018, 2, 6);
Plot_x_derivatives(x2, xInit_smooth_2, deltaKj_2, strike_price_full_2)
[x3, xInit_smooth_3, deltaKj_3, strike_price_full_3] = GetResult(2018, 4, 17);
Plot_x_derivatives(x3, xInit_smooth_3, deltaKj_3, strike_price_full_3)

figure()
subplot(2,1,1)
plot(strike_price_full_1, x1, 'lineWidth', 3)
hold on
plot(strike_price_full_2, x2, 'lineWidth', 3)
plot(strike_price_full_3, x3, 'lineWidth', 3)
legend("01/25/2018","02/06/2018","04/17/2018")
title("Call Option Prices")

subplot(2,1,2)
plot(strike_price_full_1(1:end-2), ...
    CalculateDerivativesWithXandDeltaK(x1, deltaKj_1, 2), 'lineWidth', 3)
hold on
plot(strike_price_full_2(1:end-2), ...
    CalculateDerivativesWithXandDeltaK(x2, deltaKj_2, 2), 'lineWidth', 3)
plot(strike_price_full_3(1:end-2), ...
    CalculateDerivativesWithXandDeltaK(x3, deltaKj_3, 2), 'lineWidth', 3)
legend("01/25/2018","02/06/2018","04/17/2018")
title("Probability Distribution")

save("xd4l2_xd3linf_result.mat")