function [optC_list] = GetOptimalCList(KsampleList, Creal, Kreal, CnegaListFunc)
%% Debug data
% KsampleList = [200:205] * 5;
% KsampleList = [0:2000] * 5;
% Creal = C179;
% Kreal = K179;

%% Initialize
alpha = 10;
% 1: 1e-2, 2: 1e-4, 3:10
CnegaList = CnegaListFunc(5);

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

OmegaPrimeFunc = @(x) GetOmegaPrime(x, penaltyIdxList, Cvar, alpha, CnegaList);
x0 = zeros(length(KsampleList), 1);
options = optimoptions(@fminunc,'Display','iter','Algorithm','quasi-newton', ...
    'MaxIterations', 10000, 'MaxFunctionEvaluations', 1e8);

load('result_C179_2015620.mat')
[x,fval,exitflag,output] = fminunc(OmegaPrimeFunc, x0, options);
% save 'result_C179_2015620_new.mat' x
optC_list = x;
end