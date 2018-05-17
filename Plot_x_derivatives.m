function Plot_x_derivatives(x, xInit_smooth, deltaKj, strike_price_full)

lineWidth = 2;
legend1 = "optimization result";
legend2 = "Lowess result";

xl = 2000;
xu = 3800;

figure()
subplot(5, 1, 1)
scatter(strike_price_full, x)
hold on
plot(strike_price_full, xInit_smooth, 'LineWidth', lineWidth)
axis([xl xu -0.1 50])
legend(legend1, legend2)

subplot(5, 1, 2)
scatter(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(x, deltaKj, 1))
hold on
plot(strike_price_full(1:end-1), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 1), 'LineWidth', lineWidth)
axis([xl xu -inf inf])
legend(legend1, legend2)

subplot(5, 1, 3)
scatter(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(x, deltaKj, 2))
hold on
plot(strike_price_full(1:end-2), CalculateDerivativesWithXandDeltaK(xInit_smooth, deltaKj, 2), 'LineWidth', lineWidth)
axis([xl xu -0.001 0.005])
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

h = suptitle('Uniform grid of strike prices');
set(h,'FontSize',20,'FontWeight','normal')
end