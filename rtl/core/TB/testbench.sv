/*** 
 * @Author: jia200151@126.com
 * @Date: 2026-01-07 15:21:35
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-30 10:43:21
 * @FilePath: \core\TB\testbench.sv
 * @Description: 
 * @Copyright (c) 2026 by lwj email: jia200151@126.com, All Rights Reserved.
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
    virtual core_if vif;
    function new(virtual core_if vif=null);
        // Initialize arrays to avoid null references
        foreach(registers[i]) registers[i] = 0;
        foreach(v_registers[i,j]) v_registers[i][j] = 0;
        nzp = 3'd0;
        this.vif = vif;
    endfunction

    function void reset();
        for (integer index=0; index<16 ; index=index+1) begin
            registers[index] = 0;
            for(integer v_index=0;v_index < Vector_Size;v_index=v_index+1)begin
                v_registers[index][v_index] = 0;
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

    task main();
    forever begin
         @(posedge this.vif.clk);
        update(vif.registers,vif.v_registers);
    end
       

    endtask
endclass
class mem_model#(parameter int mem_width=8);
    string name;
    int mem_depth;
    logic[mem_width-1:0] mem[];
    virtual core_if vif;
    
    function new(string name="mem_model",int mem_depth=1024,virtual core_if vif=null);
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
    function void poke(input int addr,input logic[mem_width-1:0]data);//back door write
        this.mem[addr] = data;
    endfunction
    function logic[mem_width-1:0] peek(input int addr);//back door read
        peek = this.mem[addr];
    endfunction
endclass

class program_mem#(parameter int mem_width=32) extends mem_model#(.mem_width(mem_width));
    // Add constructor
    function new(string name="program_mem", int mem_depth=1024, virtual core_if vif=null);
        super.new(name, mem_depth, vif);  // Call base class constructor
    endfunction
    //front door
    task read();
        
        vif.program_mem_read_ready <= 0;
        if(vif.program_mem_read_valid)begin
            vif.program_mem_read_data <= mem[vif.program_mem_read_address];
            vif.program_mem_read_ready <= 1;  
        end
    endtask
    task main();
        forever begin
            @(posedge this.vif.clk);
            read();
        end
    endtask
endclass //className extends superClass;

class data_mem#(parameter int mem_width=8) extends mem_model#(.mem_width(mem_width));
    // Add constructor
    function new(string name="data_mem", int mem_depth=1024, virtual core_if vif=null);
        super.new(name, mem_depth, vif);  // Call base class constructor
    endfunction
    //front door
    task read();
        @(posedge this.vif.clk);
        vif.data_mem_read_ready <= 0;
        if(vif.data_mem_read_valid)begin
            vif.data_mem_read_data <= mem[vif.data_mem_read_address];
            vif.data_mem_read_ready <= 1;
        end
    endtask

    task write();
        @(posedge this.vif.clk);
        vif.data_mem_write_ready <= 0;
        if(vif.data_mem_write_valid)begin
            mem[vif.data_mem_write_address] <= vif.data_mem_write_data;
            vif.data_mem_write_ready <= 1;
        end

    endtask
    task main();
        forever begin
            @(posedge this.vif.clk);
            fork
                write();
                read();
            join       
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

    logic[DATA_MEM_DATA_BITS*16-1:0] registers_out;
    logic[DATA_MEM_DATA_BITS*Vector_Size*16-1:0] v_registers_out;
    logic[DATA_MEM_DATA_BITS-1:0] registers[0:15];
    logic [DATA_MEM_DATA_BITS*Vector_Size-1:0] v_registers[0:15];
    integer reg_i;
    always @(*) begin
        for (reg_i = 0;reg_i<16 ;reg_i=reg_i+1 ) begin
                v_registers[reg_i] <= v_registers_out[reg_i*DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS];
                registers[reg_i] <= registers_out[reg_i*DATA_MEM_DATA_BITS*Vector_Size+:DATA_MEM_DATA_BITS];
            end
    end
endinterface //core_if
typedef enum
 {NOP=00000,BRNZP=00001,CMP=00010,ADD=00011,SUB=00100,MUL=00101,DIV=00110,LDR=00111,STR=01000,
 CONST=01001,RET=01111,
 VADD=10011,VSUB=510100,VMUL=10101,VDIV=10110,VLDR=10111,VSTR=11000  } ISA;
class instruction_transaction#(
    parameter int   DATA_MEM_ADDR_BITS = 8,
                    DATA_MEM_DATA_BITS    = 8,
                    PROGRAM_MEM_ADDR_BITS = 8,
                    PROGRAM_MEM_DATA_BITS = 32,
                    Vector_Size           = 4
);
    localparam  REG_DATA_BITS= 4;
    rand ISA instruction_type;
    rand logic[REG_DATA_BITS-1:0] d_data;
    rand logic[REG_DATA_BITS-1:0] s_data;
    rand logic[REG_DATA_BITS-1:0] t_data;
    logic[PROGRAM_MEM_DATA_BITS-1:0] instruction;
    constraint no_ret{ instruction_type != RET;}
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
        instruction = 0;
        instruction[PROGRAM_MEM_DATA_BITS-1] = instruction_type[4];
        instruction[REG_DATA_BITS-1:0] = t_data;
        instruction[2*REG_DATA_BITS-1:REG_DATA_BITS] = s_data;
        instruction[3*REG_DATA_BITS-1:2*REG_DATA_BITS] = d_data;
        instruction[4*REG_DATA_BITS-1:3*REG_DATA_BITS] = instruction_type[3:0];
       

        cov.sample();
    endfunction

    function void display();
        $display("-------------------------");
        $display("- %s ",instruction_type.name());
        $display("-------------------------");
        $display("- s = %0d, t = %0d",s_data,t_data);
        $display("- d = %0d",d_data);
        $display("-------------------------");
        if(instruction_type[3:0]!=instruction[15:8])
            $display("error:%b",instruction_type[3:0]);
        
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
    rand data_transaction data_trans[2**DATA_MEM_ADDR_BITS];//data's number is fixed;
    registers_model rm;

    function new();
        i_trans = new[0];
        this.data_num =  $pow(2,DATA_MEM_ADDR_BITS);
        // Initialize data_trans array
        foreach(data_trans[i]) begin
            data_trans[i] = new();
        end
        rm = new();
    endfunction
    function void pre_randomize();
        this.i_num = $urandom_range(1,255);
         $display("i_trans size(): %0d", this.i_num);
        this.i_trans = new[i_num];
       
    endfunction

    function void post_randomize();
        
        ISA i_type;
        $display("i_trans size(): %0d", this.i_num);
        // First, ensure all i_trans elements are constructed
        foreach(i_trans[i]) begin
            i_trans[i] = new();
            // Randomize the new instruction
            if (!i_trans[i].randomize()) begin
                $error("Failed to randomize instruction_transaction at index %0d", i);
            end
            //$display("i_trans type: %s", this.i_trans[i].instruction_type.name());
        end
        i_type = RET;
        if (i_num > 0) begin
            i_trans[i_num-1].instruction_type = i_type; //set the last instruction type RET
            i_trans[i_num-1].post_randomize();
        end
    endfunction

    function int compare(transaction tr);//compare register and data ram
        compare = 1;
        for (integer reg_i=0;reg_i < 16 ;reg_i++ ) begin
            if(this.rm.registers[reg_i]!=tr.rm.registers[reg_i])
                $display("R%d,exp:%d,act:%d;",reg_i,this.rm.registers[reg_i],tr.rm.registers[reg_i]);
                compare = 0;
                break;
            if(this.rm.v_registers[reg_i]!=tr.rm.v_registers[reg_i])
                compare = 0;
                break;
        end
        for (integer ram_i=0; ram_i < $pow(2,PROGRAM_MEM_ADDR_BITS) ; ram_i++) begin
            if(this.data_trans[ram_i].data != tr.data_trans[ram_i].data)
                compare = 0;
                break;
        end             
        return compare;

    endfunction
endclass
class generator;
    rand transaction tr;
    mailbox gen2dri;
    int repeat_num;
    function new(mailbox gen2dri);
        this.gen2dri = gen2dri; 
        this.repeat_num = 50;
    endfunction

    function void config_num(int repeat_num);
        this.repeat_num = repeat_num;
    endfunction
    task automatic main();
        for (integer no_tr=0;no_tr < repeat_num ;no_tr++ ) begin
            tr = new();
            tr.randomize();
            $display("time:%d",$time());
            $display("i_num:%d",tr.i_trans.size());
            gen2dri.put(tr);
        end
        $display("generator done");
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
            vif.registers_out <= 0;
            vif.v_registers_out <= 0;
            //memory reset
            program_ram.reset();
            data_ram.reset();
            rm.reset();
        join
        wait(!vif.reset);
        $display("/******reset ended******/");
    endtask

    function void mem_write(input transaction tr);//把获取的transaction中的数据写到存储器中
        integer i_addr;
        integer data_addr;
        logic[PROGRAM_MEM_DATA_BITS-1:0] instruction;
        logic[DATA_MEM_DATA_BITS-1:0] data;
        for (i_addr = 0;i_addr<tr.i_num ;i_addr=i_addr+1 ) begin
            instruction = tr.i_trans[i_addr].instruction;
            $display("instruction num:%d",i_addr);
            $display("instruction:%h",instruction);
            tr.i_trans[i_addr].display();
            this.program_ram.poke(i_addr,instruction);
            
        end
        for (data_addr = 0;data_addr<tr.data_num ; data_addr=data_addr+1) begin
            data = tr.data_trans[data_addr].data;
            this.data_ram.poke(data_addr,data);
            
        end
    endfunction


    task main();
        transaction tr;
        tr = new();
        forever begin
            $display("negedge clk");
            @(negedge vif.clk);
            $display("gen2dri get");
            gen2dri.get(tr);
            $display("dri2scb put");
            dri2scb.put(tr);
            $display("mem load start");
            mem_write(tr);
            $display("mem load success");
            @(posedge vif.clk);
            $display("start computation");
            vif.start <= 1;
            wait(vif.done);
        
        end
     
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
    function void mem_store(output transaction tr);//读取存储器模型中的数据
        integer i_addr;
        integer data_addr;
        integer reg_addr;
        logic[DATA_MEM_DATA_BITS-1:0] reg_data;
        logic[DATA_MEM_DATA_BITS*Vector_Size-1:0] vreg_data;
        tr = new();
        for (i_addr = 0;i_addr<tr.i_trans.size() ;i_addr=i_addr+1 ) begin
            tr.i_trans[i_addr].instruction = this.program_ram.peek(i_addr); 
        end
        for (data_addr = 0;data_addr<tr.data_num ; data_addr=data_addr+1) begin
            tr.data_trans[data_addr].data = this.data_ram.peek(data_addr);
        end
        tr.rm.nzp = this.rm.nzp;
        for (reg_addr = 0;reg_addr<16 ; reg_addr++) begin
            tr.rm.registers[reg_addr] = this.rm.registers[reg_addr];
            tr.rm.v_registers[reg_addr] = this.rm.v_registers[reg_addr];
        end
    endfunction
    task main();
        transaction tr;
        forever begin
            $display("negedge clk");
            @(negedge vif.clk);
            $display("wait done");
            wait(vif.done);
            mem_store(tr);
            mon2scb.put(tr);
            wait(vif.start);
        end
        
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
        this.dri = new(vif,gen2dri,dri2scb);
        this.mon = new(vif,mon2scb);
        this.program_ram = new("program_ram",256,vif);
        this.data_ram = new("data_ram",256,vif);
        this.rm = new(vif);
    endfunction

    function void connect();
        dri.connect(program_ram,data_ram,rm);
        mon.connect(program_ram,data_ram,rm);
    endfunction

    task main();
        fork
            mon.main();
            dri.main();
            program_ram.main();
            data_ram.main();
            rm.main();
        join

    endtask

endclass
class scoreboard#(
    parameter int   PROGRAM_MEM_DATA_BITS = 32,
                    DATA_MEM_DATA_BITS    = 8,
                    Vector_Size           = 4
);
    mailbox mon2scb;
    mailbox dri2scb;
    transaction dri_tr_queue[$],mon_tr_queue[$];
    int num_dri_tr,num_mon_tr;
    function new(input mailbox mon2scb,dri2scb);
        this.mon2scb = mon2scb;
        this.dri2scb = dri2scb;
    endfunction

    task receive_dri_tr();
        transaction tr;
        forever begin
            wait(dri2scb.num()!=0);
            dri2scb.get(tr);
            dri_tr_queue.push_back(tr);
            num_dri_tr++;
        end
    endtask
    task receive_mon_tr();
        transaction tr;
        forever begin
            wait(mon2scb.num()!=0);
            mon2scb.get(tr);
            mon_tr_queue.push_back(tr);
            num_mon_tr++;
        end
    endtask

    function void reference_model(ref transaction tr);
        int i;
        int pc = 0;
        int i_num;
        reg[DATA_MEM_DATA_BITS-1:0] rs,rt;
        reg[DATA_MEM_DATA_BITS-1:0] vrs[Vector_Size],vrt[Vector_Size];
        i_num = tr.i_num;
        
        while(pc<tr.i_num) begin
            rs = tr.rm.registers[tr.i_trans[pc].s_data];
            rt = tr.rm.registers[tr.i_trans[pc].t_data];
            vrs = tr.rm.v_registers[tr.i_trans[pc].s_data];
            vrt = tr.rm.v_registers[tr.i_trans[pc].t_data];
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
                    tr.rm.nzp = {rs-rt<0,rs-rt==0,rs-rt>0};
                end
                ADD:begin
                    tr.rm.registers[tr.i_trans[pc].d_data] = rs + rt;
                end
                SUB:begin
                    tr.rm.registers[tr.i_trans[pc].d_data] = rs - rt;
                end
                MUL:begin
                    tr.rm.registers[tr.i_trans[pc].d_data] = rs * rt;
                end
                DIV:begin
                    tr.rm.registers[tr.i_trans[pc].d_data] = rs / rt;
                end
                LDR:begin
                    tr.rm.registers[tr.i_trans[pc].d_data] = tr.data_trans[rs].data;
                end
                STR:begin
                    tr.data_trans[rs].data = rt;
                end
                CONST:begin
                    tr.rm.registers[tr.i_trans[pc].d_data] = {tr.i_trans[pc].s_data,tr.i_trans[pc].t_data};
                end
                RET:begin
                    break;
                end
                VADD:begin
                    for (i = 0;i<Vector_Size ;i++ ) begin
                        tr.rm.v_registers[tr.i_trans[pc].d_data][i] = vrs[i] + vrt[i];
                    end
                    
                end
                VSUB:begin
                    for (i = 0;i<Vector_Size ;i++ ) begin
                        tr.rm.v_registers[tr.i_trans[pc].d_data][i] = vrs[i] - vrt[i];
                    end
                end
                VMUL:begin
                    for (i = 0;i<Vector_Size ;i++ ) begin
                        tr.rm.v_registers[tr.i_trans[pc].d_data][i] = vrs[i] * vrt[i];
                    end
                end
                VDIV:begin
                    for (i = 0;i<Vector_Size ;i++ ) begin
                        tr.rm.v_registers[tr.i_trans[pc].d_data][i] = vrs[i] / vrt[i];
                    end
                end
                VLDR:begin
                    for (i = 0;i<Vector_Size ;i++ ) begin
                        tr.rm.v_registers[tr.i_trans[pc].d_data][i]= tr.data_trans[vrs[i]].data;
                    end
                end
                VSTR:begin
                    for (i = 0;i<Vector_Size ;i++ ) begin
                        tr.data_trans[vrs[i]].data = vrt[i];
                    end
                end
            endcase
            pc = pc+1;
        end
    endfunction

    task compare();
        transaction exp_tr,act_tr;
        forever begin
            if(mon_tr_queue.size()!=0)begin
                exp_tr = mon_tr_queue.pop_front();
                act_tr = dri_tr_queue.pop_front();
                $display("/*********start compare num_mon:%d,num_dri:%d*********/",num_mon_tr,num_dri_tr);
                reference_model(exp_tr);
                if(!act_tr.compare(exp_tr))
                    $display("/*********EEROR*************/\n");
                $display("/*********end compare num_mon:%d,num_dri:%d*********/",num_mon_tr,num_dri_tr);
                
            end
            #1;
        end
    endtask

    task main();
        fork
            receive_dri_tr();
            receive_mon_tr();
            compare();
        join
    endtask
endclass

class environment;
    generator gen;
    agent agt;
    scoreboard scb;
    virtual core_if vif;
    mailbox mon2scb;
    mailbox gen2dri;
    mailbox dri2scb;
    int repeat_num;
    function new(virtual core_if vif);
        this.vif = vif;
        gen2dri = new();
        mon2scb = new();
        dri2scb = new();
        gen = new(gen2dri);
        agt = new(vif,gen2dri,mon2scb,dri2scb);
        scb = new(mon2scb,dri2scb);
        agt.connect();
    endfunction

    task main();
        gen.config_num(repeat_num);
        agt.dri.reset();
        fork
            gen.main();
            agt.main();
            scb.main();
        join_any

        wait(scb.num_mon_tr >= repeat_num);
        #1000;$finish;
    endtask //automatic
endclass

program test(core_if vif);
    environment env;
    initial begin
        env = new(vif);
        env.repeat_num = 20;
        env.main();
    end
    
endprogram