/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-04 15:56:39
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-04 17:49:36
 * @FilePath: \conv1d\tb\tb_conv_1d.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
//~ `New testbench
`timescale  1ns / 1ps
`include"../define.v"
module tb_conv1d;

// conv1d Parameters
parameter PERIOD = 10;
parameter k = 16'd3;

// conv1d Inputs
reg                      clk     = 0;
reg                      rst_n   = 0;
reg                      w_valid = 0;
reg signed [k*`WIDTH_DATA-1:0] w_in    = 0;
reg signed [`WIDTH_DATA-1:0]   x=0;
reg signed [`WIDTH_DATA-1:0]   x_reg=0;
reg signed [`WIDTH_DATA-1:0]   b       = 0;

// conv1d Outputs
wire signed[`WIDTH_DATA*2-1:0]                      y;

// conv1d Bidirs

initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end
reg signed [`WIDTH_DATA-1:0] w_in_reg[0:k-1]    ;
reg signed [`WIDTH_DATA*2-1:0] exp_result[0:k-1] ,exp_result_reg[0:k-1] ;

integer j;
initial begin
    forever begin
        for(j=0;j<k;j=j+1)begin
            w_in[j*`WIDTH_DATA+:`WIDTH_DATA] = w_in_reg[j];
        end
        @(posedge clk);
    end
end
integer i;
initial begin
    for(i=0;i<k;i=i+1)begin
        w_in_reg[i] = 0;
    end
    for(i=0;i<k;i=i+1)begin
            exp_result[i] <=0;
    end
    @(posedge rst_n);
    
    
    for(i=0;i<k;i=i+1)begin
        w_in_reg[i] = $random%10;
    end
    w_valid = 1;
    repeat(2)@(posedge clk);
    w_valid = 0;
    b=$random%10;
    forever begin
        x = $random%10; 
        @(posedge clk);
        x_reg <= x;
        
        for(i=0;i<k;i=i+1)begin
            exp_result_reg[i] <= exp_result[i];
            if(i==0)
                exp_result[i] <= b + w_in_reg[i]*x_reg;
            else
                exp_result[i] <= exp_result_reg[i-1] + w_in_reg[i]*x_reg;
        end
    end
end
conv1d #(
    .k(k)
) u_conv1d (
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .w_valid(w_valid),
    .w_in   (w_in   ),
    .x      (x    ),
    .b      (b      ),

    .y      (y      )
);

initial
begin
    #100000;
    $finish;
end

endmodule