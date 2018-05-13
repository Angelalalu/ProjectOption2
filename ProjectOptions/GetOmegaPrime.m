function omegaPrime = GetOmegaPrime(x, penaltyIdxList, Cvar, alpha)


x = [1000:1005];

omega = 0;

for jj = 1:length(x)
    GetCValue(x, jj-2)
    GetCValue(x, jj-1)
    GetCValue(x, jj)
    GetCValue(x, jj+1)
    GetCValue(x, jj+2)
end







end