function xd = CalculateDerivativesWithXandDeltaK(x, deltaK, order)

for currentOrder = 1:order
    deltaK_avg = zeros(length(x)-1, 1);
    for i = 1:currentOrder
        deltaK_avg = deltaK_avg + deltaK(0+i:end-currentOrder+i);
    end
    deltaK_avg = deltaK_avg / currentOrder;
    xd = (x(2:end) - x(1:end-1)) ./ deltaK_avg;
    x = xd;    
end

end