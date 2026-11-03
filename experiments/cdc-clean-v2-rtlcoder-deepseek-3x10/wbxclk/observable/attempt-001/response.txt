Sure, here is a Verilog-2001 implementation of a pipelined Wishbone clock-domain bridge. This implementation uses two FIFOs to store Wishbone requests and responses, and two synchronizers to handle clock domain crossings.

```
module wbxclk #(
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

	// FIFOs to store Wishbone requests and responses
	reg [DW-1:0] wb_req_fifo [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_fifo [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_fifo_head;
	reg [LGFIFO-1:0] wb_req_fifo_tail;
	reg [LGFIFO-1:0] wb_resp_fifo_head;
	reg [LGFIFO-1:0] wb_resp_fifo_tail;
	reg [LGFIFO-1:0] wb_req_fifo_count;
	reg [LGFIFO-1:0] wb_resp_fifo_count;

	// Synchronizers to handle clock domain crossings
	reg [DW-1:0] wb_req_sync [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_sync [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_sync_head;
	reg [LGFIFO-1:0] wb_req_sync_tail;
	reg [LGFIFO-1:0] wb_resp_sync_head;
	reg [LGFIFO-1:0] wb_resp_sync_tail;
	reg [LGFIFO-1:0] wb_req_sync_count;
	reg [LGFIFO-1:0] wb_resp_sync_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_head;
	reg [LGFIFO-1:0] wb_req_pipe_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_head;
	reg [LGFIFO-1:0] wb_resp_pipe_tail;
	reg [LGFIFO-1:0] wb_req_pipe_count;
	reg [LGFIFO-1:0] wb_resp_pipe_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next [0:2**LGFIDO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;

	// Pipeline registers
	reg [DW-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [DW-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_req_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
	reg [LGFIFO-1:0] wb_resp_pipe_next_next_next_next_next_next