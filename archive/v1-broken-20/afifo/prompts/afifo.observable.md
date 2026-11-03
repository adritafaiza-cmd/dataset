Please act as a professional Verilog designer.

Implement an asynchronous FIFO with 2**LGFIFO entries of WIDTH bits.

i_wclk and i_rclk are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Queue words across the write and read sides, in order. Storage must accept 2**LGFIFO writes before any read, and o_wr_full must be high only when that storage is occupied. A write while full must not change stored data. A read while empty must not change o_rd_data or drop a later word. While write reset is asserted, o_wr_full is low. While read reset is asserted, o_rd_empty is high. o_rd_empty may be high while words remain stored: present one stored word at a time, and empty may return high after a read until the next stored word becomes visible. Honor the selected write edge and whether reads are registered.

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
