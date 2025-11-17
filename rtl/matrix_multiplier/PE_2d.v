/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-05 10:14:46
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-12 12:01:30
 * @FilePath: \rtl\matrix_multiplier\PE_2d.v
 * @Description: 
 * @Copyright (c) 2022 by lwj email: jia200151@126.com, All Rights Reserved.
 */
 `include"./define.v"
module PE_2d (
    input clk,
    input rst_n,
    input load_en,
    input shift_en_in,
    input[`WIDTH_DATA-1:0] w_in,
    input[`WIDTH_DATA-1:0] fm_in,
    input[`WIDTH_DATA*2-1:0] psum_in,
    output shift_en_out,
    output[`WIDTH_DATA-1:0] w_out,
    output reg[`WIDTH_DATA-1:0] w_reg,
    output[`WIDTH_DATA-1:0] fm_out,
    output [`WIDTH_DATA*2-1:0] psum_out
);
    reg[`WIDTH_DATA-1:0] s_reg;//shift_reg
    //reg[`WIDTH_DATA-1:0] w_reg;//weight_reg
    reg[`WIDTH_DATA-1:0] fm_reg;//feature map reg 
    reg[`WIDTH_DATA*2-1:0] psum_in_reg;
    reg shift_en_in_reg;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            s_reg <= 'd0;
            w_reg <= 'd0;
            fm_reg <= 'd0;
            psum_in_reg <= 'd0;
            shift_en_in_reg <= 0;
        end
        else begin
            s_reg <= load_en?w_in:s_reg;
            w_reg <= shift_en_in?s_reg:w_reg;
            fm_reg <= fm_in;
            psum_in_reg <= psum_in;
            shift_en_in_reg <= shift_en_in;
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
assign shift_en_out = shift_en_in_reg;
endmodule