/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-12-31 16:51:02
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-04 15:51:59
 * @FilePath: \core\TB\tb_core.sv
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */

//~ `New testbench
`timescale  1ns / 1ps

module tb_core;

// core Parameters
parameter PERIOD = 10;
parameter DATA_MEM_ADDR_BITS    = 8 ;
parameter DATA_MEM_DATA_BITS    = 8 ;
parameter PROGRAM_MEM_ADDR_BITS = 8 ;
parameter PROGRAM_MEM_DATA_BITS = 16;
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
wire                            done                    ;
wire                            program_mem_read_valid  ;
wire                            program_mem_read_address;
wire                            data_mem_read_valid     ;
wire                            data_mem_read_address   ;
wire                            data_mem_write_valid    ;
wire                            data_mem_write_address  ;
wire                            data_mem_write_data     ;

// core Bidirs

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
    .clk                     (clk                     ),
    .reset                   (reset                   ),
    .start                   (start                   ),
    .enable                  (enable                  ),
    .core_id                 (core_id                 ),
    .engine_id               (engine_id               ),
    .task_id                 (task_id                 ),
    .program_mem_read_ready  (program_mem_read_ready  ),
    .program_mem_read_data   (program_mem_read_data   ),
    .data_mem_read_ready     (data_mem_read_ready     ),
    .data_mem_read_data      (data_mem_read_data      ),
    .data_mem_write_ready    (data_mem_write_ready    ),

    .done                    (done                    ),
    .program_mem_read_valid  (program_mem_read_valid  ),
    .program_mem_read_address(program_mem_read_address),
    .data_mem_read_valid     (data_mem_read_valid     ),
    .data_mem_read_address   (data_mem_read_address   ),
    .data_mem_write_valid    (data_mem_write_valid    ),
    .data_mem_write_address  (data_mem_write_address  ),
    .data_mem_write_data     (data_mem_write_data     )
);

initial
begin

    $finish;
end

endmodule