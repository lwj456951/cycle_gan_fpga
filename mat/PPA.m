%function [co,sum] = PPA(PP)
%PPA 此处显示有关此函数的摘要
%   此处显示详细说明
[PP] = Booth_Encoder(a,b);
[c1_1,s1_1] = CSA(PP(8),PP(7),PP(6));
[c1_2,s1_2] = CSA(PP(5),PP(4),PP(3));
[c2_1,s2_1] = CSA(bitshift(c1_1,1),s1_1,s1_2);
[c2_2,s2_2] = CSA(bitshift(c1_2,1),PP(2),PP(1));

[c3_1,s3_1] = CSA(bitshift(c2_1,1),s2_1,s2_2);
[co,sum] = CSA(bitshift(c2_2,1),bitshift(c3_1,1),s3_1);


%end
