/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-10-29 13:37:03
 * @LastEditors: lwj
 * @LastEditTime: 2025-10-30 13:42:06
 * @FilePath: \cycle_gan_fpga\rtl\conv1d\conv1d.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`timescale 1ns/1ps
`include"./define.v"
module conv1d#(
    parameter k = 16'd15,s=16'd1//k:kernel_size 1*k,s:stride 1*s
) (
    input clk,
    input w_en,
    input [k*`WIDTH_DATA-1:0] w,//w:weight
    input [k*`WIDTH_DATA-1:0] din,
    output [k*`WIDTH_DATA-1:0] dout
);
//load weight
reg[`WIDTH_DATA-1:0] w_reg[0:k-1];
integer i;
always @(posedge clk) begin
    for(i=0;i<k;i=i+1)
        if(w_en)
            w_reg[i] <= w[(i+1)*`WIDTH_DATA-1-:`WIDTH_DATA];
end




endmodule