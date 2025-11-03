
function [PP] = Booth_Encoder(a,b)
%BOOTH_ENCODER 此处显示有关此函数的摘要
%   此处显示详细说明
% a = int16(6);
% b = int16(13);
a_bin = dec2bin(a,16);
b_bin = dec2bin(b,16);
a_bin = strcat(a_bin,'0');
PP = int32(zeros(1,8));
PPC = zeros(1,8);
i=8;
test = strcat(a_bin(2*i-1),a_bin(2*i),a_bin(2*i+1));
for i = 1:8
    test = strcat(a_bin(2*i-1),a_bin(2*i),a_bin(2*i+1));
    switch test
        case '000'
            PPC(i) = 0;
        case '001'
            PPC(i) = 1;
        case '010'
            PPC(i) = 1;
        case '011'
            PPC(i) = 2;
        case '100'
            PPC(i) = -2;
        case '101'
            PPC(i) = -1;
        case '110'
            PPC(i) = -1;
        case '111'
            PPC(i) = 0;
    end

end

for i = 1:8
    j = 8-i;
    switch PPC(i)
        case 0  
            PP(i) = int32(0);
        case 1
            PP(i) = int32(bitshift(bin2dec(b_bin),2*j));
        case 2
            PP(i) = int32(bitshift(int32(bin2dec(b_bin)),2*j+1));
        case -1
            PP(i) = int32(bitshift(int32(bitcmp(bin2dec(b_bin)))+1,2*j));
        case -2
             PP(i) = bitshift(bitcmp(bitshift(int32(bin2dec(b_bin)),1))+1,2*j,'int32');

    end
end
PP_bin = dec2bin(PP,32);

end

