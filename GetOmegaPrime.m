function omegaPrime = GetOmegaPrime(x, penaltyIdxList, Cvar, alpha, CnegaList)

% x = [1000:1005]';
omega = 0;
for jj = 1:length(x)
    omega = omega + (GetCValue(x, jj-2, CnegaList) - ...
                     4*GetCValue(x, jj-1, CnegaList) + ...
                     6*GetCValue(x, jj, CnegaList) - ...
                     4*GetCValue(x, jj+1, CnegaList) + ...
                     GetCValue(x, jj+2, CnegaList))^2;
%     GetCValue(x, jj-2)
%     GetCValue(x, jj-1)
%     GetCValue(x, jj)
%     GetCValue(x, jj+1)
%     GetCValue(x, jj+2) 
end
omegaPrime = omega + alpha * sum((Cvar(penaltyIdxList) - x(penaltyIdxList)) .^2);
end