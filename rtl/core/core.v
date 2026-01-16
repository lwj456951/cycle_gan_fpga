/***
 * @Author: jia200151@126.com
 * @Date: 2025-12-29 16:58:21
 * @LastEditors: lwj
 * @LastEditTime: 2025-12-31 16:50:00
 * @FilePath: \core\core.v
 * @Description:
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
module core#(parameter DATA_MEM_ADDR_BITS = 8,
             parameter DATA_MEM_DATA_BITS = 8,
             parameter PROGRAM_MEM_ADDR_BITS = 8,
             parameter PROGRAM_MEM_DATA_BITS = 16,
             parameter Vector_Size = 4)
            (input wire clk,
             input wire reset,
             input wire start,
             output wire done,
             input wire enable,
             input wire [7:0] core_id,
             input wire [7:0] engine_id,
             input wire [7:0] task_id,
             output wire program_mem_read_valid,
             output wire [PROGRAM_MEM_ADDR_BITS-1:0] program_mem_read_address,
             input wire program_mem_read_ready,
             input wire [PROGRAM_MEM_DATA_BITS-1:0] program_mem_read_data,
             output wire data_mem_read_valid,
             output wire [DATA_MEM_ADDR_BITS-1:0] data_mem_read_address,
             input wire data_mem_read_ready,
             input wire [DATA_MEM_DATA_BITS-1:0] data_mem_read_data,
             output wire data_mem_write_valid,
             output wire [DATA_MEM_ADDR_BITS-1:0] data_mem_write_address,
             output wire [DATA_MEM_DATA_BITS-1:0] data_mem_write_data,
             input wire data_mem_write_ready,
             // registers
             output wire [DATA_MEM_DATA_BITS*16-1:0] registers_out,
             output wire [DATA_MEM_DATA_BITS*Vector_Size*16-1:0] v_registers_out);
    
    
    // core_controller Inputs
    wire  [2:0] fetcher_state;
    wire  [2:0] lsu_state    ;
    wire  [7:0] next_pc      ;
    
    // core_controller Outputs
    wire [7:0]     current_pc;
    wire [2:0]     core_state;
    //fetcher Outputs
    wire [PROGRAM_MEM_DATA_BITS-1:0]                           instruction     ;
    // decoder Outputs
    wire [3:0]     decoded_rd_address        ;
    wire [3:0]     decoded_rs_address        ;
    wire [3:0]     decoded_rt_address        ;
    wire [2:0]     decoded_nzp               ;
    wire [7:0]     decoded_immediate         ;
    wire      decoded_reg_write_enable  ;
    wire      decoded_mem_read_enable   ;
    wire      decoded_mem_write_enable  ;
    wire      decoded_nzp_write_enable  ;
    wire [1:0]     decoded_reg_input_mux     ;
    wire [1:0]     decoded_alu_arithmetic_mux;
    wire      decoded_alu_output_mux    ;
    wire      decoded_pc_mux            ;
    wire      decoded_vector_mux        ;
    wire      decoded_ret              ;      //ret means return
    // lsu Inputs
    wire  [7:0] rs                       ;//address
    wire  [7:0] rt                       ;//write data
    
    // lsu Outputs
    wire [DATA_MEM_DATA_BITS-1:0]     lsu_out          ;//read data
    wire [DATA_MEM_DATA_BITS*Vector_Size-1:0]       v_lsu_out       ;//read vector data
    
    // ALU Inputs
    wire  [DATA_MEM_DATA_BITS*Vector_Size-1:0] v_rs                       ;
    wire  [DATA_MEM_DATA_BITS*Vector_Size-1:0] v_rt                       ;
    
    // ALU Outputs
    wire   [DATA_MEM_DATA_BITS-1:0]                 alu_out  ;
    wire   [DATA_MEM_DATA_BITS*Vector_Size-1:0]                 v_alu_out;
    
    
    
    core_controller  u_core_controller (
    .clk          (clk),
    .reset        (reset),
    .start        (start),
    .decoded_ret  (decoded_ret),
    .fetcher_state(fetcher_state),
    .lsu_state    (lsu_state),
    .next_pc      (next_pc),
    
    .current_pc   (current_pc),
    .core_state   (core_state),
    .done         (done)
    );
    
    fetcher #(
    .PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
    .PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS)
    ) u_fetcher (
    .clk             (clk),
    .reset           (reset),
    .core_state      (core_state),
    .current_pc      (current_pc),
    .mem_read_ready  (program_mem_read_ready),
    .mem_read_data   (program_mem_read_data),
    
    .mem_read_valid  (program_mem_read_valid),
    .mem_read_address(program_mem_read_address),
    .fetcher_state   (fetcher_state),
    .instruction     (instruction)
    );
    
    decoder #(
    .PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS)
    ) u_decoder (
    .clk                       (clk),
    .reset                     (reset),
    .core_state                (core_state),
    .instruction               (instruction),
    
    .decoded_rd_address        (decoded_rd_address),
    .decoded_rs_address        (decoded_rs_address),
    .decoded_rt_address        (decoded_rt_address),
    .decoded_nzp               (decoded_nzp),
    .decoded_immediate         (decoded_immediate),
    .decoded_reg_write_enable  (decoded_reg_write_enable),
    .decoded_mem_read_enable   (decoded_mem_read_enable),
    .decoded_mem_write_enable  (decoded_mem_write_enable),
    .decoded_nzp_write_enable  (decoded_nzp_write_enable),
    .decoded_reg_input_mux     (decoded_reg_input_mux),
    .decoded_alu_arithmetic_mux(decoded_alu_arithmetic_mux),
    .decoded_alu_output_mux    (decoded_alu_output_mux),
    .decoded_pc_mux            (decoded_pc_mux),
    .decoded_vector_mux        (decoded_vector_mux),
    .decoded_ret               (decoded_ret)
    );
    
    
    lsu #(
    .Vector_Size(Vector_Size),
    .DATA_BITS  (DATA_MEM_DATA_BITS)
    ) u_lsu (
    .clk                     (clk),
    .reset                   (reset),
    .enable                  (enable),
    .core_state              (core_state),
    .decoded_mem_read_enable (decoded_mem_read_enable),
    .decoded_mem_write_enable(decoded_mem_write_enable),
    .decoded_vector_mux      (decoded_vector_mux),
    .rs                      (rs),
    .rt                      (rt),
    .v_rs                    (v_rs),
    .v_rt                    (v_rt),
    .mem_read_ready          (data_mem_read_ready),
    .mem_read_data           (data_mem_read_data),
    .mem_write_ready         (data_mem_write_ready),
    
    .mem_read_valid          (data_mem_read_valid),
    .mem_read_address        (data_mem_read_address),
    .mem_write_valid         (data_mem_write_valid),
    .mem_write_address       (data_mem_write_address),
    .mem_write_data          (data_mem_write_data),
    .lsu_state               (lsu_state),
    .lsu_out                 (lsu_out),
    .v_lsu_out               (v_lsu_out)
    );
    
    ALU #(
    .Vector_Size(Vector_Size)
    ) u_ALU (
    .clk                       (clk),
    .reset                     (reset),
    .enable                    (enable),
    .core_state                (core_state),
    .decoded_alu_arithmetic_mux(decoded_alu_arithmetic_mux),
    .decoded_alu_output_mux    (decoded_alu_output_mux),
    .decoded_alu_vector_mux    (decoded_vector_mux),
    .rs                        (rs),
    .rt                        (rt),
    .v_rs                      (v_rs),
    .v_rt                      (v_rt),
    
    .alu_out                   (alu_out),
    .v_alu_out                 (v_alu_out)
    );
    
    PC  u_PC (
    .clk                     (clk),
    .reset                   (reset),
    .enable                  (enable),
    .core_state              (core_state),
    .decoded_nzp             (decoded_nzp),
    .decoded_immediate       (decoded_immediate),
    .decoded_nzp_write_enable(decoded_nzp_write_enable),
    .decoded_pc_mux          (decoded_pc_mux),
    .alu_out                 (alu_out),
    .current_pc              (current_pc),
    
    .next_pc                 (next_pc)
    );
    

// register Bidirs

    register #(
    .DATA_BITS  (DATA_MEM_DATA_BITS  ),
    .Vector_Size(Vector_Size)
    ) u_register (
    .clk                     (clk                     ),
    .reset                   (reset                   ),
    .enable                  (enable                  ),
    .core_id                 (core_id                 ),
    .engine_id               (engine_id               ),
    .task_id                 (task_id                 ),
    .core_state              (core_state              ),
    .decoded_rd_address      (decoded_rd_address      ),
    .decoded_rs_address      (decoded_rs_address      ),
    .decoded_rt_address      (decoded_rt_address      ),
    .decoded_reg_write_enable(decoded_reg_write_enable),
    .decoded_reg_input_mux   (decoded_reg_input_mux   ),
    .decoded_immediate       (decoded_immediate       ),
    .decoded_vector_mux      (decoded_vector_mux      ),
    .alu_out                 (alu_out                 ),
    .lsu_out                 (lsu_out                 ),
    .v_alu_out               (v_alu_out               ),
    .v_lsu_out               (v_lsu_out               ),

    .rs                      (rs                      ),
    .rt                      (rt                      ),
    .v_rs                    (v_rs                    ),
    .v_rt                    (v_rt                    ),
    .registers_out           (registers_out           ),
    .v_registers_out         (v_registers_out         )
);
endmodule
