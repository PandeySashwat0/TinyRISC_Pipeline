module MA(
    
    input clk,
    [31:0] PC_in, op2,
    [31:0] instruction_in,
    [21:0] ControlWord_in,
    [31:0] aluResult_in,
    
    input isConflict_rs2, 
    [31:0] wbData,
    
    output [31:0]aluResult_MA,
    
    output 
    [31:0] PC, 
    [31:0] instruction_MA, instruction_WB,    
    [21:0] ControlWord,
    [31:0] aluResult,
    [31:0] ldResult
    );
    
    wire [31:0] ldResult_in;
    assign aluResult_MA [31:0]= aluResult_in;
    assign instruction_MA= instruction_in;
    
    MemUnit MemoryUnit(
    .isLd(ControlWord_in[11]), .isSt(ControlWord_in[10]),
    .mar(aluResult_in), 
    .mdr(isConflict_rs2? wbData: op2),
    .ldResult(ldResult_in)
);

////////////////////////////////////////////////////////////////////////////////
MA_WB MA_WB(
    clk,
    PC_in,
    instruction_in,
    ControlWord_in,
    aluResult_in,
    ldResult_in,

    PC,
    instruction_WB,
    ControlWord,
    aluResult,
    ldResult
    );
        
endmodule

module MemUnit (
    input isLd, isSt,
    [31:0] mdr, mar,
    output [31:0] ldResult
);
    
    dataMemory DataMemory( .isLd(isLd), .isSt(isSt), .addr(mar), .data_in(mdr), .data_out(ldResult));
endmodule

module dataMemory(
    input isLd,isSt,
    [31:0] addr,
    input [31:0]data_in,
    output reg [31:0]data_out
);
    
    reg [31:0] mem [0:2^32-1];
    
    always @(*) begin
    if(isSt && ~isLd)
    mem[addr]= data_in;
    
    if(isLd && ~isSt)    
    data_out= mem[addr];
    end
endmodule

/* This is the pipeline register between MA and WB units
   to store:
    32bit PC
    32bit  instruction
    22bit control word
    32bit aluResult
    32bit ldResult
*/

module MA_WB(
    input clk,
    input [31:0] PC_in,
    input [31:0] instruction_in,
    input [21:0] ControlWord_in,
    input [31:0] aluResult_in,
    input [31:0] ldResult_in,

    output [31:0] PC_out,
    output [31:0] instruction_WB,
    output [21:0] ControlWord_out,
    output [31:0] aluResult_out,
    output [31:0] ldResult
    );

    reg [31:0] PC_reg, aluResult_reg, ldResult_reg;
    reg [31:0] instruction_reg;
    reg [21:0] ControlWord_reg;

    assign PC_out = PC_reg[31:0];
    assign instruction_WB = instruction_reg[31:0];
    assign ControlWord_out = ControlWord_reg[21:0];
    assign aluResult_out = aluResult_reg[31:0];
    assign ldResult = ldResult_reg[31:0];

    always @(posedge clk) begin
        PC_reg[31:0] <= PC_in;
        instruction_reg[31:0] <= instruction_in;
        ControlWord_reg[21:0] <= ControlWord_in;
        aluResult_reg[31:0] <= aluResult_in;
        ldResult_reg[31:0] <= ldResult_in;
    end

endmodule