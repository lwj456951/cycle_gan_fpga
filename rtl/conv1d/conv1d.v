/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-10-29 13:37:03
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-04 16:43:26
 * @FilePath: \conv1d\conv1d.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`timescale 1ns/1ps
`include"./define.v"
module conv1d#(
    parameter k = 16'd3//k:kernel_size 1*k
) (
    input clk,
    input rst_n,
    input w_valid,
    input [k*`WIDTH_DATA-1:0] w_in,//w:weight
    input [`WIDTH_DATA-1:0] x,
    input [`WIDTH_DATA-1:0] b,//bias
    output signed[`WIDTH_DATA*2-1:0] y//y=b+w0*x0+w1*x1+w0*x2
);

// PE Inputs
reg  [`WIDTH_DATA-1:0]   fm_in   = 0;
reg  [`WIDTH_DATA*2-1:0] psum_in = 0;

// PE Outputs
wire[`WIDTH_DATA-1:0]                    w_out   ;
wire [`WIDTH_DATA-1:0]                   fm_out  ;
wire [`WIDTH_DATA*2-1:0]                   psum_out[0:k-1];

// PE Bidirs


genvar  i;
generate
    for(i=0;i<k;i=i+1) begin :inst_PE
        if(i==0)
            PE  u_PE (
                .clk     (clk     ),
                .rst_n   (rst_n   ),
                .w_in    (w_in[i*`WIDTH_DATA+:`WIDTH_DATA]    ),
                .w_valid (w_valid ),
                .fm_in   (x ),
                .psum_in ({{`WIDTH_DATA{b[`WIDTH_DATA-1]}},b} ),

                .w_out   (w_out   ),
                .fm_out  (fm_out  ),
                .psum_out(psum_out[i])
            );
        else begin

            PE  u_PE (
                .clk     (clk     ),
                .rst_n   (rst_n   ),
                .w_in    (w_in[i*`WIDTH_DATA+:`WIDTH_DATA]    ),
                .w_valid (w_valid ),
                .fm_in   (x ),
                .psum_in (psum_out[i-1]),

                .w_out   (w_out   ),
                .fm_out  (fm_out  ),
                .psum_out(psum_out[i])
            );
        end
    end
endgenerate
assign y=psum_out[k-1];
endmodule