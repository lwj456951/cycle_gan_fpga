%function [outputArg1,outputArg2] = PPA(inputArg1,inputArg2)
%PPA 此处显示有关此函数的摘要
%   此处显示详细说明
close all
clear
[PP] = Booth_Encoder(9,7);
[c1_1,s1_1] = CSA(PP(8),PP(7),PP(6));
[c1_2,s1_2] = CSA(PP(5),PP(4),PP(3));
[c2_1,s2_1] = CSA(c1_1,s1_1,c1_2);
[c2_2,s2_2] = CSA(s1_2,PP(2),PP(1));

[c3_1,s3_1] = CSA(s2_1,c2_2,s2_2);
[co,sum] = CSA(c2_1,c3_1,s3_1);
%end

