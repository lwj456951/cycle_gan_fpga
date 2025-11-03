/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-10-30 14:20:29
 * @LastEditors: lwj
 * @LastEditTime: 2025-10-31 13:12:32
 * @FilePath: \conv1d\Wallace_PPA_16.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */

`timescale 1ns/1ps
`include"./define.v"
//PPA (Partial Product Compress)
module Wallace_PPA_16 (input[`WIDTH_DATA*2*8-1:0] PP,  //Partial Product(32bits) *8
                       output[`WIDTH_DATA*2-1:0] cout,
                       output[`WIDTH_DATA*2-1:0] sum);
    //nonsense ,just for compile
    reg[`WIDTH_DATA*2-1:0] PP_reg[0:7];
    integer j;
    always @(*) begin
        for(j = 0;j<8;j = j+1)
            PP_reg[j] <= PP[j*`WIDTH_DATA*2+:`WIDTH_DATA*2];
    end
    
    // wallace tree 4 level
    wire[`WIDTH_DATA*2-1:0] cout_1_1,cout_1_2,cout_2_1,cout_2_2,cout_3_1,cout_4_1;
    wire[`WIDTH_DATA*2-1:0] sum_1_1,sum_1_2,sum_2_1,sum_2_2,sum_3_1,sum_4_1;
    
    genvar i;
    generate
    for(i = 0;i<`WIDTH_DATA*2;i= i+1)begin
        CSA_3_2  u_1_1 (
        .a   (PP_reg[0][i]),
        .b   (PP_reg[1][i]),
        .cin (PP_reg[2][i]),
        
        .cout(cout_1_1[i]),
        .sum (sum_1_1[i])
        );
        
        CSA_3_2  u_1_2 (
        .a   (PP_reg[3][i]),
        .b   (PP_reg[4][i]),
        .cin (PP_reg[5][i]),
        
        .cout(cout_1_2[i]),
        .sum (sum_1_2[i])
        );
        
        CSA_3_2  u_2_1 (
        .a   (cout_1_1[i]),
        .b   (sum_1_1[i]),
        .cin (cout_1_2[i]),
        
        .cout(cout_2_1[i]),
        .sum (sum_2_1[i])
        );
        
        CSA_3_2  u_2_2 (
        .a   (sum_1_2[i]),
        .b   (PP_reg[6][i]),
        .cin (PP_reg[7][i]),
        
        .cout(cout_2_2[i]),
        .sum (sum_2_2[i])
        );
        
        CSA_3_2  u_3_1 (
        .a   (sum_2_1[i]),
        .b   (cout_2_2[i]),
        .cin (sum_2_2[i]),
        
        .cout(cout_3_1[i]),
        .sum (sum_3_1[i])
        );
        
        CSA_3_2  u_3_2 (
        .a   (cout_2_1[i]),
        .b   (cout_3_1[i]),
        .cin (sum_3_1[i]),
        
        .cout(cout[i]),
        .sum (sum[i])
        );
    end
    endgenerate
    
endmodule
