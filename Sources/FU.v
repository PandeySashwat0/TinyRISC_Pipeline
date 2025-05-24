module FU(
    input [31:0] instruction_OF,
    input [31:0] instruction_EX,
    input [31:0] instruction_MA,
    input [31:0] instruction_WB,

    output reg WB_OF_rs1, WB_OF_rs2,
    output reg WB_MA_rs2,
    output reg WB_EX_op2,
    output reg [1:0] MAWB_EX_rs1, MAWB_EX_rs2
);

    // Function to check if an instruction writes to a register
    function is_writer;
        input [31:0] instr;
        begin
            case (instr[31:27])
                5'b01101, 5'b10010, 5'b10000, 5'b10001, 5'b10011: is_writer = 0; // control flow/nop
                5'bX, 5'b00101, 5'b10100, 5'b01111: is_writer = 0; // cmp, ret, st
                default: is_writer = 1;
            endcase
        end
    endfunction

    // Function to check if an instruction reads from a register
    function is_reader;
        input [31:0] instr;
        begin
            case (instr[31:27])
                5'bX, 5'b01101, 5'b10000, 5'b10001, 5'b10010, 5'b10011: is_reader = 0; // control flow/nop               
                default: is_reader = 1;
            endcase
        end
    endfunction

    always @(*) begin
        // WB to OF
        if (is_writer(instruction_WB) && 
        is_reader(instruction_OF)) begin
        
            WB_OF_rs1 = instruction_WB[25:22]== instruction_OF[21:18];
            WB_OF_rs2 = (instruction_OF[26] == 0) &&
                         instruction_WB[25:22]== instruction_OF[17:14];
                      
        end
        
        else begin
            WB_OF_rs1 = 0;
            WB_OF_rs2 = 0;
        end

        // MA/WB to EX
        if (is_reader(instruction_EX)) begin
        
            if (is_writer(instruction_WB)) begin
            
                MAWB_EX_rs1[1] = instruction_WB[25:22]== instruction_EX[21:18];
                MAWB_EX_rs2[1] = (instruction_EX[26] == 0 &&
                                 ((instruction_WB[25:22]== instruction_EX[17:14])));
                                 
                WB_EX_op2 = ((instruction_EX[26] == 0) && 
                            (instruction_WB[25:22]== instruction_EX[17:14])) ||
                            
                            (instruction_EX [31:27] == 5'b01111 &&
                             instruction_WB[25:22]== instruction_EX[25:22]);                 
            end 
            
            else begin
                MAWB_EX_rs1[1] = 0;
                MAWB_EX_rs2[1] = 0;
                WB_EX_op2 = 0;

            end

            if (is_writer(instruction_MA)) begin
            
                MAWB_EX_rs1[0] = (instruction_MA[25:22]== instruction_EX[21:18]);
                MAWB_EX_rs2[0] = (instruction_EX[26] == 0 &&
                                 ((instruction_MA[25:22] == instruction_EX[17:14])));                           
                                 
            end 
            
            else begin
                MAWB_EX_rs1[0] = 0;
                MAWB_EX_rs2[0] = 0;
            end
            
        end 
        
        else begin
            MAWB_EX_rs1 = 2'b00;
            MAWB_EX_rs2 = 2'b00;
        end

        // WB to MA
        if ((instruction_MA[31:27] == 5'b01110 && is_writer(instruction_WB)) ||
            (instruction_MA[31:27] == 5'b01111 && is_writer(instruction_WB))) begin
            
            WB_MA_rs2 = (instruction_WB[25:22]== instruction_MA[25:22]);
        end 
        
        else begin
            WB_MA_rs2 = 0;
        end
    end

endmodule
