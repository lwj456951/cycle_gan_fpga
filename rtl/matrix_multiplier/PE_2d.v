/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-05 10:14:46
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-05 10:50:50
 * @FilePath: \rtl\conv2d\PE_2d.v
 * @Description: 
 * @Copyright (c) 2022 by lwj email: jia200151@126.com, All Rights Reserved.
 */
 `include"./define.v"
module PE_2d (
    input clk,
    input rst_n,
    input[`WIDTH_DATA-1:0] w_in,
    input[`WIDTH_DATA-1:0] fm_in,
    input[`WIDTH_DATA*2-1:0] psum_in,
    output[`WIDTH_DATA-1:0] w_out,
    output[`WIDTH_DATA-1:0] fm_out,
    output [`WIDTH_DATA*2-1:0] psum_out
);
    reg[`WIDTH_DATA-1:0] s_reg;//shift_reg
    reg[`WIDTH_DATA-1:0] w_reg;//weight_reg
    reg[`WIDTH_DATA-1:0] fm_reg;//feature map reg 
    reg[`WIDTH_DATA*2-1:0] psum_in_reg;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            s_reg <= 'd0;
            w_reg <= 'd0;
            fm_reg <= 'd0;
            psum_in_reg <= 'd0;
        end
        else begin
            s_reg <= w_in;
            w_reg <= s_reg;
            fm_reg <= fm_in;
            psum_in_reg <= psum_in;
        end
    end

MAC  u_MAC (
    .weight  (w_reg  ),
    .feature (fm_reg ),
    .psum_in (psum_in_reg ),

    .psum_out(psum_out)
);
assign w_out = s_reg;
assign fm_out = fm_reg;

endmodule