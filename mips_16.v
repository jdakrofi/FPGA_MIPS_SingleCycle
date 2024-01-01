
/*
* Top level module
* OUTPUTS
* alu_result: bus carrying the results of arithmetic and logical operations
* pc_out: the memory location of the next instruction
	
* INPUTS
* clk: clock
* reset: active high reset signal


*/
module mips_16(
	input clk, reset,
	output[15:0] pc_out, alu_result
);

	
	reg [15:0] pc_current;
	
	// busses carrying the memory locations of subsequent instructions 
	wire signed[15:0] pc_next, pc2;
	
	// bus carrying the next instruction to be exectued
	wire [15:0] instr;
	
	
	wire [1:0] reg_dst, mem_to_reg, alu_op;
	wire jump, branch, mem_read, mem_write, alu_src, reg_write;
	
	
	wire [2:0] reg_write_dest;
	wire [15:0] reg_write_data;
	wire [2:0] reg_read_addr_1;
	wire [15:0] reg_read_data_1;
	wire [2:0] reg_read_addr_2;
	wire [15:0] reg_read_data_2;
	
	wire [15:0] sign_ext_im, read_data2, zero_ext_im, imm_ext;
	wire JRControl;
	wire [2:0] ALU_Control;
	wire [15:0] ALU_out;
	wire zero_flag;
	
	
	wire signed[15:0] im_shift_1, PC_j, PC_beq, PC_4beq, PC_4beqj, PC_jr;
	wire beq_control;
	wire [14:0] jump_shift_1;
	wire [15:0] mem_read_data;
	wire [15:0] no_sign_ext;
	wire sign_or_zero;


	always@(posedge clk or posedge reset)
	begin
		if(reset) pc_current <= 16'd0;
		else pc_current <= pc_next;	
	end
	
	//obtain the next instruction from memory
	instruction_memory instr_mem(.pc(pc_current), .instruction(instr));
	
	// determine  what type of instruction it is and activate the appropriate  operation triggers and registers
	control control_unit(reset, instr[15:13], reg_dst, mem_to_reg, alu_op, jump, branch, mem_read,
	mem_write, alu_src, reg_write, sign_or_zero);
	
	
	// the module handle read and write operations to the register file
	register_file reg_file( clk, reset, reg_write, reg_write_dest, reg_write_data, 
	reg_read_addr_1, reg_read_data_1, reg_read_addr_2, reg_read_data_2);
	
	// this module handles requests to jump to another instruction
	JR_Control JRControl_unit(alu_op, instr[3:0], JRControl);
	
	// this module handles request to execute logical and arithemtic operations determining which operation is being requested
	ALUControl ALU_Control_unit(alu_op, instr[3:0], ALU_Control);
	
	// logical and arithmetic operations are exectued in this module
	alu alu_unit(re_read_data_1, read_data2, ALU_Control, ALU_out, zero_flag);
	
	
	// requested to read and writed data to memory
	data_memory datamem(clk, ALU_out, reg_read_data_2, mem_write, mem_read, mem_read_data);
	
	// pc +2
	assign pc2 = pc_current + 16'd2;
	
	// jump shift left 1
	assign jump_shift_1 = {instr[13:0], 1'b0};
	
	// multiplexer regdest
	assign reg_write_dest = (reg_dst==2'b10) ? 3'b111: ((reg_dst==2'b01) ? instr[6:4]:instr[9:7]);
	
	// register file
	assign reg_read_addr_1 = instr[12:10];
	assign reg_read_addr_2 = instr[9:7];
	
	// sign extend
	assign sign_ext_im = {{9{instr[6]}}, instr[6:0]};
	assign zero_ext_im = {{9{1'b0}}, instr[6:0]};
	assign imm_ext =  (sign_or_zero==1'b1) ? sign_ext_im : zero_ext_im;
	
	
	// multiplexer alu_src
	assign read_data2 = (alu_src==1'b1) ? imm_ext : reg_read_data_2;
	// immediate shift 1
	assign im_shift_1 = {imm_ext[14:0], 1'b0};
	assign no_sign_ext = ~(im_shift_1) + 1'b1;
	
	// PC beq add
	assign PC_beq = (im_shift_1[15] == 1'b1) ? (pc2 - no_sign_ext) : (pc2 + im_shift_1);
	// branch equal control
	assign beq_control = branch & zero_flag;
	// PC branch equal 
	assign PC_4beq = (beq_control==1'b1) ? PC_beq : pc2;
	//PC jump
	assign PC_j = {pc2[15], jump_shift_1};
	// PC_$ branch equal jump
	assign PC_4beqj = (jump == 1'b1) ? PC_j : PC_4beq;
	// PC_jump_return
	assign PC_jr = reg_read_data_1;
	// pc next
	assign pc_next = (JRControl==1'b1) ? PC_jr : PC_4beqj;
	
	// write back
	assign reg_write_data = (mem_to_reg == 2'b10) ? pc2: ((mem_to_reg == 2'b01) ? mem_read_data: ALU_out);
	
	// output
	assign pc_out = pc_current;
	assign alu_result = ALU_out;
	
	
endmodule