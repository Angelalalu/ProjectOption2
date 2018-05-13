function Cval = GetCValue(x, idx)

if idx < 1
    Cval = idx - 1;
elseif idx > length(x)
    Cval = 0;
else
    Cval = x(idx);
end
end