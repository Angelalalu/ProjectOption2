function [loss] = LossFunction(x, Cvar, IndexList, alpha, deltaKj, norm)
loss0 = (sum(CalculateDerivativesWithXandDeltaK(x, deltaKj, 4).^2))^0.5;
xd = CalculateDerivativesWithXandDeltaK(x, deltaKj, 3);
if norm == inf
    loss = max(abs(xd));
else
    loss = (sum(abs(xd) .^ norm))^(1/norm);
end

% loss = (sum((abs(xd) .^ 1.2)))^(1/1.2);
% loss = (sum(abs(xd) .^ 1.3))^(1/1.3);
% loss = (sum((abs(xd) .^ 1.5)))^(1/1.5);
% loss = (sum(xd .^ 2))^0.5;
% loss = max(abs(CalculateDerivativesWithXandDeltaK(x, deltaKj, 4)));
loss = loss0 + loss + sum((x(IndexList) - Cvar(IndexList)).^2) * alpha;
end