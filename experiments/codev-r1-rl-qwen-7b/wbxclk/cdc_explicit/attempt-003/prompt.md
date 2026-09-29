Please act as a professional Verilog designer.

Implement a pipelined Wishbone clock-domain bridge.

Module name:
    wbxclk

Language:
    Verilog-2001

Clocks:
    i_wb_clk: Independent asynchronous clock (async to i_xclk_clk).
    i_xclk_clk: Independent asynchronous clock (async to i_wb_clk).

Resets:
    i_reset: active-high.
    bus_abort: reset.

Input ports:
    i_wb_clk: Clock.
    i_reset: Active-high reset.
    i_wb_cyc: See Behavior.
    i_wb_stb: See Behavior.
    i_wb_we: See Behavior.
    i_wb_addr: Address.
    i_wb_data: Data payload.
    i_wb_sel: See Behavior.
    i_xclk_clk: Clock.
    i_xclk_stall: Clock.
    i_xclk_ack: Clock.
    i_xclk_data: Clock.
    i_xclk_err: Clock.

Output ports:
    o_wb_stall: See Behavior.
    o_wb_ack: See Behavior.
    o_wb_data: Data payload.
    o_wb_err: See Behavior.
    o_xclk_cyc: Clock.
    o_xclk_stb: Clock.
    o_xclk_we: Clock.
    o_xclk_addr: Clock.
    o_xclk_data: Clock.
    o_xclk_sel: Clock.

Parameters:
    AW: See Behavior.
    DW: See Behavior.
    LGFIFO: Log2 of the number of FIFO entries.

Behavior:
    - Accept pipelined Wishbone cycles on the i_wb_* ports.
    - Forward each accepted cycle exactly once to the o_xclk_* ports.
    - Return ack/err/data to the source.
    - o_wb_stall must go high when the crossing cannot accept another cycle.
    - Reset must idle both buses and must not create a destination cycle.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module	wbxclk #(
		parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_wb_clk, i_reset,
		input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input	wire	[(AW-1):0]	i_wb_addr,
		input	wire	[(DW-1):0]	i_wb_data,
		input	wire	[(DW/8-1):0]	i_wb_sel,
		output	wire			o_wb_stall,
		output	reg			o_wb_ack,
		output	reg	[(DW-1):0]	o_wb_data,
		output	reg			o_wb_err,
		input	wire			i_xclk_clk,
		output	reg			o_xclk_cyc,
		output	reg			o_xclk_stb,
		output	reg			o_xclk_we,
		output	reg	[(AW-1):0]	o_xclk_addr,
		output	reg	[(DW-1):0]	o_xclk_data,
		output	reg	[(DW/8-1):0]	o_xclk_sel,
		input	wire			i_xclk_stall,
		input	wire			i_xclk_ack,
		input	wire	[(DW-1):0]	i_xclk_data,
		input	wire			i_xclk_err
	);
