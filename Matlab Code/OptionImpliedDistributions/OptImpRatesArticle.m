%% Estimating option-implied probability distributions.
%
% Author: Ken Deeley
% Copyright 2015 The MathWorks, Inc.

%% Notation.
% In this script we use the following notation for option-related
% quantities.
%
% * K - strike price of the asset ($).
% * C - call price of the asset ($).
% * P - put price of the asset ($).
% * S - underlying asset price ($).
% * T - time to expiry of the options (years).
% * rf - risk-free rate, expressed as a decimal number in the range [0, 1].
% * sigma - asset volatility, expressed as a decimal number in the range
%   [0, 1].

%% Load the hypothetical option data and associated parameters.
% Suppose that we observe, from the market, the following option prices for
% an underlying asset.
load OptionData
display(D)
% We note that we may have only a small number of observed (K, C) or (K, P)
% pairs for each distinct expiry time.

%% Compute the implied volatility from the market data.
% To do this, we use the Financial Toolbox function BLSIMPV to compute the
% implied volatilities from the available market data. This function uses
% an iterative approach via comparison with prices from the Black-Scholes 
% model.
D.sigmaCall = blsimpv(D.S, D.K, D.rf, D.T, D.C, [], [], [], {'call'});
D.sigmaPut = blsimpv(D.S, D.K, D.rf, D.T, D.P, [], [], [], {'put'});

%% Set up figure options to use within the script.
figOpts = {'Units', 'Normalized', 'Position', 0.25*[1, 1, 2, 2]};

%% Visualize the market data in strike-volatility (K, sigma) space.
% We stratify the chart by time to expiry since we are interested in the
% (K, sigma) pairs for each distinct value of T.

% Option call prices.
figure(figOpts{:})
gscatter(D.K, D.sigmaCall, D.T)
xlabel('Strike price, K')
ylabel('Implied volatility, \sigma')
title('(K, \sigma) pairs for option call prices')
grid
T0 = unique(D.T);
T0Text = num2str(T0);
legText = [repmat('T = ', size(T0Text, 1), 1), T0Text];
legend(legText, 'Location', 'eastoutside')
hold on
% Store the plot colors for future use.
ax = gca;
cols = flipud(cat(1, ax.Children.Color));

% Repeat for thefigure(figOpts{:})
gscatter(D.K, D.sigmaPut, D.T)
xlabel('Strike price, K')
ylabel('Implied volatility, \sigma')
title('(K, \sigma) pairs for option put prices')
grid
legend(legText, 'Location', 'eastoutside')
hold on put prices.


%% Use interpolation to estimate more sample points.
% In order to produce a reasonable approximation to the strike price 
% probability density functions, we need more data points. One approach is
% to use cubic spline interpolation in (K, sigma) space to produce more
% sample points. We do this for each distinct expiry time.

% Define sample strike prices for the interpolation.
extrapThresh = 0.01;
fineK = linspace(min(D.K)-extrapThresh, ...
                 max(D.K)+extrapThresh, 500).';
% Preallocate space for the results.
sigmaCallInterp = NaN(numel(fineK), numel(T0)); 
sigmaPutInterp = sigmaCallInterp;
for k = 1:numel(T0)
    % Extract strike/sigma values for each value of T.
    idx = D.T == T0(k);
    tempK = D.K(idx);
    tempSigCall = D.sigmaCall(idx);
    tempSigPut = D.sigmaPut(idx);
    % Store the results.
    sigmaCallInterp(:, k) = interp1(tempK, tempSigCall, fineK, 'spline', 'extrap');
    sigmaPutInterp(:, k) = interp1(tempK, tempSigPut, fineK, 'spline', 'extrap');
    % Add to the chart.
    figure(1)
    plot(fineK, sigmaCallInterp(:, k), 'Color', cols(k, :), 'LineWidth', 2)
    figure(2)
    plot(fineK, sigmaPutInterp(:, k), 'Color', cols(k, :), 'LineWidth', 2)
end % for

%% Use the SABR model to perform the interpolation.
% The SABR model is often used in situations in which cubic spline
% interpolation does not give satisfactory results. For more details on the
% SABR model and the techniques used here, refer to the documentation 
% example "Calibrate the SABR Model" and the references therein.

for k = numel(T0):-1:1
    % Define settle and exercise dates for the options, in string format.
    idx = D.T == T0(k);
    settle = datetime('today');
    exercise = char(settle + 365*T0(k));
    % Extract the (K, sigma) values for each expiry time.
    tempK = D.K(idx);
    tempSigmaCall = D.sigmaCall(idx); 
    tempSigmaPut = D.sigmaPut(idx);
    midPt = round(numel(tempK)/2);
    tempForward = tempK(midPt);
    tempCall = tempSigmaCall(midPt);
    tempPut = tempSigmaPut(midPt);
    % Define an appropriate value for beta, and calibrate the other
    % parameters alpha, rho and nu.
    beta = 0.2;    
    objFunCall = @(X) tempSigmaCall - ...
    blackvolbysabr(X(1), beta, X(2), X(3), char(settle), ...
    exercise, tempForward, tempK);
    objFunPut = @(X) tempSigmaPut - ...
    blackvolbysabr(X(1), beta, X(2), X(3), char(settle), ...
    exercise, tempForward, tempK);
    XCall = lsqnonlin(objFunCall, [0.5, 0, 0.5], [0, -1, 0], [Inf, 1, Inf]);
    XPut = lsqnonlin(objFunPut, [0.5, 0, 0.5], [0, -1, 0], [Inf, 1, Inf]);
    CallAlpha(k) = XCall(1);
    CallRho(k) = XCall(2);
    CallNu(k) = XCall(3);
    PutAlpha(k) = XPut(1);
    PutRho(k) = XPut(2);
    PutNu(k) = XPut(3);
    % Use the calibrated parameters to interpolate the implied
    % volatilities.
    sigmaCallSABR(:, k) = blackvolbysabr(CallAlpha(k), beta, CallRho(k), CallNu(k), ...
        char(settle), exercise, tempForward, fineK);
    sigmaPutSABR(:, k) = blackvolbysabr(PutAlpha(k), beta, PutRho(k), PutNu(k), ...
        char(settle), exercise, tempForward, fineK);
end % for

%% Plot the results of the SABR interpolation.
figure(figOpts{:})
gscatter(D.K, D.sigmaCall, D.T)
hold on
for k = 1:numel(T0)
    plot(fineK, sigmaCallSABR(:, k), 'LineWidth', 2, 'Color', cols(k, :))
end % for
xlabel('K')
ylabel('\sigma')
title('(K, \sigma) pairs for option call prices, SABR interpolation')
grid
legend(legText, 'Location', 'eastoutside')

figure(figOpts{:})
gscatter(D.K, D.sigmaPut, D.T)
hold on
for k = 1:numel(T0)
    plot(fineK, sigmaPutSABR(:, k), 'LineWidth', 2, 'Color', cols(k, :))
end % for
xlabel('K')
ylabel('\sigma')
title('(K, \sigma) pairs for option put prices, SABR interpolation')
grid
legend(legText, 'Location', 'eastoutside')

%% Transform the data from volatility to option price space.
% After interpolation in (K, sigma) space, either via cubic splines, SABR
% interpolation, or some other method, we obtain enough data points to
% estimate the implied strike price density functions at each expiry time.

% We begin by converting the (K, sigma) pairs into (K, C) (respectively,
% (K, P)) space.
% Preallocation.
newC = NaN(size(sigmaCallSABR));
newP = NaN(size(sigmaPutSABR));
% Extract scalar asset price and risk-free rate values.
S = D.S(1);
rf = D.rf(1);
for k = 1:numel(T0)    
    newC(:, k) = blsprice(S, fineK, rf, T0(k), sigmaCallSABR(:, k));
    newP(:, k) = blsprice(S, fineK, rf, T0(k), sigmaPutSABR(:, k));
end % for

%% Estimate the implied densities by approximating derivatives.
% Approximate the first derivative, at each distinct expiry time.
% We use the discrete approximation to the first derivative.
dK = diff(fineK);
Cdash = diff(newC) ./ repmat(dK, 1, size(newC, 2));
Pdash = diff(newP) ./ repmat(dK, 1, size(newP, 2));

% Approximate the second derivatives.
d2K = dK(2:end);
Cddash = diff(Cdash) ./ repmat(d2K, 1, size(Cdash, 2));
Pddash = diff(Pdash) ./ repmat(d2K, 1, size(Pdash, 2));

%% Use the approximate derivatives to estimate each density function.
% We remove any negative values prior to the estimation process.
% Preallocate space for the PDF approximations.
approxCallPDFs = NaN(size(Cddash));
approxPutPDFs = NaN(size(Pddash));
% Set any negative values to zero.
Cddash(Cddash < 0) = 0;
Pddash(Pddash < 0) = 0;
for k = 1:size(Cddash, 2)
    approxCallPDFs(:, k) = exp(rf * T0(k)) * Cddash(:, k);    
    approxPutPDFs(:, k) = exp(rf * T0(k)) * Pddash(:, k);
end % for

%% Plot the functions approximated using this technique.
pdfK = fineK(3:end);
figure(figOpts{:})
for k = 1:size(approxCallPDFs, 2)
    subplot(2, 4, k)
    plot(pdfK, approxCallPDFs(:, k), 'LineWidth', 2, 'Color', cols(k, :))
    xlabel('Strike (K)')
    ylabel('Value')
    title(['T = ', num2str(T0(k))])
    grid
end % for
figure(figOpts{:})
for k = 1:size(approxPutPDFs, 2)
    subplot(2, 4, k)
    plot(pdfK, approxPutPDFs(:, k), 'LineWidth', 2, 'Color', cols(k, :))
    xlabel('Strike (K)')
    ylabel('Value')
    title(['T = ', num2str(T0(k))])
    grid
end % for

%% Fit interpolants to each approximated function.
pdfFitsCall = cell(1, size(approxCallPDFs, 2));
pdfFitsPut = cell(1, size(approxPutPDFs, 2));
for k = 1:numel(T0)
    pdfFitsCall{k} = fit(pdfK, approxCallPDFs(:, k), 'linear');
    pdfFitsPut{k} = fit(pdfK, approxPutPDFs(:, k), 'linear');
end % for

%% Normalize and visualise the pdfs estimated by cubic spline interpolation.
fitKCall = linspace(min(D.K)-4, max(pdfK)+6, 5000).';
fitKCall = repmat({fitKCall}, 1, numel(pdfFitsCall));
fitKPut = fitKCall;
fitValsCall = cell(1, numel(pdfFitsCall));
fitValsPut = fitValsCall;
figure(figOpts{:})
for k = 1:numel(pdfFitsCall)
    subplot(2, 4, k)
    % Evaluate the fit.
    fitValsCall{k} = pdfFitsCall{k}(fitKCall{k});
    % Truncate to ensure positive PDF values.
    posIdx = fitValsCall{k} >= 0;
    fitKCall{k} = fitKCall{k}(posIdx);
    fitValsCall{k} = fitValsCall{k}(posIdx);
    % Ensure the area under the curve is 1.
    A = trapz(fitKCall{k}, fitValsCall{k});
    fitValsCall{k} = fitValsCall{k}/A;
    plot(fitKCall{k}, fitValsCall{k}, 'Color', cols(k, :), 'LineWidth', 2)
    xlabel('Strike (K)')
    ylabel('Density')
    title(['T = ', num2str(T0(k))])
    grid
end % for
figure(figOpts{:})
for k = 1:numel(pdfFitsPut)
    subplot(2, 4, k)
    % Evaluate the fit.
    fitValsPut{k} = pdfFitsPut{k}(fitKPut{k});
    % Truncate to ensure positive PDF values.
    posIdx = fitValsPut{k} >= 0;
    fitKPut{k} = fitKPut{k}(posIdx);
    fitValsPut{k} = fitValsPut{k}(posIdx);
    % Ensure the area under the curve is 1.
    A = trapz(fitKPut{k}, fitValsPut{k});
    fitValsPut{k} = fitValsPut{k}/A;
    plot(fitKPut{k}, fitValsPut{k}, 'Color', cols(k, :), 'LineWidth', 2)
    xlabel('Strike (K)')
    ylabel('Density')
    title(['T = ', num2str(T0(k))])
    grid
end % for

%% Randomly sample from the distributions defined by these densities.
nSamples = 1e3;
priceSimCall = NaN(numel(pdfFitsCall), nSamples);
priceSimPut = NaN(numel(pdfFitsPut), nSamples);
for k = 1:numel(T0)
    priceSimCall(k, :) = randsample(fitKCall{k}, nSamples, true, fitValsCall{k});
    priceSimPut(k, :) = randsample(fitKPut{k}, nSamples, true, fitValsPut{k});
end % for

%% Create the fan charts.

% Using call price data.
historical = [0, S]; % Define T = 0 initially.
forecastCall = [T0, priceSimCall]; % Different expiry times and simulations.
forecastPut = [T0, priceSimPut];
fanplot(historical, forecastCall)
set(gcf, figOpts{:})
thresh = [2, 7];
ylim([S-thresh(1), S+thresh(2)])
ylabel('Future Asset Price')
title('Option-Implied Asset Prices, Using Call Price Data')
xlabel('Future Time (Years)')

% Using put price data.
fanplot(historical, forecastPut)
set(gcf, figOpts{:})
ylim([S-thresh(1), S+thresh(2)])
ylabel('Future Asset Price')
title('Option-Implied Asset Prices, Using Put Price Data')
xlabel('Future Time (Years)')

% Show the average forecast.
avgForecast = (forecastCall + forecastPut)/2;
fanplot(historical, avgForecast)
set(gcf, figOpts{:})
ylim([S-thresh(1), S+thresh(2)])
ylabel('Future Asset Price')
title('Option-Implied Asset Prices')
xlabel('Future Time (Years)')