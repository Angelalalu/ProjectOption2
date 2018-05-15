function [loss] = LossFunction(x, Cvar, IndexList, alpha, deltaKj)
loss = sum(CalculateDerivativesWithXandDeltaK(x, deltaKj, 4).^2);
loss = loss + sum((x(IndexList) - Cvar(IndexList)).^2) * alpha;
end