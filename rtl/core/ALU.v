/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-12-29 14:31:33
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-09 10:58:12
 * @FilePath: \core\ALU.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
 
module ALU#(
    parameter Vector_Size = 4
)
 (
    input wire clk,
    input wire reset,
    input wire enable, // If current block has less threads then block size, some ALUs will be inactive

    input reg [2:0] core_state,

    input reg [1:0] decoded_alu_arithmetic_mux,
    input reg decoded_alu_output_mux,
    input reg decoded_alu_vector_mux,

    input reg [7:0] rs,
    input reg [7:0] rt,
    input reg [8*Vector_Size-1:0] v_rs,
    input reg [8*Vector_Size-1:0] v_rt,
    output wire [7:0] alu_out,
    output wire [8*Vector_Size-1:0] v_alu_out
);
    localparam ADD = 2'b00,
        SUB = 2'b01,
        MUL = 2'b10,
        DIV = 2'b11;

    reg [7:0] alu_out_reg;
    assign alu_out = alu_out_reg;

    reg [8*Vector_Size-1:0] v_alu_out_reg;
    assign v_alu_out = v_alu_out_reg;

    reg [$clog2(Vector_Size):0] vector_i;
    always @(posedge clk) begin 
        if (reset) begin 
            alu_out_reg <= 8'b0;
            v_alu_out_reg <= 'd0;
        end else if (enable) begin
            // Calculate alu_out when core_state = EXECUTE
            if (core_state == 3'b101) begin 
                if (decoded_alu_output_mux == 1) begin 
                    // Set values to compare with NZP register in alu_out[2:0]
                    alu_out_reg <= {5'b0, (rs - rt < 0), (rs - rt == 0), (rs - rt > 0)};
                end
                else if(decoded_alu_vector_mux) begin
                    for(vector_i = 0;vector_i < Vector_Size;vector_i = vector_i + 1) begin
                        // Execute the specified arithmetic instruction
                        case (decoded_alu_arithmetic_mux)
                            ADD: begin 
                                v_alu_out_reg[vector_i*8+:8] <= rs[vector_i*8+:8] + rt[vector_i*8+:8];
                            end
                            SUB: begin 
                                v_alu_out_reg[vector_i*8+:8] <= rs[vector_i*8+:8] - rt[vector_i*8+:8];
                            end
                            MUL: begin 
                                v_alu_out_reg[vector_i*8+:8] <= rs[vector_i*8+:8] * rt[vector_i*8+:8];
                            end
                            DIV: begin 
                                v_alu_out_reg[vector_i*8+:8] <= rs[vector_i*8+:8] / rt[vector_i*8+:8];
                            end
                        endcase
                    end
                    
                end
                else begin 
                    // Execute the specified arithmetic instruction
                    case (decoded_alu_arithmetic_mux)
                        ADD: begin 
                            alu_out_reg <= rs + rt;
                        end
                        SUB: begin 
                            alu_out_reg <= rs - rt;
                        end
                        MUL: begin 
                            alu_out_reg <= rs * rt;
                        end
                        DIV: begin 
                            alu_out_reg <= rs / rt;
                        end
                    endcase
                end
            end
        end
    end
endmodule