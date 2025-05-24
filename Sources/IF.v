module IF(
input clk, isBranch, rst,
[31:0] BranchTarget,
output [31:0] PC,
[31:0] instruction
);

reg [31:0] regPC;
wire [31:0] instruction_in, PC_in; //input to IF_OF

instructionMemory InstructionMemory(
.pcAddr(PC_in),
.instruction(instruction_in)
);

assign PC_in=regPC;         //to IF_OF
 

always @(posedge clk or posedge rst) begin
    if (rst)
        regPC <= 32'h00000000;  // Initialize PC on reset
    else if (isBranch === 1'b1)
        regPC <= BranchTarget;
    else
        regPC <= regPC + 1;
end

IF_OF IF_OF(
    clk,
    PC_in, instruction_in,
    PC,instruction
    );
    
endmodule

/* ROM memory for testing having asynchronous read
Synchronous read causes instruction fetch delay (Instruction is fetched for previous PC). This causes problems in case of branch instruction
We could conversely use negative edge triggered memory to solve this*/

module instructionMemory(
input  [31:0] pcAddr,
output reg [31:0] instruction
);

reg [31:0] mem [2^32-1: 0];
always @(*)
 instruction= mem[pcAddr];
 
endmodule

/*this is the pipeline register between IF and OF stage. 
to store:
    32bit PC
    32bit instruction
    64bit total
*/

module IF_OF(
    input clk,
    [31:0] PC_in, instruction_in,
    output [31:0] PC_out,instruction_out
    );
    
    reg [31:0] PC_IF_OF;
    reg [31:0] instruction_IF_OF;
    
    assign instruction_out = instruction_IF_OF [31:0];
    assign PC_out = PC_IF_OF [31:0];
    
    always @(posedge clk)   begin    
    PC_IF_OF [31:0] <= PC_in; 
    instruction_IF_OF [31:0] <= instruction_in ;       
    end
    
endmodule