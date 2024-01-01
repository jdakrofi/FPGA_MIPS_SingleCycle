/*
 This module takes two operands (a and b) as inputs and performs a particular operation on them
 depending on the value of the alu_control signal. The module outputs the answer on the result bus.
 The zero output wire is used to indicated with the result of the operation carried out was equal to
 zero.
*/

module alu(
	input [15:0] a,
	input [15:0] b,
	input [2:0] alu_control,
	output reg [15:0] result,
	output zero
);

	always@(*)
	begin
		case(alu_control)
			3'b000: result = a + b;
			3'b001: result = a - b;
			3'b010: result = a & b;
			3'b011: result = a | b;
			3'b100: result = (a<b) ? 16'd1 : 16'd0;
			default: result = a + b;
		endcase
	end
	
	assign zero = (result==16'd0) ? 1'b1:1'b0;
	
endmodule