Please act as a professional Verilog designer.

Implement an asynchronous FIFO with 2**LGFIFO entries of WIDTH bits.

Module name:
    afifo

Language:
    Verilog-2001

Clocks:
    i_wclk: Independent asynchronous clock (async to i_rclk).
    i_rclk: Independent asynchronous clock (async to i_wclk).

Resets:
    i_wr_reset_n: active-low.
    i_rd_reset_n: active-low.

Input ports:
    i_wclk: Clock.
    i_wr_reset_n: Active-low reset.
    i_wr: See Behavior.
    i_wr_data: Data payload.
    i_rclk: Clock.
    i_rd_reset_n: Active-low reset.
    i_rd: See Behavior.

Output ports:
    o_wr_full: FIFO full flag.
    o_rd_data: Data payload.
    o_rd_empty: FIFO empty flag.

Parameters:
    LGFIFO: Log2 of the number of FIFO entries.
    WIDTH: Payload width in bits.
    NFF: Implementation parameter. Choose a safe crossing yourself.
    WRITE_ON_POSEDGE: See Behavior.
    OPT_REGISTER_READS: See Behavior.

Behavior:
    - A write is accepted when i_wr is high and o_wr_full is low.
    - A read is accepted when i_rd is high and o_rd_empty is low.
    - Accepted data must return exactly once in write order.
    - Writes while full and reads while empty must not change stored data.
    - After reset, o_wr_full is low and o_rd_empty is high.
    - WRITE_ON_POSEDGE selects the write edge. OPT_REGISTER_READS selects whether reads are registered.
    - Do not emit FORMAL-only ports.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
