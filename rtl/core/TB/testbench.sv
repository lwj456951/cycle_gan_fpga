/*** 
 * @Author: jia200151@126.com
 * @Date: 2026-01-07 15:21:35
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-07 17:17:40
 * @FilePath: \core\TB\testbench.sv
 * @Description: 
 * @Copyright (c) 2026 by lwj email: jia200151@126.com, All Rights Reserved.
 */
/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-12-31 16:51:02
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-07 15:12:14
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
    reg[2:0] nzp;
    function void reset();
        for (integer index=0; index<16 ; index=index+1) begin
            registers[index] <= 0;
            for(integer v_index=0;v_index < Vector_Size;v_index=v_index+1)begin
                v_registers[index][v_index] <= 0;
            end
        end
        nzp = 3'd0;
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
        this.mem = new[mem_depth];
    endfunction
    task reset();
        integer i;
        wait(vif.reset);
        for(i=0;i<this.mem_depth;i=i+1)begin
            this.mem[i] = 0;
        end
        wait(!vif.reset);
    endtask
    task peek(input int addr,input logic[mem_width-1:0]data);//back door read
        this.mem[addr] = data;
    endtask
    task poke(input int addr,output logic[mem_width-1:0] data);//back door write
        data = this.mem[addr];
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

    covergroup cov;
        coverpoint instruction_type{
            bins branch = {BRNZP,CMP};
            bins scalar_arithmetic = {ADD,SUB,MUL,DIV};
            bins scalar_ls = {LDR,STR};
            bins scalar_const = {CONST};
            bins vector_arithmetic = {VADD,VSUB,VMUL,VDIV};
            bins vector_ls = {VSTR,VLDR};
            bins nop = {NOP};
        }
    endgroup
    function new();
        cov = new();
        
    endfunction
    function void post_randomize();
        instruction[PROGRAM_MEM_DATA_BITS-1] = instruction_type[4];
        instruction[REG_DATA_BITS:0] = t_data;
        instruction[2*REG_DATA_BITS:REG_DATA_BITS] = s_data;
        instruction[3*REG_DATA_BITS:2*REG_DATA_BITS] = d_data;
        instruction[3*REG_DATA_BITS+:4] = instruction_type[3:0];
        cov.sample();
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

    covergroup cov;
        coverpoint data {
            bins zeros = {0};
            bins mid = {[1:128]};
            bins high = {[128:$]};
        }
    endgroup

    function new();
        cov=new();
    endfunction

    function void post_randomize();
        cov.sample();
    endfunction
endclass
class transaction#(
    parameter int   DATA_MEM_ADDR_BITS = 8,
                    DATA_MEM_DATA_BITS    = 8,
                    PROGRAM_MEM_ADDR_BITS = 8,
                    PROGRAM_MEM_DATA_BITS = 32,
                    Vector_Size           = 4
);
    int data_num;
    int i_num;
    rand instruction_transaction i_trans[];//program ram 
    rand data_transaction data_trans[$pow(2,DATA_MEM_ADDR_BITS)];//data's number is fixed;
    registers_model rm;
    constraint instruction_size{
        i_trans.size() inside {[1:$pow(2,PROGRAM_MEM_ADDR_BITS)]};//instruction's number is random;
    }

    function new();
        i_trans = new[0];
        this.data_num =  $pow(2,DATA_MEM_ADDR_BITS);
    endfunction

    function void post_randomize();
        ISA i_type;
        i_type = RET;
        this.i_num = i_trans.size();

        i_trans[i_num-1].instruction_type = i_type;//set the last instruction type RET
        i_trans[i_num-1].post_randomize();
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

class driver#(
    parameter int   PROGRAM_MEM_DATA_BITS = 32,
                    DATA_MEM_DATA_BITS    = 8
);
    virtual core_if vif;
    mailbox gen2dri;
    mailbox dri2scb;
    program_mem#(.mem_width(PROGRAM_MEM_DATA_BITS)) program_ram;
    data_mem#(.mem_width(DATA_MEM_DATA_BITS)) data_ram;
    registers_model rm;
    function new(virtual core_if vif,mailbox gen2dri,dri2scb);
        this.vif = vif;
        this.gen2dri = gen2dri;
        this.dri2scb = dri2scb;
    endfunction
    function void connect(program_mem#(.mem_width(32)) program_ram,data_mem#(.mem_width(8)) data_ram,registers_model rm);
        this.program_ram = program_ram;
        this.data_ram = data_ram;
        this.rm = rm;
    endfunction
    task reset();
        wait(vif.reset);
         $display("/******reset start******/");
        fork
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
        join
        $display("/******reset ended******/");
        wait(!vif.reset);
    endtask

    function void mem_load(input transaction tr);
        integer i_addr;
        integer data_addr;
        logic[PROGRAM_MEM_DATA_BITS-1:0] instruction;
        logic[DATA_MEM_DATA_BITS-1:0] data;
        for (i_addr = 0;i_addr<tr.i_num ;i_addr=i_addr+1 ) begin
            this.program_ram.peek(i_addr,instruction);
            tr.i_trans[i_addr].instruction = instruction;
        end
        for (data_addr = 0;data_addr<tr.data_num ; data_addr=data_addr+1) begin
            this.data_ram.peek(data_addr,data);
            tr.data_trans[data_addr].data = data;
        end
    endfunction


    task main();
        transaction tr;
        
        @(negedge vif.clk);
        gen2dri.get(tr);
        dri2scb.put(tr);
        mem_load(tr);
        @(posedge vif.clk);
        vif.start <= 1;
        wait(vif.done);
    endtask
endclass
class monitor#(
    parameter int   PROGRAM_MEM_DATA_BITS = 32,
                    DATA_MEM_DATA_BITS    = 8,
                    Vector_Size           = 4
);

    virtual core_if vif;
    mailbox mon2scb;
    program_mem#(.mem_width(PROGRAM_MEM_DATA_BITS)) program_ram;
    data_mem#(.mem_width(DATA_MEM_DATA_BITS)) data_ram;
    registers_model rm;

    function new(virtual core_if vif,mailbox mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction
    function void connect(program_mem#(.mem_width(PROGRAM_MEM_DATA_BITS)) program_ram,data_mem#(.mem_width(DATA_MEM_DATA_BITS)) data_ram,registers_model rm);
        this.program_ram = program_ram;
        this.data_ram = data_ram;
        this.rm = rm;
    endfunction
    function void mem_store(output transaction tr);
        integer i_addr;
        integer data_addr;
        integer reg_addr;
        logic[DATA_MEM_DATA_BITS-1:0] reg_data;
        logic[DATA_MEM_DATA_BITS*Vector_Size-1:0] vreg_data;
        for (i_addr = 0;i_addr<tr.i_trans.size() ;i_addr=i_addr+1 ) begin
            this.program_ram.poke(i_addr,tr.i_trans[i_addr].instruction); 
        end
        for (data_addr = 0;data_addr<tr.data_num ; data_addr=data_addr+1) begin
            this.data_ram.poke(data_addr,tr.data_trans[data_addr].data);
        end
        tr.rm = this.rm;
    endfunction
    task main();
        transaction tr;
        @(negedge vif.clk);
        wait(vif.done);
        mem_store(tr);
        mon2scb.put(tr);
        wait(vif.start);
    endtask
endclass

class agent#(
    parameter int   PROGRAM_MEM_DATA_BITS = 32,
                    DATA_MEM_DATA_BITS    = 8
);
    driver dri;
    monitor mon;
    mailbox gen2dri;
    mailbox mon2scb;
    mailbox dri2scb;
    virtual core_if vif;
    program_mem#(.mem_width(PROGRAM_MEM_DATA_BITS)) program_ram;
    data_mem#(.mem_width(DATA_MEM_DATA_BITS)) data_ram;
    registers_model rm;

    function new(input virtual core_if vif,
                input mailbox gen2dri,mon2scb,dri2scb);
        this.vif = vif;
        this.gen2dri = gen2dri;
        this.mon2scb = mon2scb;
        this.dri2scb =dri2scb;
        dri = new(vif,gen2dri,dri2scb);
        mon = new(vif,gen2dri);
    endfunction

    function void connect();
        dri.connect(program_ram,data_ram,rm);
        mon.connect(program_ram,data_ram,rm);
    endfunction
endclass
class scoreboard;
    mailbox mon2scb;
    mailbox dri2scb;
    transaction dri_tr_queue[$],mon_tr_queue[$];
    int num_dri_tr,num_mon_tr;
    function new(input mailbox mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    task receive_dri_tr();
        transaction tr;
        forever begin
            wait(dri2scb.num()!=0);
            dri2scb.get(tr);
            dri_tr_queue.push_back(tr);
        end
    endtask
    task receive_mon_tr();
        transaction tr;
        forever begin
            wait(mon2scb.num()!=0);
            mon2scb.get(tr);
            mon_tr_queue.push_back(tr);
        end
    endtask

    function reference_model(input transaction tr,output transaction result);
        int pc = 0;
        int i_num;
        i_num = tr.i_num;
        while(pc<tr.i_num) begin
            case(tr.i_trans[pc].instruction_type)
            //{NOP=00000,BRNZP=00001,CMP=00010,ADD=00011,SUB=00100,MUL=00101,DIV=00110,LDR=00111,STR=01000,CONST=01001,RET=01111,
            //VADD=10011,VSUB=10100,VMUL=10101,VDIV=10110,VLDR=10111,VSTR=11000  }
                NOP:begin
                    //do nothing
                end
                BRNZP:begin
                    if(tr.i_trans[pc].d_data[3:1]&tr.rm.nzp != 3'b000)
                        pc = {tr.i_trans[pc].s_data,tr.i_trans[pc].t_data};
                end
                CMP:begin
                    
                end
                ADD:begin
                    
                end
                SUB:begin
                    
                end
                MUL:begin
                    
                end
                DIV:begin
                    
                end
                LDR:begin
                    
                end
                STR:begin
                    
                end
                CONST:begin
                    
                end
                RET:begin
                    
                end
                VADD:begin
                    
                end
                VSUB:begin
                    
                end
                VMUL:begin
                    
                end
                VDIV:begin
                    
                end
                VLDR:begin
                    
                end
                VSTR:begin
                    
                end
            endcase
            pc = pc+1;
        end
    endfunction

    task compare();

    endtask

    task main();
        fork
            receive_dri_tr();
            receive_mon_tr();
            compare();
        join
    endtask
endclass
