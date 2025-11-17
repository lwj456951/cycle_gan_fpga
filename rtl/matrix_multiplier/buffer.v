/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-10 15:36:00
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-11 16:47:13
 * @FilePath: \rtl\matrix_multiplier\buffer.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
 `include"./define.v"
module buffer #(
    parameter WIDTH = `WIDTH_DATA,
    parameter  LENGTH= 1
) (
    input clk,
    input rst_n,
    input clear,
    input[WIDTH-1:0] din,
    output[WIDTH-1:0] dout
);
reg[WIDTH-1:0] d_reg[0:LENGTH-1];
integer i;
always @(posedge clk or negedge rst_n) begin
    for(i=0;i<LENGTH;i=i+1)begin
        if(clear||~rst_n)
            d_reg[i] <= 'd0;
        else if(i==0)
            d_reg[i] <= din;
        else
            d_reg[i] <= d_reg[i-1]; 
    end
end
assign dout = d_reg[LENGTH-1];
endmodule