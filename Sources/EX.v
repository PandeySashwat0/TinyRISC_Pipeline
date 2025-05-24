/*
ControlWord [21:0] = {
    [21]    isRet,    
    [20]    isWb,     
    [19]    isImmediate,
    [18:15] isUBranch, isBeq, isBgt, isCall,    
     
    [14:10] isCmp, isAdd, isSub, isLd, isSt,     
    {9:7]   isOr, isNot, isAnd,               
    [6:5]   isDiv, isMod,                      
    [4]     isMov,                              
    [3]     isMul,                              
    [2:0]   isLsl, isLsr, isAsr };  

*/

// _mid extension is used for signifying input to EX_MA reg

module EX(
    input  clk,
    [31:0] PC_in, 
    [31:0] instruction_in,
    [21:0] ControlWord_in,
    [31:0] BranchTarget_in, A, B, op2_in,
    
    //bit 0 is for MA_EX conflict, bit 1 is for RW_EX conflict
    input [1:0] isConflict_rs1, isConflict_rs2, 
    input isConflict_op2,    
    input [31:0] wbData, aluResult_MA,
    
    output isBranchTaken,
    [31:0] PC, op2, BranchTarget,
    [31:0] instruction_EX, instruction_MA,
    [21:0] ControlWord,
    [31:0] aluResult
    );
    
    assign instruction_EX= instruction_in;
    //goes to IF unit
    assign BranchTarget= ControlWord_in[21]? A: BranchTarget_in;
    reg [31:0] aluResult_in;
    wire [31:0] aluA, aluB; 
    
    //priority is given to MA while forwarding if both have conflict
    assign aluA= isConflict_rs1[0]===1 ? aluResult_MA: 
                (isConflict_rs1[1]===1 ? wbData: A);
    assign aluB= isConflict_rs2[0]===1 ? aluResult_MA: 
                (isConflict_rs2[1]===1 ? wbData: B);
                
    //instantiate adder unit
    wire [31:0] adderResult;
      
    Adder AdderUnit(
    aluA, aluB,
    ControlWord_in [14:10] ,
    setGt, setEq,
    adderResult 
    );
    
    //instantiate divide unit
    wire [31:0] dividerResult;
    
    Divider DividerUnit(
    aluA, aluB,
    ControlWord_in [6:5] ,
    dividerResult 
    );

    //instantiate multiplier unit
     wire [31:0] multiplierResult;
     Multiplier MultiplierUnit(
     .A(aluA), .B(aluB),
     .isMul(ControlWord_in[3]),
     .multiplierResult(multiplierResult [31:0])  
     );
     
     //instantiate shift unit
     wire [31:0] shiftResult;
     Shift ShiftUnit(
     aluA, aluB,
     ControlWord_in [2:0],
     shiftResult  
     );
     
     //instantiate logical unit
     wire [31:0] logicalResult;
     Logical LogicalUnit(
     aluA, aluB,
     ControlWord_in  [9:7] ,
     logicalResult  
     );
     
     //instantiate mov unit
     wire [31:0] movResult;
     Mov MovUnit(
     ControlWord_in[4],
     aluB,
     movResult 
     );
    
    //assign one of these results to aluResults through MUX
    
    
                 
    always @(*) begin    
     
    
    case({(|ControlWord_in[14:10]) , (|ControlWord_in[9:7]) , 
             (|ControlWord_in[6:5]) , (ControlWord_in[4]) , 
             (ControlWord_in[3]) , (|ControlWord_in[2:0])}) 
                
    6'b100000:
    aluResult_in= adderResult;
    
    6'b010000:
    aluResult_in= logicalResult;
    
    6'b001000:
    aluResult_in= dividerResult;
    
    6'b000100:
    aluResult_in= movResult;
    
    6'b000010:
    aluResult_in= multiplierResult;
    
    6'b000001:
    aluResult_in= shiftResult;
    
    default: aluResult_in= 32'bX;
    
    endcase
    end
    
    wire eq,gt;
    flagReg Flags(.isCmp(ControlWord_in[14]), .setGt(setGt), .setEq(setEq), .eq(eq), .gt(gt));
    assign isBranchTaken= ControlWord_in[17]&eq 
    || ControlWord_in[16]&gt 
    || ControlWord_in[18];
    
///////////////////////////////////////////////////////////////////////////    
//instantiate EX_MA register

wire [31:0] w= isConflict_op2? wbData: op2_in;

    EX_MA EX_MA(
    .clk(clk), 
    .PC_in(PC_in), 
    .op2_in(w),  
    .aluResult_in(aluResult_in),
    .instruction_in(instruction_in),
    .ControlWord_in(ControlWord_in),

    .PC(PC), .op2(op2), 
    .aluResult(aluResult),
    .instruction_out(instruction_MA),
    .ControlWord(ControlWord)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////

module flagReg ( 
input isCmp,
setEq, setGt,
output reg eq,
reg gt
);

reg [1:0] flags;
always @(*) 
    if(isCmp) begin
    eq=setEq;
    gt=setGt;
    end

    
endmodule

///////////////////////////////////////////////////////////////////////////
module Adder (
input [31:0] A, B,
[14:10] ControlWord,
output reg setGt, setEq,
reg [31:0] adderResult
);

always @(*) begin
    if(ControlWord[14]) begin
        if(A==B) begin
        setEq=1; setGt=0;
        end
        
        else if(A>B) begin
        setGt=1; setEq=0;
        end
        
        else begin
        setGt=0; setEq=0;
        end
   end
   
   if(ControlWord[13] || ControlWord[11]|| ControlWord[10])
   adderResult= A+B;
   
   if(ControlWord[12])
   adderResult= A-B;
   
end
endmodule

module Divider(
input [31:0] A, B,
[6:5] ControlWord,
output reg [31:0] dividerResult
);

always @(*) begin
    if(ControlWord[6])
    dividerResult= A/B;
    
    if(ControlWord[5])
    dividerResult= A%B;
end
endmodule

module Multiplier(
  input isMul,
  [31:0] A, B,
  output reg [31:0] multiplierResult  
);
    always @(*) begin
    if(isMul)
    multiplierResult= A*B;
end
endmodule

module Shift(
   input signed [31:0] A, B,
   [2:0] ControlWord,
   output reg signed [31:0] shiftResult  
);
    
    always @(*) begin
    case (ControlWord)
    
    3'b001: shiftResult= A>>>B;
    3'b010: shiftResult= A>>B;
    3'b100: shiftResult= A<<B;
    
    endcase
    end
endmodule

module Logical(
   input [31:0] A, B,
   [9:7] ControlWord,
   output reg [31:0] logicalResult  
);
   
   always @(*) begin
    case (ControlWord)
    
    3'b100: logicalResult= A|B;
    3'b010: logicalResult= ~A;
    3'b001: logicalResult= A&B;
    
    endcase
    end
endmodule

module Mov(
  input isMov,
  [31:0] B,
  output reg [31:0] movResult  
);
    always @(*) begin
    if(isMov)
    movResult= B;
    end
endmodule

/* This is the pipeline register between EX and MA units
   to store:
    1bit  isBranchTaken
    32bit PC
    32bit op2
    32bit BranchTarget
    32bit aluResult
    32bit instruction
    22bit control word
*/

module EX_MA(
    input clk,
    input [31:0] PC_in, op2_in, aluResult_in,
    input [31:0] instruction_in,
    input [21:0] ControlWord_in,

    output [31:0] PC, op2, aluResult,
    output [31:0] instruction_out,
    output [21:0] ControlWord
    );


    reg [31:0] PC_reg, op2_reg, aluResult_reg;
    reg [31:0] instruction_reg;
    reg [21:0] ControlWord_reg;

    assign PC = PC_reg[31:0];
    assign op2 = op2_reg[31:0];
    assign aluResult = aluResult_reg[31:0];
    assign instruction_out = instruction_reg[31:0];
    assign ControlWord = ControlWord_reg[21:0];

    always @(posedge clk) begin
        PC_reg[31:0] <= PC_in;
        op2_reg[31:0] <= op2_in;
        aluResult_reg[31:0] <= aluResult_in;
        instruction_reg[31:0] <= instruction_in;
        ControlWord_reg[21:0] <= ControlWord_in;
    end

endmodule