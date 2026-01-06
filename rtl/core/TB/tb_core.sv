/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-12-31 16:51:02
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-06 20:02:08
 * @FilePath: \core\TB\tb_core.sv
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */

//~ `New testbench
`timescale  1ns / 1ps

class  registers_model#(parameter int DATA_MEM_ADDR_BITS = 8,
                        DATA_MEM_DATA_BITS    = 8,
                        PROGRAM_MEM_ADDR_BITS = 8,
                        PROGRAM_MEM_DATA_BITS = 32,
                        Vector_Size           = 4);
    reg[DATA_MEM_DATA_BITS-1:0] registers[0:15];
    reg[DATA_MEM_DATA_BITS-1:0] v_registers[0:15][0:Vector_Size-1];
    function void reset();
        for (integer index=0; index<16 ; index=index+1) begin
            registers[index] <= 0;
            for(integer v_index=0;v_index < Vector_Size;v_index=v_index+1)begin
                v_registers[index][v_index] <= 0;
            end
        end
    endfunction

    function void update(logic [DATA_MEM_DATA_BITS-1:0] act_reg[0:15],
                    logic[DATA_MEM_DATA_BITS*Vector_Size-1:0] act_vreg[0:15]);
        for (integer index=0; index<16 ; index=index+1) begin
            registers[index] <= act_reg[index];
            for(integer v_index=0;v_index < Vector_Size;v_index=v_index+1)begin
                v_registers[index][v_index] <= act_vreg[index][v_index*8+:8];
            end
        end
    endfunction
endclass
class mem_model#(parameter int mem_width=8);
    string name;
    int mem_depth;
    logic[mem_width-1:0] mem[];
    virtual core_if vif;
    
    function new(string name,int mem_depth,virtual core_if vif);
        this.name = name;
        this.mem_depth = mem_depth;
        this.vif = vif;
        mem = new[mem_depth];
    endfunction
    task reset();
        integer i;
        wait(vif.reset);
        for(i=0;i<this.mem_depth;i=i+1)begin
            mem[i] = 0;
        end
        wait(!vif.reset);
    endtask
    task peek(input int addr,data);//back door read
        mem[addr] = data;
    endtask
    task poke(input int addr,output int data);//back door write
        data = mem[addr];
    endtask
endclass

class program_mem#(parameter int mem_width=32) extends mem_model#(.mem_width(mem_width));
    //front door
    task read();
        vif.program_mem_read_ready <= 0;
        if(vif.program_mem_read_valid)begin
            vif.program_mem_read_data <= mem[vif.program_mem_read_address];
            vif.program_mem_read_ready <= 1;  
        end
    endtask
endclass //className extends superClass;

class data_mem#(parameter int mem_width=8) extends mem_model#(.mem_width(mem_width));
    //front door
    task read();
        vif.data_mem_read_ready <= 0;
        if(vif.data_mem_read_valid)begin
            vif.data_mem_read_data <= mem[vif.data_mem_read_address];
            vif.data_mem_read_ready <= 1;
        end
    endtask

    task write();
        vif.data_mem_write_ready <= 0;
        if(vif.data_mem_write_valid)begin
            mem[vif.data_mem_write_address] <= vif.data_mem_write_data;
            vif.data_mem_write_ready <= 1;
        end

    endtask
endclass
interface core_if#(
    parameter int   DATA_MEM_ADDR_BITS = 8,
                    DATA_MEM_DATA_BITS    = 8,
                    PROGRAM_MEM_ADDR_BITS = 8,
                    PROGRAM_MEM_DATA_BITS = 32,
                    Vector_Size           = 4
)(input logic clk,reset);
    logic start;
    logic enable;
    logic[7:0]   core_id;
    logic[7:0]   engine_id;
    logic[7:0]   task_id;
    logic                           program_mem_read_ready;
    logic[PROGRAM_MEM_DATA_BITS-1:0] program_mem_read_data;
    logic                           data_mem_read_ready;
    logic[DATA_MEM_DATA_BITS-1:0] data_mem_read_data;
    logic                           data_mem_write_ready;

    logic done;
    logic program_mem_read_valid;
    logic[PROGRAM_MEM_ADDR_BITS-1:0]  program_mem_read_address;
    logic data_mem_read_valid;
    logic[DATA_MEM_ADDR_BITS-1:0]    data_mem_read_address;
    logic data_mem_write_valid; 
    logic[DATA_MEM_ADDR_BITS-1:0]  data_mem_write_address;
    logic[DATA_MEM_DATA_BITS-1:0]  data_mem_write_data;
endinterface //core_if
typedef enum
 {NOP=00000,BRNZP=00001,CMP=00010,ADD=00011,SUB=00100,MUL=00101,DIV=00110,LDR=00111,STR=01000,CONST=01001,RET=01111,
 VADD=10011,VSUB=10100,VMUL=10101,VDIV=10110,VLDR=10111,VSTR=11000  } ISA;
class instruction_transaction#(
    parameter int   DATA_MEM_ADDR_BITS = 8,
                    DATA_MEM_DATA_BITS    = 8,
                    PROGRAM_MEM_ADDR_BITS = 8,
                    PROGRAM_MEM_DATA_BITS = 32,
                    Vector_Size           = 4
);
    localparam  REG_DATA_BITS= DATA_MEM_DATA_BITS/2;
    rand ISA instruction_type;
    rand logic[REG_DATA_BITS-1:0] d_data;
    rand logic[REG_DATA_BITS-1:0] s_data;
    rand logic[REG_DATA_BITS-1:0] t_data;
    logic[PROGRAM_MEM_DATA_BITS-1:0] instruction;

    function void post_randomize();
        instruction[PROGRAM_MEM_DATA_BITS-1] = instruction_type[4];
        instruction[REG_DATA_BITS:0] = t_data;
        instruction[2*REG_DATA_BITS:REG_DATA_BITS] = s_data;
        instruction[3*REG_DATA_BITS:2*REG_DATA_BITS] = d_data;
        instruction[3*REG_DATA_BITS+:4] = instruction_type[3:0];
    endfunction

    function void display();
        $display("-------------------------");
        $display("- %s ",instruction_type.name());
        $display("-------------------------");
        $display("- s = %0d, t = %0d",s_data,t_data);
        $display("- d = %0d",d_data);
        $display("-------------------------");
    endfunction
endclass
class data_transaction#(
    parameter int   DATA_MEM_ADDR_BITS = 8,
                    DATA_MEM_DATA_BITS    = 8
);
    rand logic[DATA_MEM_DATA_BITS-1:0] data;
endclass
class transaction#(
    parameter int   DATA_MEM_ADDR_BITS = 8,
                    DATA_MEM_DATA_BITS    = 8,
                    PROGRAM_MEM_ADDR_BITS = 8,
                    PROGRAM_MEM_DATA_BITS = 32,
                    Vector_Size           = 4
);
    int last_num;
    rand instruction_transaction i_trans[];//program ram 
    rand data_transaction data_trans[$pow(2,DATA_MEM_ADDR_BITS)];//data's number is fixed;
    constraint instruction_size{
        i_trans.size() inside {[1:$pow(2,PROGRAM_MEM_ADDR_BITS)]};//instruction's number is random;
    }

    function new();
        i_trans = new[0];
    endfunction

    function void post_randomize();
        ISA i_type;
        i_type = RET;
        last_num = i_trans.size();
        i_trans[last_num-1].instruction_type = i_type;//set the last instruction type RET
        i_trans[last_num-1].post_randomize();
    endfunction
endclass
class generator;
    rand transaction tr;
    mailbox gen2dri;

    function new(mailbox gen2dri);
        this.gen2dri = gen2dri; 
    endfunction


    task automatic main();
        tr = new();
        tr.randomize();
        gen2dri.put(tr);
    endtask //automatic
endclass

class driver;
    virtual core_if vif;
    mailbox gen2dri;
    program_mem#(.mem_width(32)) program_ram;
    data_mem#(.mem_width(8)) data_ram;
    registers_model rm;
    function new(virtual core_if vif,mailbox gen2dri);
        this.vif = vif;
        this.gen2dri = gen2dri;
    endfunction
    function void connect(program_mem#(.mem_width(32)) program_ram,data_mem#(.mem_width(8)) data_ram,registers_model rm);
        this.program_ram = program_ram;
        this.data_ram = data_ram;
        this.rm = rm;
    endfunction
    task reset();
        wait(vif.reset);
        $display("/******reset start******/");
        //dut reset
        vif.start <= 0;
        vif.enable <= 1;
        vif.core_id<= 0;
        vif.engine_id<= 0;
        vif.task_id<= 0;
        vif.program_mem_read_ready<= 0;
        vif.program_mem_read_data<= 0;
        vif.data_mem_read_ready<= 0;
        vif.data_mem_read_data<= 0;
        vif.data_mem_write_ready<= 0;
        //memory reset
        program_ram.reset();
        data_ram.reset();
        rm.reset();
        $display("/******reset ended******/");
        wait(!vif.reset);
    endtask

    task mem_load(transaction tr);
        
    endtask 

    task main();
        transaction tr;
        
        @(negedge vif.clk);
        gen2dri.get(tr);
        mem_load(tr);
        @(posedge vif.clk);
        vif.start <= 1;
        wait(vif.done);
    endtask
endclass

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
// here for test code

registers_model rm;

initial begin
    rm = new();
    rm.reset();
    forever begin
        @(posedge clk);
        #(PERIOD/4);
        rm.update(u_core.u_register.registers,u_core.u_register.v_registers);
    end
end

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

