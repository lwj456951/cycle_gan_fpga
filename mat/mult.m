close all
clear

%%
a = int16(6);
b = int16(13);
c = a * b;

%%
a_bin = dec2bin(a,16);
b_bin = dec2bin(b,16);
[PP] = Booth_Encoder(a,b);
[co,sum] = PPA(PP);
result = bitshift(co,1) + sum;