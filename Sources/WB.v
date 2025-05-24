module WB(
    input 
    [31:0] PC_in, instruction_in,
    [21:0] ControlWord_in,
    [31:0] aluResult_in,
    [31:0] ldResult_in,
    
    output wbEnable,
    [31:0] instruction_WB,
    reg [3:0] wbAddr,
    reg [31:0]wbData
    );
    
    assign instruction_WB= instruction_in;    
    assign wbEnable= ControlWord_in[20];
    
    always @(*) begin
    
    wbAddr [3:0]= ControlWord_in[15]? 4'b1111: instruction_in[25:22];
    
    case ({ControlWord_in[11],ControlWord_in[15]})
    
    default: wbData= 32'bX ;
    2'b00:   wbData= aluResult_in;
    2'b10:   wbData= ldResult_in;
    2'b01:   wbData= (PC_in+1);
    
    endcase
    end
endmodule
