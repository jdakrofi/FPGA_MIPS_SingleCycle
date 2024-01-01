/*
 This module creates a memory array this is used to store data (the results of operations).
 This memory array has 8 memory locations and can store 16 bit per address.
 Data is stored in the array when reg_write_en==1
 Data is read from the array when an address is provided by either the reg_read_addr_1 or reg_read_addr_2 inputs busses. 

*/
module register_file(
	input  clk, rst, reg_write_en,
	input [2:0] reg_write_dest,
	input [15:0] reg_write_data,
	input [2:0] reg_read_addr_1,
	output [15:0] reg_read_data_1,
	input [2:0] reg_read_addr_2,
	output [15:0] reg_read_data_2
);
	
	reg [15:0] reg_array [7:0];
	
	always@(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			reg_array[0] <= 16'b0;
			reg_array[1] <= 16'b0;
			reg_array[2] <= 16'b0;
			reg_array[3] <= 16'b0;
			reg_array[4] <= 16'b0;
			reg_array[5] <= 16'b0;
			reg_array[6] <= 16'b0;
			reg_array[7] <= 16'b0;
		end
		
		else
		begin
			if(reg_write_en) reg_array[reg_write_dest] <= reg_write_data;
		end
	end

	assign reg_read_data_1 = (reg_read_addr_1 == 0) ? 16'b0 : reg_array[reg_read_addr_1];
	assign reg_read_data_2 = (reg_read_addr_2 == 0) ? 16'b0 : reg_array[reg_read_addr_2];
endmodule