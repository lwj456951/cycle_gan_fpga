/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-11 16:01:57
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-17 13:18:32
 * @FilePath: \rtl\matrix_multiplier\tb\tb_matrix_multiplier.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
//~ `New testbench
`timescale  1ns / 1ps
`include"../define.v"
module tb_matrix_multiplier;

// matrix_multiplier Parameters
parameter PERIOD = 10;
parameter M                 = 16'd4     ;
parameter K                 = 16'd3     ;
parameter N                 = 16'd3     ;
parameter WIDTH_W_ADDR      = $clog2(K*N);
parameter WIDTH_FM_ADDR     = $clog2(M*K);
parameter WIDTH_RESULT_ADDR = $clog2(M*N);
parameter WIDTH_TILE        = 1         ;

// matrix_multiplier Inputs
reg                      clk      = 0;
reg                      rst_n    = 0;
reg                      start    = 0;
reg  [`WIDTH_DATA-1:0]   w_in     = 0;
reg  [WIDTH_W_ADDR-1:0]  w_addr   = 0;
reg                      w_en     = 0;
reg  [`WIDTH_DATA-1:0]   fm_in    = 0;
reg  [WIDTH_FM_ADDR-1:0] fm_addr  = 0;
reg                      fm_en    = 0;
reg  [WIDTH_TILE-1:0]    tile_num = 1;

// matrix_multiplier Outputs
wire   signed[`WIDTH_DATA*2-1:0]                 matrix_out      ;
reg   [WIDTH_RESULT_ADDR-1:0]                 matrix_raddr    ;
wire                    result_valid    ;
wire                    acc_result_valid;

// matrix_multiplier Bidirs

initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

matrix_multiplier #(
    .M                (M                ),
    .K                (K                ),
    .N                (N                ),
    .WIDTH_W_ADDR     (WIDTH_W_ADDR     ),
    .WIDTH_FM_ADDR    (WIDTH_FM_ADDR    ),
    .WIDTH_RESULT_ADDR(WIDTH_RESULT_ADDR),
    .WIDTH_TILE       (WIDTH_TILE       )
) u_matrix_multiplier (
    .clk             (clk             ),
    .rst_n           (rst_n           ),
    .start           (start           ),
    .w_in            (w_in            ),
    .w_addr          (w_addr          ),
    .w_en            (w_en            ),
    .fm_in           (fm_in           ),
    .fm_addr         (fm_addr         ),
    .fm_en           (fm_en           ),
    .tile_num        (tile_num        ),

    .matrix_out      (matrix_out      ),
    .matrix_raddr    (matrix_raddr    ),
    .result_valid    (result_valid    ),
    .acc_result_valid(acc_result_valid)
);

initial
begin
    #10000000;
    $finish;
end


// load weight and feature map and start
//I(M*K)*W(K*N) = O(M*N),I:feature map,W:weight(kernel),O:output matrix
reg signed[`WIDTH_DATA-1:0]  fm[0:M-1][0:K-1],w[0:K-1][0:N-1];
integer m,k,n;
initial begin
    @(posedge rst_n);
    fm_en = 1;
    for (m=0;m<M ;m=m+1 ) begin
        for (k =0 ;k<K ;k=k+1 ) begin
    
            fm_addr =m*K+k ;
            fm_in = $random%10;
            fm[m][k] = fm_in;
            @(posedge clk);
        end
    end
    fm_en = 0;
    w_en = 1;
    for (k = 0;k<K ;k=k+1 ) begin
        for (n = 0;n<N ;n=n+1 ) begin
            w_addr = k*N+n;
            w_in = $random%10;
            w[k][n] = w_in;
            @(posedge clk);
        end
    end
    w_en = 0;

    
    start = 1;@(posedge clk);start=0;
end
//monitor result
integer result_row,result_col,acc_index;
reg signed[`WIDTH_DATA*2-1:0]  matrix[0:M-1][0:N-1],expected[0:M-1][0:N-1];
reg recieve_result=0;
reg signed [`WIDTH_DATA*2-1:0]matrix_out_reg;
initial begin
    for (result_row =0 ;result_row < M ;result_row=result_row+1 ) begin
            for (result_col = 0;result_col<N ;result_col=result_col+1 ) begin
                    matrix[result_row][result_col] = 'd0;
                    expected[result_row][result_col] = 'd0;
                    end
                    
                end
    matrix_raddr = 0;
    forever begin
        @(posedge clk);

        if(result_valid)
            recieve_result <= 1;
        if(recieve_result)begin
            for (result_row =0 ;result_row < M ;result_row=result_row+1 ) begin
                for (result_col = 0;result_col<N ;result_col=result_col+1 ) begin 
                    matrix_raddr <= matrix_raddr + 1;       
                    @(posedge clk);
                    matrix[result_row][result_col] <= matrix_out;
                    for (acc_index = 0;acc_index < K ;acc_index = acc_index + 1 ) begin
                        expected[result_row][result_col] = expected[result_row][result_col] + fm[result_row][acc_index]*w[acc_index][result_col];
                    end
                    
                end
            end
        end
        recieve_result = 0;
    end
end
endmodule