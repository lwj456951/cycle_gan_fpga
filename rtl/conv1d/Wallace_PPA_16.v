/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-10-29 16:12:26
 * @LastEditors: lwj
 * @LastEditTime: 2025-10-30 14:01:28
 * @FilePath: \cycle_gan_fpga\rtl\conv1d\Wallace_PPA_16.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`timescale 1ns/1ps
`include"./define.v"
//PPA (Partial Product Compress)
module Wallace_PPA_16 (
    input[`WIDTH_DATA*2*8-1:0] PP,//Partial Product(32bits) *8
    output[`WIDTH_DATA*2-1:0] cout,
    output[`WIDTH_DATA*2-1:0] sum
);

reg[`WIDTH_DATA-1:0] PP_reg[0:7];
integer i;
always @(*) begin
    for(i=0;i<7;i=i+1)
        PP_reg[i] <= PP[(i+1)*`WIDTH_DATA-1-:`WIDTH_DATA];
end
// CSA_3_2 Parameters

// CSA_3_2 Inputs
reg   a   = 0;
reg   b   = 0;
reg   cin = 0;

// CSA_3_2 Outputs


// CSA_3_2 Bidirs

CSA_3_2  u_CSA_3_2 (
    .a   (a   ),
    .b   (b   ),
    .cin (cin ),

    .cout(cout),
    .sum (sum )
);


endmodule