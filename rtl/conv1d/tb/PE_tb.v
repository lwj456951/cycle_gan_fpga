/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-04 11:08:37
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-04 11:51:40
 * @FilePath: \conv1d\tb\PE_tb.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
//~ `New testbench
`timescale  1ns / 1ps
`include"../define.v"
module tb_PE;
// PE Parameters
parameter PERIOD = 10;

// PE Inputs
reg                      clk     = 0;
reg                      rst_n   = 0;
reg  signed [`WIDTH_DATA-1:0]   w_in    = 0;
reg                      w_valid = 0;
reg  signed[`WIDTH_DATA-1:0]   fm_in   = 0;
reg  signed[`WIDTH_DATA*2-1:0] psum_in = 0;

// PE Outputs
wire   [`WIDTH_DATA-1:0]                 w_out   ;
wire    [`WIDTH_DATA-1:0]                fm_out  ;
wire   [`WIDTH_DATA*2-1:0]                psum_out;

// PE Bidirs

initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end
integer exp_result,exp_result_1,exp_result_2;
initial begin
    exp_result = 0;
    @(posedge rst_n);
    w_valid =  1;
    forever begin
        w_in=$random%10;
        fm_in=$random%10;
        psum_in = $random%10;
        exp_result = psum_in + w_in*fm_in;
        @(posedge clk);
        exp_result_1 <= exp_result;
        exp_result_2 <= exp_result_1;
        
    end
end
PE  u_PE (
    .clk     (clk     ),
    .rst_n   (rst_n   ),
    .w_in    (w_in    ),
    .w_valid (w_valid ),
    .fm_in   (fm_in   ),
    .psum_in (psum_in ),

    .w_out   (w_out   ),
    .fm_out  (fm_out  ),
    .psum_out(psum_out)
);

initial
begin
    #1000000;
    $finish;
end

endmodule