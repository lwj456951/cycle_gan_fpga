/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-10-31 10:53:48
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-03 19:46:04
 * @FilePath: \conv1d\Booth_Wallace_Multiplier.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`timescale 1ns/1ps
`include"./define.v"
module Booth_Wallace_Multipiler(input[`WIDTH_DATA-1:0] weight,
                                input[`WIDTH_DATA-1:0] feature,
                                output[`WIDTH_DATA*2-1:0] result_out);

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
wire [`WIDTH_DATA*2-1:0]                   PPA_cout_r;
assign PPA_cout_r = PPA_cout << 1;
// Wallace_PPA_16 Bidirs

Wallace_PPA_16  u_Wallace_PPA_16 (
.PP  (PP),

.cout(PPA_cout),
.sum (PPA_sum)
);
// adder
assign result_out = PPA_cout_r + PPA_sum;

endmodule
