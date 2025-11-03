/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-03 19:51:03
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-03 20:06:32
 * @FilePath: \conv1d\tb\MAC_tb.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
//~ `New testbench
`timescale  1ns / 1ps
`include"../define.v"
module tb_MAC;
reg clk,rst_n;
// MAC Parameters
parameter PERIOD = 10;
reg [`WIDTH_DATA*2-1:0]             exp_result;
// MAC Inputs
reg  [`WIDTH_DATA-1:0]   weight  = 0;
reg  [`WIDTH_DATA-1:0]   feature = 0;
reg  [`WIDTH_DATA*2-1:0] psum_in = 0;

// MAC Outputs
wire   [`WIDTH_DATA*2-1:0]                 psum_out;

// MAC Bidirs

initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
	clk=0;
	rst_n=0;
    #(PERIOD*2) rst_n  =  1;
end
integer i;
initial begin
    i=1;
    forever begin
        @(posedge clk);
        weight = 6;
        feature = 13;
        psum_in = 12;
        exp_result = weight*feature + psum_in;
    end
end
MAC  u_MAC (
    .weight  (weight  ),
    .feature (feature ),
    .psum_in (psum_in ),

    .psum_out(psum_out)
);

initial
begin
    #100000;
    $finish;
end

endmodule