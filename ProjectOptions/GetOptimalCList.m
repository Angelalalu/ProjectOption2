function [optC_list] = GetOptimalCList(KsampleList, Creal, Kreal)
%% Debug data
KsampleList = [200:205] * 5;
Creal = C179;
Kreal = K179;

%% Initialize
alpha = 1e-2;

%% Loop begin
Cvar = zeros(length(KsampleList), 1);
penaltyIdxList = [];

for j = 1:length(KsampleList)
    Ksample = KsampleList(j);
    K_i_eq_j_list = find(Kreal == Ksample);
    Cim = mean(Creal(K_i_eq_j_list));
    Cvar(j) = Cim;
    
    if ~isnan(Cim)
        penaltyIdxList = [penaltyIdxList; j];
    end
end

OmegaPrime = @(x) GetOmegaPrime(x, penaltyIdxList, Cvar, alpha);

x = fminunc(fun, x0)




end