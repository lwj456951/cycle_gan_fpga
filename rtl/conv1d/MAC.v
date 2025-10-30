
/***
 * @Author: jia200151@126.com
 * @Date: 2025-10-30 19:11:35
 * @LastEditors: lwj
 * @LastEditTime: 2025-10-30 19:16:05
 * @FilePath: \conv1d\MAC.v
 * @Description:
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`timescale 1ns/1ps
`include"./define.v"
module MAC (input[`WIDTH_DATA-1:0] weight,
            input[`WIDTH_DATA-1:0] feature,
            input[`WIDTH_DATA*2-1:0] psum_in,
            output[`WIDTH_DATA*2-1:0] psum_out);
   
//PPA_cout,PPA_sum(`WIDTH_DATA*2) = weight * feature(`WIDTH_DATA)
//psum_out = psum_in + PPA_cout + PPA_sum
    wire [`WIDTH_DATA*2*8-1:0]                     PP;
    
    // Booth_Encoder Bidirs
    
    Booth_Encoder  u_Booth_Encoder (
    .weight (weight),
    .feature(feature),
    
    .PP     (PP)
    );
    wire [`WIDTH_DATA*2-1:0]                   PPA_cout;
    wire [`WIDTH_DATA*2-1:0]                   PPA_sum ;
    
    // Wallace_PPA_16 Bidirs
    
    Wallace_PPA_16  u_Wallace_PPA_16 (
    .PP  (PP),
    
    .cout(PPA_cout),
    .sum (PPA_sum)
    );
    // CSA_3_2 Bidirs 
    //compresion psum_in + PPA_cout + PPA_sum
    wire [`WIDTH_DATA*2-1:0]                   adder_cout;
    wire [`WIDTH_DATA*2-1:0]                   adder_sum ;
    CSA_3_2  u_CSA (
    .a   (PPA_cout[i]),
    .b   (PPA_sum[i]),
    .cin (psum_in[i]),
    
    .cout(adder_cout[i]),
    .sum (adder_sum[i])
    );
    
    // CSA_3_2 Bidirs
    
    CSA_3_2  u_CSA_adder (
    .a   (adder_cout[i]),
    .b   (adder_sum[i]),
    .cin (`WIDTH_DATA*2'd0),
    
    .cout(),
    .sum (psum_out)
    );
endmodule
