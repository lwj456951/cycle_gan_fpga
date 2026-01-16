/***
 * @Author: jia200151@126.com
 * @Date: 2025-12-29 16:21:42
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-04 20:17:12
 * @FilePath: \core\register.v
 * @Description:
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */

module register#(parameter DATA_BITS = 8,
                 parameter Vector_Size = 4)
                (input wire clk,
                 input wire reset,
                 input wire enable,                               // If current block has less threads then block size, some registers will be inactive
                 input reg [7:0] core_id,
                 input reg [7:0] engine_id,
                 input reg [7:0] task_id,
                 input reg [2:0] core_state,
                 input reg [3:0] decoded_rd_address,
                 input reg [3:0] decoded_rs_address,
                 input reg [3:0] decoded_rt_address,
                 input reg decoded_reg_write_enable,
                 input reg [1:0] decoded_reg_input_mux,
                 input reg [DATA_BITS-1:0] decoded_immediate,
                 input reg decoded_vector_mux,
                 input reg [DATA_BITS-1:0] alu_out,
                 input reg [DATA_BITS-1:0] lsu_out,
                 input reg [Vector_Size*DATA_BITS-1:0] v_alu_out,
                 input reg [Vector_Size*DATA_BITS-1:0] v_lsu_out,
                 output reg [7:0] rs,
                 output reg [7:0] rt,
                 output reg [8*Vector_Size-1:0] v_rs,
                 output reg [8*Vector_Size-1:0] v_rt,
                 output reg [DATA_BITS*16-1:0] registers_out,
                 output reg [DATA_BITS*Vector_Size*16-1:0] v_registers_out
                 );
    localparam ARITHMETIC = 2'b00,
    MEMORY = 2'b01,
    CONSTANT = 2'b10;
    
    // 16 registers per thread (13 free registers and 3 read-only registers)
    reg [DATA_BITS-1:0] registers[0:15];
    reg [DATA_BITS*Vector_Size-1:0] v_registers[0:15];
    integer vreg_i;
    integer reg_i;
    always @(*) begin
        for (reg_i = 0;reg_i<16 ;reg_i=reg_i+1 ) begin
                v_registers_out[reg_i*DATA_BITS+:DATA_BITS] <= v_registers[reg_i];
                registers_out[reg_i*DATA_BITS*Vector_Size+:DATA_BITS] <= registers[reg_i];
            end
    end
    always @(posedge clk) begin
        if (reset) begin
            // Empty rs, rt
            rs   <= 0;
            rt   <= 0;
            v_rs <= 0;
            v_rt <= 0;
            // Initialize all free registers
            registers[0]  <= 8'b0;
            registers[1]  <= 8'b0;
            registers[2]  <= 8'b0;
            registers[3]  <= 8'b0;
            registers[4]  <= 8'b0;
            registers[5]  <= 8'b0;
            registers[6]  <= 8'b0;
            registers[7]  <= 8'b0;
            registers[8]  <= 8'b0;
            registers[9]  <= 8'b0;
            registers[10] <= 8'b0;
            registers[11] <= 8'b0;
            registers[12] <= 8'b0;
            // Initialize read-only registers
            registers[13] <= core_id;           //core id
            registers[14] <= engine_id;          // engine id
            registers[15] <= task_id;         // task id
            for (vreg_i = 0;vreg_i<16 ;vreg_i=vreg_i+1 ) begin
                v_registers[vreg_i] <= 0;
            end
            end else if (enable) begin
            
            // Fill rs/rt when core_state = REQUEST
            if (core_state == 3'b011) begin
                if (decoded_vector_mux)begin
                    v_rs <= v_registers[decoded_rs_address];
                    v_rt <= v_registers[decoded_rt_address];
                end
                else begin
                    rs <= registers[decoded_rs_address];
                    rt <= registers[decoded_rt_address];
                end
                
            end
            
            // Store rd when core_state = UPDATE
            if (core_state == 3'b110) begin
                // Only allow writing to R0 - R12
                if (decoded_reg_write_enable && decoded_rd_address < 13) begin
                    if (decoded_vector_mux)begin
                        case (decoded_reg_input_mux)
                            ARITHMETIC: begin
                                // ADD, SUB, MUL, DIV
                                v_registers[decoded_rd_address] <= v_alu_out;
                            end
                        endcase
                    end
                    else begin
                        case (decoded_reg_input_mux)
                            ARITHMETIC: begin
                                // ADD, SUB, MUL, DIV
                                registers[decoded_rd_address] <= alu_out;
                            end
                            MEMORY: begin
                                // LDR
                                registers[decoded_rd_address] <= lsu_out;
                            end
                            CONSTANT: begin
                                // CONST
                                registers[decoded_rd_address] <= decoded_immediate;
                            end
                        endcase
                    end
                    
                end
            end
        end
    end
    
    
endmodule
