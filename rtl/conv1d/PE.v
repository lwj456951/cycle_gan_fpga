/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-04 10:38:43
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-04 11:39:54
 * @FilePath: \conv1d\PE.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`timescale 1ns/1ps
`include"./define.v"

module PE (
    input clk,
    input rst_n,
    input[`WIDTH_DATA-1:0] w_in,
    input w_valid,
    input[`WIDTH_DATA-1:0] fm_in,
    input[`WIDTH_DATA*2-1:0] psum_in,
    output[`WIDTH_DATA-1:0] w_out,
    output[`WIDTH_DATA-1:0] fm_out,
    output [`WIDTH_DATA*2-1:0] psum_out
);
reg[`WIDTH_DATA-1:0] w_reg;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        w_reg <= 'd0;
    else if(w_valid)
        w_reg <= w_in;
    else
        w_reg <= w_reg;
end
reg[`WIDTH_DATA-1:0] fm_reg;
reg[`WIDTH_DATA*2-1:0] psum_reg;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        fm_reg <= 'd0;
        psum_reg <= 'd0;
    end
    else begin
        fm_reg <= fm_in;
        psum_reg <= psum_in;
    end
end

// MAC Bidirs
wire[`WIDTH_DATA*2-1:0] psum_out_MAC;
reg[`WIDTH_DATA*2-1:0] psum_out_reg;
MAC  u_MAC (
    .weight  (w_reg  ),
    .feature (fm_reg ),
    .psum_in (psum_reg ),

    .psum_out(psum_out_MAC)
);

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        psum_out_reg <= 'd0;
    end
    else begin
        psum_out_reg <= psum_out_MAC;
    end
end
assign psum_out = psum_out_reg;
endmodule