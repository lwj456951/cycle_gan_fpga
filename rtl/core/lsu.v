/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-12-28 12:58:36
 * @LastEditors: lwj
 * @LastEditTime: 2025-12-31 16:40:59
 * @FilePath: \core\lsu.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
module lsu#(
    parameter   Vector_Size = 4,
    parameter   DATA_BITS = 8
)(
    input wire clk,
    input wire reset,
    input wire enable, // If current block has less threads then block size, some LSUs will be inactive

    // State
    input reg [2:0] core_state,

    // Memory Control Sgiansl
    input reg decoded_mem_read_enable,
    input reg decoded_mem_write_enable,
    input reg decoded_vector_mux,
    // Registers
    input reg [7:0] rs,
    input reg [7:0] rt,
    input reg [8*Vector_Size-1:0] v_rs,
    input reg [8*Vector_Size-1:0] v_rt,

    // Data Memory
    output reg mem_read_valid,
    output reg [7:0] mem_read_address,
    input reg mem_read_ready,
    input reg [7:0] mem_read_data,
    output reg mem_write_valid,
    output reg [7:0] mem_write_address,
    output reg [7:0] mem_write_data,
    input reg mem_write_ready,
    
    // LSU Outputs
    output reg [2:0] lsu_state,
    output reg [7:0] lsu_out,
    output reg [Vector_Size*DATA_BITS-1:0] v_lsu_out
);
    reg [$clog2(Vector_Size):0] addr_pointer;
  localparam IDLE = 3'b00, REQUESTING = 3'b01, WAITING = 3'b10, ADDR_ADD = 3'b11,DONE = 3'b100;
   always @(posedge clk) begin
        if (reset) begin
            lsu_state <= IDLE;
            lsu_out <= 0;
            mem_read_valid <= 0;
            mem_read_address <= 0;
            mem_write_valid <= 0;
            mem_write_address <= 0;
            mem_write_data <= 0;
            addr_pointer <= 0;
        end else if (enable) begin
            if(decoded_vector_mux)begin//读vector size 次的数据填满vector register，状态机加一个地址自增即可
                case (lsu_state)
                        IDLE: begin
                            // Only read when core_state = REQUEST
                            if (core_state == 3'b011) begin 
                                lsu_state <= REQUESTING;
                                addr_pointer <= 0;
                            end
                        end
                        REQUESTING: begin 
                            if (decoded_mem_read_enable)begin
                                mem_read_valid <= 1;
                                mem_read_address <= v_rs[addr_pointer*8+:8];
                                lsu_state <= WAITING;
                            end
                            if (decoded_mem_write_enable)begin
                                mem_write_valid <= 1;
                                mem_write_address <= v_rs[addr_pointer*8+:8];
                                mem_write_data <= v_rt[addr_pointer*8+:8];
                                lsu_state <= WAITING;
                            end
                        end
                        WAITING: begin
                            if (mem_read_ready == 1) begin
                                mem_read_valid <= 0;
                                v_lsu_out[addr_pointer*8+:8] <= mem_read_data;
                                lsu_state <= ADDR_ADD;
                            end
                            if (mem_write_ready) begin
                                mem_write_valid <= 0;
                                lsu_state <= DONE;
                            end
                        end
                        ADDR_ADD: begin
                            if(addr_pointer == 3)begin
                                lsu_state <= DONE;
                            end
                            else begin
                                addr_pointer <= addr_pointer + 1;
                                lsu_state <= REQUESTING;
                            end

                        end
                        DONE: begin 
                            // Reset when core_state = UPDATE
                            if (core_state == 3'b110) begin 
                                lsu_state <= IDLE;
                            end
                        end
                    endcase
            end
            else begin
                // If memory read enable is triggered (LDR instruction)
                if (decoded_mem_read_enable) begin 
                    case (lsu_state)
                        IDLE: begin
                            // Only read when core_state = REQUEST
                            if (core_state == 3'b011) begin 
                                lsu_state <= REQUESTING;
                            end
                        end
                        REQUESTING: begin 
                            mem_read_valid <= 1;
                            mem_read_address <= rs;
                            lsu_state <= WAITING;
                        end
                        WAITING: begin
                            if (mem_read_ready == 1) begin
                                mem_read_valid <= 0;
                                lsu_out <= mem_read_data;
                                lsu_state <= DONE;
                            end
                            
                        end
                        DONE: begin 
                            // Reset when core_state = UPDATE
                            if (core_state == 3'b110) begin 
                                lsu_state <= IDLE;
                            end
                        end
                    endcase
                end

                // If memory write enable is triggered (STR instruction)
                if (decoded_mem_write_enable) begin 
                    case (lsu_state)
                        IDLE: begin
                            // Only read when core_state = REQUEST
                            if (core_state == 3'b011) begin 
                                lsu_state <= REQUESTING;
                            end
                        end
                        REQUESTING: begin 
                            mem_write_valid <= 1;
                            mem_write_address <= rs;
                            mem_write_data <= rt;
                            lsu_state <= WAITING;
                        end
                        WAITING: begin
                            if (mem_write_ready) begin
                                mem_write_valid <= 0;
                                lsu_state <= DONE;
                            end
                        end
                        DONE: begin 
                            // Reset when core_state = UPDATE
                            if (core_state == 3'b110) begin 
                                lsu_state <= IDLE;
                            end
                        end
                    endcase
                end
            end
            
        end
    end  
    
endmodule