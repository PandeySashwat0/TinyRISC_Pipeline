`timescale 1ns / 1ps

module tb_FU(

    );
    
    reg [31:0] instruction_OF,
    instruction_EX,
    instruction_MA,
    instruction_WB;
    
    reg [31:0] mem [0:3];
    
    initial begin
    $readmemb("output.txt", mem);
    
    #1 instruction_OF= mem[0];
     instruction_EX= mem[1];
     instruction_MA= mem[2];
     instruction_WB= mem[3];
    end
    
///////////////////////////////////////////////////////////////////////////
wire WB_OF_rs1, WB_OF_rs2,
     WB_MA_rs2;
wire [1:0] MAWB_EX_rs1, MAWB_EX_rs2;
    
        
    FU FU(
    
    instruction_OF,
    instruction_EX,
    instruction_MA,
    instruction_WB,
    
    WB_OF_rs1, WB_OF_rs2,
    WB_MA_rs2,
    MAWB_EX_rs1, MAWB_EX_rs2    
    );
endmodule
