function Cval = GetCValue(x, idx, CnegaList)

if idx < 1
    i = -(idx - 1);
    Cval = CnegaList(i);
elseif idx > length(x)
    Cval = 0;
else
    Cval = x(idx);
end
end