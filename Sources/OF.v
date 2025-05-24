module OF(
    input wbEnable, clk,
    [31:0] instruction, PC_in, wbData,
    [3:0] wbAddr,
    
    input isConflict_rs1, isConflict_rs2,
    
    output [31:0] instruction_EX, instruction_OF,
    [21:0] ControlWord,
    [31:0] BranchTarget, A, B, op2, PC
    );
        
    wire [31:0] op1;     
    wire [3:0] op1_addr, op2_addr;
    wire [5:0] opcode; 
    wire [17:0] immx;
  
// declare wires that will go to OF_EX reg
    wire [21:0] ControlWord_in;    
    wire [31:0] BranchTarget_in, A_in, B_in, op2_in;
          
    assign opcode= instruction[31:26]; 
    assign instruction_OF= instruction;
//instantiate control unit here. isSt, isRet and isImmediate will be used directly here
    ControlUnit CU(
    opcode,
    isRet,    
    isWb,     
    isImmediate,
    isUBranch, isBeq, isBgt, isCall,
    
    isCmp, isAdd, isSub, isLd, isSt,    //Adder in ALU
    isOr, isNot, isAnd,                 //Logical Unit in ALU
    isDiv, isMod,                       //Deviding unit
    isMov,                              //Mov unit
    isMul,                              //Multiply unit
    isLsl, isLsr, isAsr                 //Shift unit
    
    );
    
    assign ControlWord_in [21:0] = {
    isRet,    
    isWb,     
    isImmediate,
    isUBranch, isBeq, isBgt, isCall, 
    isCmp, isAdd, isSub, isLd, isSt,    
    isOr, isNot, isAnd,                 
    isDiv, isMod,                      
    isMov,                              
    isMul,                              
    isLsl, isLsr, isAsr }; 
////////////////////////////////////////////////////////////////////////////////////////

    
    //make sign extenders and zero extenders
    wire [31:0] signExtendedBranchTarget= {{5{instruction[26]}}, instruction[26:0]}; 
    wire [31:0] signExtendedimmx = (instruction[17:16]==2'b10)? 
        {16'b1, instruction[15:0]} : {16'b0, instruction[15:0]};   

//Call has absolute branch while others have offset branching
       
    assign BranchTarget_in= isCall===1'b1 ? signExtendedBranchTarget
                               : signExtendedBranchTarget+ PC_in ;      
    
    assign immx = instruction [17:0];
 
    assign op1_addr= isRet? 4'd15: instruction[21:18];
    assign op2_addr= isSt? instruction[25:22]: instruction[17:14];

//instantiate regFile to interface    
registerFile RegisterFile(
    .clk(clk),
    .op1_addr(op1_addr), .op2_addr(op2_addr),
    .op1(op1), .op2(op2_in),
    .wbEnable(wbEnable), .wbData(wbData), .wbAddr(wbAddr)
);

assign A_in= isConflict_rs1===1 ? wbData: op1;
assign B_in= isImmediate? signExtendedimmx: 
             (isConflict_rs2===1 ? wbData: op2_in);

////////////////////////////////////////////////////////////////////////////////////////
/*instantiate OF_EX reg*/
OF_EX OF_EX(
    clk,
    instruction,
    ControlWord_in,
    BranchTarget_in, A_in, B_in, op2_in, PC_in,
    
    instruction_EX,
    ControlWord,
    BranchTarget, A, B, op2, PC
    );
    
endmodule

////////////////////////////////////////////////////////////////////////////////////////
/*the register file is asynchronous read and synchronous write.
This is made as a seperate module so that it can be accessed by both OF and WB units
*/
////////////////////////////////////////////////////////////////////////////////////////

module registerFile(
    input clk, wbEnable,
    [3:0] op1_addr, op2_addr, wbAddr, 
    [31:0] wbData,
    output [31:0] op1, op2
);

reg [31:0] regFile [0:15];
assign op1= regFile [op1_addr];
assign op2= regFile [op2_addr];

always @(posedge clk) 
if(wbEnable)
    regFile[wbAddr]= wbData;

endmodule

////////////////////////////////////////////////////////////////////////////////////////
/* we will be using a simple hardwired control unit for our processor
This is to reduce the hardware requirements and reduce complexity
*/
////////////////////////////////////////////////////////////////////////////////////////

module ControlUnit(
    input [5:0] opcode,
    output isRet,    
    isWb,     
    isImmediate,
    isUBranch, isBeq, isBgt, isCall,
    
    isCmp, isAdd, isSub, isLd, isSt,    //Adder in ALU
    isOr, isNot, isAnd,                 //Logical Unit in ALU
    isDiv, isMod,                       //Deviding unit
    isMov,                              //Mov unit
    isMul,                              //Multiply unit
    isLsl, isLsr, isAsr                 //Shift unit
    
    );
    
    assign isRet= opcode[5:1] == 5'b10100 ;
    
    assign isImmediate= opcode[0];
 
 //these are all ALU signals   
    assign isAdd= opcode[5:1] == 5'b00000 ;
    assign isSub= opcode[5:1] == 5'b00001 ;
    assign isLd= opcode[5:1] == 5'b01110 ;
    assign isSt= opcode[5:1] == 5'b01111 ;
    assign isCmp= opcode[5:1] == 5'b00101 ;
    
    assign isOr= opcode[5:1] == 5'b00111 ;
    assign isAnd= opcode[5:1] == 5'b00110 ;
    assign isNot= opcode[5:1] == 5'b01000 ;
    
    assign isLsl= opcode[5:1] == 5'b01010 ;
    assign isLsr= opcode[5:1] == 5'b01011 ;
    assign isAsr= opcode[5:1] == 5'b01100 ;
    
    assign isMul= opcode[5:1] == 5'b00010 ;
    
    assign isDiv= opcode[5:1] == 5'b00011 ;
    assign isMod= opcode[5:1] == 5'b00100 ;
    
    assign isMov= opcode[5:1] == 5'b01001 ;

//These are branch signals.        
    assign isB= opcode[5:1] == 5'b10010 ;
    assign isCall= opcode[5:1] == 5'b10011 ;
    assign isBeq= opcode[5:1] == 5'b10000 ;
    assign isBgt= opcode[5:1] == 5'b10001 ;
    
    assign isUBranch= isB||isRet||isCall;
    
    assign isNop= opcode[5:1] == 5'b01101 ;
    
    assign isWb= ~(isCmp || isNop || (isUBranch && ~isCall) || isSt);
    
endmodule

/*This is the pipeline register between OF and EX units
to store:
    32bit instruction
    32bit op2
    32bit A
    32bit B
    32bit PC
    32bit BranchTarget
    22bit control word
*/

module OF_EX(
    input clk,
    [31:0] instruction_in,
    [21:0] ControlWord_in,
    [31:0] BranchTarget_in, A_in, B_in, op2_in, PC_in,
    
    output [31:0] instruction_EX,
    [21:0] ControlWord,
    [31:0] BranchTarget, A, B, op2, PC
    );
    
    reg [31:0] instruction_reg;
    reg [21:0] ControlWord_reg;
    reg [31:0] BranchTarget_reg, A_reg, B_reg, op2_reg, PC_reg;

    assign instruction_EX = instruction_reg[31:0];
    assign ControlWord = ControlWord_reg[21:0];
    assign BranchTarget = BranchTarget_reg[31:0];
    assign A = A_reg[31:0];
    assign B = B_reg[31:0];
    assign op2 = op2_reg[31:0];
    assign PC = PC_reg[31:0];

    always @(posedge clk) begin
        instruction_reg[31:0]         <= instruction_in;
        ControlWord_reg[21:0]  <= ControlWord_in;
        BranchTarget_reg[31:0] <= BranchTarget_in;
        A_reg[31:0]         <= A_in;
        B_reg[31:0]         <= B_in;
        op2_reg[31:0]       <= op2_in;
        PC_reg[31:0]        <= PC_in;
    end

endmodule