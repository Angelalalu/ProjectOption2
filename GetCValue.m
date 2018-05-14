function Cval = GetCValue(x, idx, CnegaList, clampSize)

if idx < 1
    i = idx + clampSize;
    Cval = CnegaList(i);
elseif idx > length(x)
    Cval = 0;
else
    Cval = x(idx);
end
end