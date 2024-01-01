/*
 In this module the kind of arithmetic or logical operation to be carried out
 is determine be combining the ALUop and Function signals. See alu.v to determine
 which operations correspoend to the each possible ALU_COntrol value.
*/

module ALUControl(
	input [1:0] ALUOp,
	input [3:0] Function,
	output reg [2:0] ALU_Control
);

	//reg ALU_Control;
	wire [5:0] ALUControlIn = {ALUOp, Function};
	
	always@(ALUControlIn)
		casex(ALUControlIn)
			6'b11xxxx:ALU_Control=3'b000;
			6'b10xxxx:ALU_Control=3'b100;
			6'b01xxxx:ALU_Control=3'b001;
			6'b000000:ALU_Control=3'b000;
			6'b000001:ALU_Control=3'b001;
			6'b000010:ALU_Control=3'b010;
			6'b000011:ALU_Control=3'b011;
			6'b000100:ALU_Control=3'b100;
			default: ALU_Control=3'b000;
		endcase
		
endmodule

module JR_Control(
	input[1:0] alu_op,
	input[3:0] funct,
	output JRControl
);

assign JRControl = ({alu_op,funct}==6'b001000) ? 1'b1 : 1'b0;
endmodule