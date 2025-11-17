/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-05 11:03:03
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-17 13:21:36
 * @FilePath: \rtl\matrix_multiplier\matrix_multiplier.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`include"./define.v"
//weight fixed
module matrix_multiplier #(
    parameter M = 16'd4,
    parameter K = 16'd3,//k:kernel_size K*N
    parameter N = 16'd3,
    parameter WIDTH_W_ADDR = $clog2(K*N),
    parameter WIDTH_FM_ADDR = $clog2(M*K),
    parameter WIDTH_RESULT_ADDR = $clog2(M*N),
    parameter WIDTH_TILE = 4//16*12=4*(4*3)
)(
    input clk,
    input rst_n,
    input start,
    //w:weight
    input signed[`WIDTH_DATA-1:0] w_in,
    input [WIDTH_W_ADDR-1:0] w_addr,
    input w_en,
    //feature map
    input signed[`WIDTH_DATA-1:0] fm_in,
    input [WIDTH_FM_ADDR-1:0] fm_addr,
    input fm_en,
    //I(M*K)*W(K*N) = O(M*N),I:feature map,W:weight(kernel),O:output matrix
    input[WIDTH_TILE-1:0] tile_num,
    output reg signed[`WIDTH_DATA*2-1:0] matrix_out,
    input[WIDTH_RESULT_ADDR-1:0] matrix_raddr,
    output reg result_valid,//one splited matrix_mult result
    output reg acc_result_valid//accumulated result 
);

reg signed[`WIDTH_DATA -1:0] w_ram[0:K*N-1];
reg signed[`WIDTH_DATA -1:0] fm_ram[0:M*K-1];   
reg signed[`WIDTH_DATA*2 -1:0] result_ram[0:M*N-1];
//read data(column channals) 
reg[`WIDTH_DATA -1:0] w_rd[0:N-1];//N column
reg[$clog2(K):0] w_row;//weight row counter

reg[`WIDTH_DATA -1:0] fm_rd[0:K-1];//K column
reg[$clog2(M):0] fm_row;//feature map row counter
//delay data
wire[`WIDTH_DATA -1:0] w_delay[0:N-1];//N column
wire[`WIDTH_DATA -1:0] fm_delay[0:K-1];//K column
//cnt
reg[WIDTH_TILE-1:0] tile_cnt;//max count==tile_num
reg[$clog2(M+N+K+2):0] delay_cnt;//after PE array finish computing(N+K delay),store the result(first tile) or accumulate the result(the rest tile)(M delay);
reg[$clog2(M):0] result_row_cnt;//M rows
//clear
wire clear;
assign clear = start || result_valid;
//state machine
localparam idle = 3'd0,load_w=3'd1,load_fm=3'd2,update_result=3'd3;
reg[2:0] c_state,n_state;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        c_state <= idle;
    else
        c_state <= n_state;
end
always @(*) begin
    case (c_state)
        idle:begin
            n_state <= start?load_w:idle;
        end
        load_w:begin
            n_state <= (w_row >= K)?load_fm:load_w;
        end
        load_fm:begin
            n_state <= (delay_cnt>=M+N)?update_result:load_fm;
        end
        update_result: begin
            n_state <= (result_row_cnt == M)?idle:update_result;
        end
        default: n_state<=idle;
    endcase
end
integer i,j;
//weight and feature map memory
//write
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        for(i=0;i<K*N;i=i+1)begin
            w_ram[i] <= 'd0;
        end
        for(j=0;j<M*K;j=j+1)begin
            fm_ram[j] <= 'd0;
        end
    end
    else begin
        if(w_en)
            w_ram[w_addr] <= w_in; 
        if(fm_en)  
            fm_ram[fm_addr] <= fm_in;
    end
end
//read row cnt
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        w_row <= 'd0;
        fm_row <= 'd0;
    end
    else begin
        if(result_valid)//K rows 
            w_row <= 'd0;
        else if(start)
            w_row <= 'd1;
        else if(w_row > 0 && w_row < K)
            w_row <= w_row+1;

        if(result_valid) //M rows 
            fm_row <= 'd0;
        else if(c_state==load_w && n_state==load_fm)//Load feature map after load a whole column weight
            fm_row <= 'd1;
        else if(fm_row > 0 && fm_row < M)
            fm_row <= fm_row+1;
    end
end
//read data
//row first
integer w_column;
always @(posedge clk or negedge rst_n) begin
    for(w_column=0;w_column<N;w_column=w_column+1)begin
        if(~rst_n)
            w_rd[w_column] <= 'd0;
        else begin
            
            if(n_state!=idle&&w_row < K)
                w_rd[w_column] <= w_ram[w_row*N+w_column];
            else
                w_rd[w_column] <= 'd0;
        end
    end
end
integer fm_column;
always @(posedge clk or negedge rst_n) begin
    for(fm_column=0;fm_column<N;fm_column=fm_column+1)begin
        if(~rst_n)
            fm_rd[fm_column] <= 'd0;
        else begin
            if(n_state==load_fm&&fm_row<M)
                fm_rd[fm_column] <= fm_ram[fm_row*N+fm_column];
            else
                fm_rd[fm_column] <= 'd0;
        end
    end
end
//delay buffer
genvar w_ptr,fm_ptr;
generate
    for(w_ptr=0;w_ptr<N;w_ptr=w_ptr+1)begin:wbuffer_gen
        buffer #(
            .WIDTH (`WIDTH_DATA),
            .LENGTH(w_ptr+1)//1~N,w_ptr point to 1~N th column
        ) u_buffer (
            .clk  (clk  ),
            .rst_n(rst_n),
            .clear(clear),
            .din  (w_rd[w_ptr]),

            .dout (w_delay[w_ptr] )
        );
    end
    for(fm_ptr=0;fm_ptr<K;fm_ptr=fm_ptr+1)begin
        buffer #(
            .WIDTH (`WIDTH_DATA),
            .LENGTH(K-fm_ptr)//1~K,fm_ptr point to 1~K th column
        ) u_buffer (
            .clk  (clk  ),
            .rst_n(rst_n),
            .clear(clear),
            .din  (fm_rd[fm_ptr]  ),

            .dout (fm_delay[fm_ptr] )
        );
    end
endgenerate

// compute 2d PE(K*N)
genvar  PE_ROW,PE_COL;
wire[`WIDTH_DATA -1:0] w_out_reg[0:K-1][0:N-1];
wire[`WIDTH_DATA -1:0] fm_out_reg[0:K-1][0:N-1];
wire[`WIDTH_DATA*2 -1:0] psum_out_reg[0:K-1][0:N-1];
wire[`WIDTH_DATA -1:0] w_reg[0:K-1][0:N-1];
reg load_en[0:N-1];//weight column load en

//shift_en
wire shift_en_out_reg[0:K-1][0:N-1];
reg shift_en;
wire shift_en_delay;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_en <= 0;
    end
    else begin
        if(c_state==load_w && n_state==load_fm)
            shift_en <= 1;
        if(shift_en)
            shift_en <= 0;
    end
end
//load en
//shut down load_en after the column has totally load
integer load_i;
always @(posedge clk or negedge rst_n) begin
    for (load_i =0 ;load_i<N ;load_i=load_i+1 ) begin
        if(~rst_n)begin
            load_en[load_i] <= 1'b1;
        end
        else begin
            if(result_valid)begin
                load_en[load_i] <= 'b1;
            end
            else begin
                if(load_i==0)
                    load_en[load_i] <= shift_en?1'b0:load_en[load_i];
                else if(load_i==1)
                    load_en[load_i] <= shift_en_delay?1'b0:load_en[load_i];
                else
                    load_en[load_i] <= shift_en_out_reg[0][load_i-2]?1'b0:load_en[load_i];
            end
            
        end
    end
end
buffer #(
    .WIDTH (1 ),
    .LENGTH(1)
) u_buffer (
    .clk  (clk  ),
    .rst_n(rst_n),
    .clear(clear),
    .din  (shift_en  ),

    .dout (shift_en_delay )
);

//PE array
generate
    for(PE_ROW=0;PE_ROW<K;PE_ROW=PE_ROW+1)begin
        for ( PE_COL=0 ;PE_COL<N ;PE_COL=PE_COL+1 ) begin
            if (PE_ROW==0&PE_COL==0) begin
                PE_2d  u_PE_2d (
                    .clk     (clk     ),
                    .rst_n   (rst_n   ),
                    .load_en(load_en[PE_COL]),
                    .shift_en_in(shift_en_delay),
                    .w_in    (w_delay[PE_COL]    ),
                    .fm_in   (fm_delay[K-1-PE_ROW]   ),
                    .psum_in (`WIDTH_DATA*2'd0),

                    .shift_en_out(shift_en_out_reg[PE_ROW][PE_COL]),
                    .w_out   (w_out_reg[PE_ROW][PE_COL]   ),
                    .w_reg(w_reg[PE_ROW][PE_COL]),
                    .fm_out  (fm_out_reg[PE_ROW][PE_COL]  ),
                    .psum_out(psum_out_reg[PE_ROW][PE_COL])
                );
            end
            else if(PE_COL==0)begin
                PE_2d  u_PE_2d (
                    .clk     (clk     ),
                    .rst_n   (rst_n   ),
                    .load_en(load_en[PE_COL]),
                    .shift_en_in(shift_en_out_reg[PE_ROW-1][PE_COL]),
                    .w_in    (w_out_reg[PE_ROW-1][PE_COL]    ),
                    .fm_in   (fm_delay[K-1-PE_ROW]   ),
                    .psum_in (psum_out_reg[PE_ROW-1][PE_COL] ),

                    .shift_en_out(shift_en_out_reg[PE_ROW][PE_COL]),
                    .w_out   (w_out_reg[PE_ROW][PE_COL]   ),
                    .w_reg(w_reg[PE_ROW][PE_COL]),
                    .fm_out  (fm_out_reg[PE_ROW][PE_COL]  ),
                    .psum_out(psum_out_reg[PE_ROW][PE_COL])
                );
            end
            else if(PE_ROW==0)begin
                PE_2d  u_PE_2d (
                    .clk     (clk     ),
                    .rst_n   (rst_n   ),
                    .load_en(load_en[PE_COL]),
                    .shift_en_in(shift_en_out_reg[PE_ROW][PE_COL-1]),
                    .w_in    (w_delay[PE_COL]    ),
                    .fm_in   (fm_out_reg[PE_ROW][PE_COL-1]   ),
                    .psum_in (`WIDTH_DATA*2'd0 ),

                    .shift_en_out(shift_en_out_reg[PE_ROW][PE_COL]),
                    .w_out   (w_out_reg[PE_ROW][PE_COL]   ),
                    .w_reg(w_reg[PE_ROW][PE_COL]),
                    .fm_out  (fm_out_reg[PE_ROW][PE_COL]  ),
                    .psum_out(psum_out_reg[PE_ROW][PE_COL])
                );
            end
            else begin
                PE_2d  u_PE_2d (
                    .clk     (clk     ),
                    .rst_n   (rst_n   ),
                    .load_en(load_en[PE_COL]),
                    .shift_en_in(shift_en_out_reg[PE_ROW-1][PE_COL]||shift_en_out_reg[PE_ROW][PE_COL-1]),
                    .w_in    (w_out_reg[PE_ROW-1][PE_COL]   ),
                    .fm_in   (fm_out_reg[PE_ROW][PE_COL-1]   ),
                    .psum_in (psum_out_reg[PE_ROW-1][PE_COL]),

                    .shift_en_out(shift_en_out_reg[PE_ROW][PE_COL]),
                    .w_out   (w_out_reg[PE_ROW][PE_COL]   ),
                    .w_reg(w_reg[PE_ROW][PE_COL]),
                    .fm_out  (fm_out_reg[PE_ROW][PE_COL]  ),
                    .psum_out(psum_out_reg[PE_ROW][PE_COL])
                );
            end
        end
    end
endgenerate


//result delay buffer 
genvar result_ptr;
wire signed [`WIDTH_DATA*2-1:0] result_delay[0:N-1] ;
generate
    for (result_ptr = 0;result_ptr<N ;result_ptr=result_ptr+1 ) begin
        buffer #(
            .WIDTH (`WIDTH_DATA*2 ),
            .LENGTH(N-result_ptr)
        ) u_buffer (
            .clk  (clk  ),
            .rst_n(rst_n),
            .clear(clear),
            .din  (psum_out_reg[K-1][result_ptr]  ),

            .dout (result_delay[result_ptr] )
        );
    end
endgenerate
//accumulate
//control logic
//w_cnt >= K(A whole column+1 delay) -> delay_cnt++,
//delay cnt >= PE array delay -> result_row_cnt++,(if delay cnt == PE array delay+update delay,-> delay cnt<=0)
//result_row_cnt == result matrix row -> tile_cnt++
//tile_cnt == tile_num -> result valid

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        delay_cnt <= 'd0;
        result_row_cnt <= 'd0;
        tile_cnt <= 'd0;
        result_valid <= 0;
        acc_result_valid <= 0;
    end
    else begin
        //delay_cnt
        if(result_row_cnt == M)//finish result data updating
            delay_cnt <= 'd0;
        else begin
            if(w_row >= K) 
                delay_cnt = delay_cnt + 1;
        end
        //result_row_cnt
        if(result_row_cnt == M)
            result_row_cnt <= 'd0;
        else begin
            if(delay_cnt>=2+N+K+1)
            //2：1 weight delay+1 weight load
            //N+K:PE array delay
            //1： result delay
                result_row_cnt <= result_row_cnt + 1;
        end
        //tile_cnt
        if(tile_cnt == tile_num)begin
            tile_cnt <= 'd0;
        end
        else begin
            if(result_row_cnt == M)begin
                tile_cnt <= tile_cnt + 1; 
                result_valid <= 1;
            end      
        end
        //result_valid
        begin
        if(result_row_cnt == M)
            result_valid <= 1;     
        if(result_valid)
                result_valid <= 0;
        end
        //acc_result_valid
        if(tile_cnt==tile_num)
            acc_result_valid <= 1;
        else
            acc_result_valid <= 0;
    end
end
//accumulate result matrix
integer result_col;
always @(posedge clk or negedge rst_n) begin
    for (result_col = 0;result_col<N ;result_col=result_col+1 ) begin
        if(~rst_n)begin
            result_ram[result_row_cnt*N + result_col] <= 'd0; 
        end
        else begin
            if(delay_cnt>=2+N+K+1 &&delay_cnt<=2+N+K+M+1)begin
                if(tile_cnt == 'd0)
                    result_ram[result_row_cnt*N + result_col] <= result_delay[result_col];
                else if(tile_cnt < tile_num) begin
                    result_ram[result_row_cnt*N + result_col] <= result_delay[result_col] + result_ram[result_row_cnt*N + result_col];
                end
            end

        end
    end
end
integer index_o;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
        for (index_o =0 ;index_o<M*N ;index_o = index_o+1 ) begin
            result_ram[index_o] <= 'd0;      
        end
    else
        matrix_out <= result_ram[matrix_raddr];
end
endmodule