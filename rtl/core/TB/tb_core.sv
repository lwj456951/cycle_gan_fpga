/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-12-31 16:51:02
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-16 15:54:58
 * @FilePath: \core\TB\tb_core.sv
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */

//~ `New testbench
`timescale  1ns / 1ps
`include "testbench.sv"

module tb_core;

// core Parameters
parameter PERIOD = 10;
parameter DATA_MEM_ADDR_BITS    = 8 ;
parameter DATA_MEM_DATA_BITS    = 8 ;
parameter PROGRAM_MEM_ADDR_BITS = 8 ;
parameter PROGRAM_MEM_DATA_BITS = 32;
parameter Vector_Size           = 4 ;

// core Inputs
reg                              clk                    = 0;
reg                              reset                  = 0;
reg                              start                  = 0;
reg                              enable                 = 0;
reg  [7:0]                       core_id                = 0;
reg  [7:0]                       engine_id              = 0;
reg  [7:0]                       task_id                = 0;
reg                              program_mem_read_ready = 0;
reg  [PROGRAM_MEM_DATA_BITS-1:0] program_mem_read_data  = 0;
reg                              data_mem_read_ready    = 0;
reg  [DATA_MEM_DATA_BITS-1:0]    data_mem_read_data     = 0;
reg                              data_mem_write_ready   = 0;


// core Outputs
wire                                                    done                    ;
wire                                                    program_mem_read_valid  ;
wire  [PROGRAM_MEM_ADDR_BITS-1:0]                       program_mem_read_address;
wire                                                    data_mem_read_valid     ;
wire  [DATA_MEM_ADDR_BITS-1:0]                          data_mem_read_address   ;
wire                                                    data_mem_write_valid    ;
wire  [DATA_MEM_ADDR_BITS-1:0]                          data_mem_write_address  ;
wire  [DATA_MEM_DATA_BITS-1:0]                          data_mem_write_data     ;
wire[DATA_MEM_DATA_BITS*16-1:0]                         registers_out           ;
wire[DATA_MEM_DATA_BITS*Vector_Size*16-1:0]             v_registers_out         ;
/************** testbench*********************/
core_if intf(clk,reset);
test t1(intf);
/************** testbench*********************/


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) reset  =  1;
    #(PERIOD*2) reset  =  0;
end

core #(
    .DATA_MEM_ADDR_BITS   (DATA_MEM_ADDR_BITS   ),
    .DATA_MEM_DATA_BITS   (DATA_MEM_DATA_BITS   ),
    .PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
    .PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS),
    .Vector_Size          (Vector_Size          )
) u_core (
    .clk                     (intf.clk                     ),
    .reset                   (intf.reset                   ),
    .start                   (intf.start                   ),
    .enable                  (intf.enable                  ),
    .core_id                 (intf.core_id                 ),
    .engine_id               (intf.engine_id               ),
    .task_id                 (intf.task_id                 ),
    .program_mem_read_ready  (intf.program_mem_read_ready  ),
    .program_mem_read_data   (intf.program_mem_read_data   ),
    .data_mem_read_ready     (intf.data_mem_read_ready     ),
    .data_mem_read_data      (intf.data_mem_read_data      ),
    .data_mem_write_ready    (intf.data_mem_write_ready    ),

    .done                    (intf.done                    ),
    .program_mem_read_valid  (intf.program_mem_read_valid  ),
    .program_mem_read_address(intf.program_mem_read_address),
    .data_mem_read_valid     (intf.data_mem_read_valid     ),
    .data_mem_read_address   (intf.data_mem_read_address   ),
    .data_mem_write_valid    (intf.data_mem_write_valid    ),
    .data_mem_write_address  (intf.data_mem_write_address  ),
    .data_mem_write_data     (intf.data_mem_write_data     ),
    .registers_out           (intf.registers_out          ),
    .v_registers_out         (intf.v_registers_out         )
);

initial
begin
    $dumpfile("dump.vcd"); $dumpvars;
end

endmodule