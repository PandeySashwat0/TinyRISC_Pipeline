`timescale 1ns / 1ps

module tb_Pipeline(
    
    );
    reg clk;
    reg rst;
    
    TinyRISC_Pipeline Pipeline(
    .clk(clk), .rst(rst)
    );
    
    
    //generate clk
    initial begin
    clk=0; rst=1;
    forever
    #5clk=~clk;
    end

    
    initial begin
    $readmemb("output.txt", Pipeline.IF.InstructionMemory.mem);
    #5 rst=0;

/*    repeat (50) begin
    @(posedge clk)
    
    $display("\nCycle: %0t", $time);
            $display("========================");
            $display("FETCH     | PC: %h | Inst: %h", 
            Pipeline.IF_UNIT.PC, Pipeline.IF_UNIT.instruction_out);
            
            $display("IF/OF     | PC: %h | Inst: %h", 
            Pipeline.reg_IF_OF.PC_out, Pipeline.reg_IF_OF.instruction_out);
            
            $display("OF/EX     | PC: %h | rd: %h | A: %h | B: %h |op2: %h |ControlWord: %h",
             Pipeline.reg_OF_EX.PC_out, Pipeline.reg_OF_EX.rd, 
             Pipeline.reg_OF_EX.A, Pipeline.reg_OF_EX.B, Pipeline.reg_OF_EX.op2, Pipeline.reg_OF_EX.ControlWord);         
              
            $display("EX/MA     | PC: %h | rd: %h | ALU Result: %h | op2: %h", 
             Pipeline.reg_EX_MA.PC, Pipeline.reg_EX_MA.rd, 
             Pipeline.reg_EX_MA.aluResult, Pipeline.reg_EX_MA.op2);
            
            $display("MA/WB     | PC: %h | rd: %h | ALU Result: %h | LD Result: %h", 
             Pipeline.reg_MA_WB.PC_out, Pipeline.reg_MA_WB.rd_out, 
             Pipeline.reg_MA_WB.aluResult_out, Pipeline.reg_MA_WB.ldResult); 
                        
            $display("WB        | Write Enable: %b | Write Addr: %h | Write Data: %h", 
             Pipeline.WB_UNIT.wbEnable, Pipeline.WB_UNIT.wbAddr, 
             Pipeline.WB_UNIT.wbData);
    end*/
    
    #200
    $finish;
    end

/* basically the PC is not updating unless isBranch and BranchTarget are known 
these will be known only if the respective instruction has reached CU*/
endmodule
