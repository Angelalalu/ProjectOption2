function [loss] = LossFunction(x, Cvar, IndexList, alpha, deltaKj)
% loss = sum(CalculateDerivativesWithXandDeltaK(x, deltaKj, 4).^2);

xd = CalculateDerivativesWithXandDeltaK(x, deltaKj, 3);
% loss = sum(abs(xd));
% loss = sum(abs(xd) .^ 1.1);
loss = sum((abs(xd) .^ 1.2));
% loss = sum(abs(xd) .^ 1.3);
% loss = sum((abs(xd) .^ 1.5));
% loss = sum(xd .^ 2);
% loss = max(abs(xd));
% loss = max(abs(CalculateDerivativesWithXandDeltaK(x, deltaKj, 4)));
loss = loss + sum((x(IndexList) - Cvar(IndexList)).^2) * alpha;
end