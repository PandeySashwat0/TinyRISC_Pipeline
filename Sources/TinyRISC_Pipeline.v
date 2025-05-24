/*
The variable names are prefixed with their destination module
and suffixed with their source module wherever required

For conflict signals Source and destination are both in suffix in respective order
*/

module TinyRISC_Pipeline(
    input clk, rst
    );

///////////////////
wire WB_OF_rs1;
wire WB_OF_rs2;
wire [1:0] MAWB_EX_rs1;
wire [1:0] MAWB_EX_rs2;
wire WB_EX_op2;
wire WB_MA_rs2;
//////////////////
wire [31:0] wbData_WB;
wire [3:0] wbAddr_WB;
wire wbEnable_WB;
//////////////////////////////////////////////////////////////////////////
wire [31:0] PC_MA, WB_aluResult_MA, ldResult_MA;
wire [31:0] WB_instruction_MA, FU_instruction_MA;
wire [21:0] ControlWord_MA;
//////////////////////////////////////////////////////////////////////////
wire [31:0] PC_IF, instruction_IF;
//////////////////////////////////////////////////////////////////////////
wire [31:0] isBranch_EX, PC_EX, op2_EX, BranchTarget_EX, aluResult_EX;
wire [31:0] FU_instruction_EX, MA_instruction_EX;
wire [21:0] ControlWord_EX;
wire [31:0] EX_aluResult_MA;
//////////////////////////////////////////////////////////////////////////

wire [31:0] EX_instruction_OF, FU_instruction_OF;
wire [21:0] ControlWord_OF;
wire [31:0] BranchTarget_OF, A_OF, B_OF, op2_OF, PC_OF;
//////////////////////////////////////////////////////////////////////////
wire [31:0] FU_instruction_WB;

IF IF(
.clk(clk), 
.isBranch(isBranch_EX),
.rst(rst),
.BranchTarget(BranchTarget_EX),

.PC(PC_IF),
.instruction(instruction_IF)
);


OF OF(
    .wbEnable(wbEnable_WB), 
    .clk(clk),
    .instruction(instruction_IF), 
    .PC_in(PC_IF), 
    .wbData(wbData_WB),
    .wbAddr(wbAddr_WB),
    
    .isConflict_rs1(WB_OF_rs1), 
    .isConflict_rs2(WB_OF_rs2),
    
    .instruction_EX(EX_instruction_OF), 
    .instruction_OF(FU_instruction_OF),
    .ControlWord(ControlWord_OF),
    .BranchTarget(BranchTarget_OF), 
    .A(A_OF), .B(B_OF), .op2(op2_OF), 
    .PC(PC_OF)
    );


EX EX(
    .clk(clk),
    .PC_in(PC_OF), 
    .instruction_in(EX_instruction_OF),
    .ControlWord_in(ControlWord_OF),
    .BranchTarget_in(BranchTarget_OF), 
    .A(A_OF), .B(B_OF), .op2_in(op2_OF),
    
    //bit 0 is for MA_EX conflict, bit 1 is for WB_EX conflict
    .isConflict_rs1(MAWB_EX_rs1), 
    .isConflict_rs2(MAWB_EX_rs2),    
    .isConflict_op2(WB_EX_op2), 
    .wbData(wbData_WB), 
    .aluResult_MA(EX_aluResult_MA),
    
    .isBranchTaken(isBranch_EX),
    .PC(PC_EX), .op2(op2_EX), 
    .BranchTarget(BranchTarget_EX),
    .instruction_EX(FU_instruction_EX), 
    .instruction_MA(MA_instruction_EX),
    .ControlWord(ControlWord_EX),
    .aluResult(aluResult_EX)
    );    


MA MA(   
    .clk(clk),
    .PC_in(PC_EX), .op2(op2_EX),
    .instruction_in(MA_instruction_EX),
    .ControlWord_in(ControlWord_EX),
    .aluResult_in(aluResult_EX),
    
    .isConflict_rs2(WB_MA_rs2), 
    .wbData(wbData_WB),
    
    .aluResult_MA(EX_aluResult_MA), //forwarding
    .PC(PC_MA), 
    .instruction_MA(FU_instruction_MA), 
    .instruction_WB(WB_instruction_MA),    
    .ControlWord(ControlWord_MA),
    .aluResult(WB_aluResult_MA),
    .ldResult(ldResult_MA)
    );
    
//////////////////////////////////////////////////////////////////////////


WB WB(
    .PC_in(PC_MA), 
    .instruction_in(WB_instruction_MA),
    .ControlWord_in(ControlWord_MA),
    .aluResult_in(WB_aluResult_MA),
    .ldResult_in(ldResult_MA),
    
    .wbEnable(wbEnable_WB),
    .instruction_WB(FU_instruction_WB),
    .wbAddr(wbAddr_WB),
    .wbData(wbData_WB)
    );

//////////////////////////////////////////////////////////////////////////

FU FU(    
    .instruction_OF(FU_instruction_OF),
    .instruction_EX(FU_instruction_EX),
    .instruction_MA(FU_instruction_MA),
    .instruction_WB(FU_instruction_WB),
    
    .WB_OF_rs1(WB_OF_rs1), 
    .WB_OF_rs2(WB_OF_rs2),
    .WB_MA_rs2(WB_MA_rs2),
    .WB_EX_op2(WB_EX_op2),
    .MAWB_EX_rs1(MAWB_EX_rs1), .MAWB_EX_rs2(MAWB_EX_rs2)    
    );       
    
endmodule