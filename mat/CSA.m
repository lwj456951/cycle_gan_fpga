function [co,s] = CSA(a,b,c)
%CSA 此处显示有关此函数的摘要
%   此处显示详细说明
tmp = bitand(c,bitor(a,b));
co = bitor(bitand(a,b),tmp);
s = bitxor(a,b);
s = bitxor(s,c);
end

