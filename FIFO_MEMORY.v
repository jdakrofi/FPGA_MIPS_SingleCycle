/*
* Top level module
* OUTPUTS
* data_out: bus carrying out data read from FIFO_MEMORY
* fifo_full: high when FIFO_MEMORY is full
* fifo_empty: high when FIFO_MEMORY is empty
* fifo_overflow: high when FIFO_MEMORY is full and still writing data into FIFO, else it is low
* fifo_underflow: high when FIFO_MEMORY is empty and still reading data from FIFO, else it is low.
* fifo_threshold: high when then amount of data in FIFO_MEMORY is less than a 
	specific threshold, else it is low.
	
* INPUTS
* clk: clock
* rst_n: active low reset signal
* wr: external write request trigger. Used to indicate that data is to be written into FIFO_memory.
* rd: external read request trigger. Used to indicated that data is to be read from FIFO_memory.
* data_in: bus carrying data to be written into FIFO_MEMORY

*/

module FIFO_MEMORY(data_out, fifo_full, fifo_empty, fifo_threshold, fifo_overflow, 
fifo_underflow, clk, rst_n, wr, rd, data_in);

input wr, rd, clk, rst_n;
input [7:0] data_in;
output [7:0] data_out;
output fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow;

// pointers to locations in memory array where data is written to or read from
wire [4:0] wptr, rptr;

// write enable and read enable signals
wire fifo_we, fifo_rd;

write_pointer top1(wptr, fifo_we, wr, fifo_full, clk, rst_n);

read_pointer top2(rptr, fifo_rd, rd, fifo_empty, clk, rst_n);

memory_array top3(data_out, data_in, clk, fifo_we, wptr, rptr);

status_signal top4(fifo_full, fifo_empty, fifo_threshold, fifo_overflow,
fifo_underflow, wr, rd, fifo_we, fifo_rd, wptr, rptr, clk, rst_n);

endmodule

/* 
  In this module the pointer (wptr) to the next memory location where data 
  is to be written is updated only if the memory array is not full (~fifo_full) and
  there is a external write request (wr).

  The pointer is reset by an asynchronous active low reset signal
*/
module write_pointer(wptr, fifo_we, wr, fifo_full, clk, rst_n);
	input wr, fifo_full, clk, rst_n;
	output[4:0] wptr;
	output fifo_we;
	reg[4:0] wptr;
	
	assign fifo_we = (~fifo_full) & wr;
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n) wptr <= 5'b000000;
		else if(fifo_we) wptr <= wptr + 5'b000001;
		else wptr <= wptr;
	end
endmodule


/* 
  In this module the pointer (rptr) to the next memory location where data 
  is to be read from is updated only if the memory array is not full (~fifo_empty) and
  there is a external read request (rd). 

  The pointer is reset by a synchronous active low reset signal
*/
module read_pointer(rptr, fifo_rd, rd, fifo_empty, clk, rst_n);
	input rd, fifo_empty, clk, rst_n;
	output [7:0] rptr;
	output fifo_rd;
	reg[4:0] rptr;
	assign fifo_rd = (~fifo_empty) & rd;
	
	always@(posedge clk)
	begin
		if(~rst_n) rptr <= 5'b000000;
		else if (fifo_rd) rptr <=rptr + 5'b000001;
		else rptr<= rptr;
	end
endmodule


/*
	In this module data is written into memory if fifo_we is high
	and data to be read onto the data_out.	
*/
module memory_array(data_out, data_in, clk, fifo_we, wptr, rptr);
input [7:0] data_in;
input clk, fifo_we;
input [4:0] wptr, rptr;
output [7:0] data_out;
reg[7:0] data_out2[15:0];
wire[7:0] data_out;

always@(posedge clk)
	begin
		if(fifo_we) data_out2[wptr[3:0]] <= data_in;
	end
	
	assign data_out = data_out2[rptr[3:0]];

endmodule

/*
	This module computes the values of the following signals :
	fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow.
	fifo_full determines whether the memory array is full with data or not.
	fifo-full is equal to one only if we attempt to access an address location beyond 4'b1111.
	fifo_empty determines whether the memory array is devoid of data or not.
	fifo-empty is equal to one only if we attempt to access an address location beyond 4'b0000.
	fifo_threshold determines whether the memory array is close to being filled.
	fifo_threshold is equal to one only if we attempt to access an address location beyond 4'b1000.
	fifo_overflow is set to one if  the memory array is full and the write trigger (wr=1) and an
	attempt hasn't been made to read from memory. Otherwise fifo_overflow is set to zero
	fifo_underflow is set to one if  the memory array is empty and the read trigger (rd=1) and an
	attempt hasn't been made to write to memory. Otherwise fifo_underflow is set to zero.	
	
*/
module status_signal(fifo_full, fifo_empty, fifo_threshold, fifo_overflow, 
fifo_underflow, wr, rd, fifo_we, fifo_rd, wptr, rptr, clk, rst_n);

input wr, rd, fifo_we, fifo_rd, clk, rst_n;
input[4:0] wptr, rptr;
output fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow;
wire fbit_comp, overflow_set, underflow_set;
wire pointer_equal;
wire [4:0] pointer_result;
reg fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow;

assign fbit_comp = wptr[4] ^ rptr[4];
assign pointer_equal = (wptr[3:0] - rptr[3:0]) ? 0:1;
assign pointer_result = wptr[4:0] - rptr[4:0];
assign overflow_set = fifo_full & wr;
assign underflow_set = fifo_empty & rd;

always@(*)
begin
	fifo_full = fbit_comp & pointer_equal;
	fifo_empty = (~fbit_comp) & pointer_equal;
	fifo_threshold = (pointer_result[4] || pointer_result[3]) ? 1:0;
end


always@(posedge clk or negedge rst_n)
begin
	if(~rst_n) fifo_overflow<=0;
	else if((overflow_set==1) && (fifo_rd==0)) fifo_overflow <=1;
	else if(fifo_rd) fifo_overflow<=0;
	else fifo_overflow<=fifo_overflow;
end


always@(posedge clk or negedge rst_n)
begin
	if(~rst_n) fifo_underflow<=0;
	else if((underflow_set==1) && (fifo_we==0)) fifo_underflow<=1;
	else if(fifo_we) fifo_underflow<=0;
	else fifo_underflow <= fifo_underflow;
end

endmodule

