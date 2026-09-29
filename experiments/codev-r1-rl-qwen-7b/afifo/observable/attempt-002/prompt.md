Please act as a professional Verilog designer.

Implement an asynchronous FIFO with 2**LGFIFO entries of WIDTH bits.

i_wclk and i_rclk are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Queue words across the write and read sides, in order. Honor the full/empty flags, reset behavior, and the selected write-edge and read-timing options.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);
