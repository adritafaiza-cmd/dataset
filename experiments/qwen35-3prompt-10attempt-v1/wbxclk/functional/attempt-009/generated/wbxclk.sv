module wbxclk #(
	parameter	AW=32,
		parameter	DW=32,
		parameter	LGFIFO = 5
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

	localparam	DEPTH = 1 << LGFIFO;

	// Wishbone Side FIFO (Input)
	// Stores incoming WB cycles to be forwarded to XCLK domain
	wbx_fifo #(
		.AW		= AW,
		.DW		= DW,
		.DEP		= DEPTH,
		.RST		= i_reset,
		.CLK		= i_wb_clk,
		.I_CYC	= i_wb_cyc,
		.I_STB	= i_wb_stb,
		.I_WE	= i_wb_we,
		.I_ADDR	= i_wb_addr,
		.I_DATA	= i_wb_data,
		.I_SEL	= i_wb_sel,
		.O_STALL	= o_wb_stall,
		.O_ACK	= o_wb_ack,
		.O_DATA	= o_wb_data,
		.O_ERR	= o_wb_err
	) u_wb_fifo (
		.I_CYC		-> i_wb_cyc,
		.I_STB		-> i_wb_stb,
		.I_WE		-> i_wb_we,
		.I_ADDR		-> i_wb_addr,
		.I_DATA		-> i_wb_data,
		.I_SEL		-> i_wb_sel,
		.O_STALL		-> o_wb_stall,
		.O_ACK		-> o_wb_ack,
		.O_DATA		-> o_wb_data,
		.O_ERR		-> o_wb_err
	);

	// XCLK Side FIFO (Output)
	// Stores outgoing XCLK cycles to be returned to WB domain
	wbx_fifo #(
		.AW		= AW,
		.DW		= DW,
		.DEP		= DEPTH,
		.RST		= i_reset,
		.CLK		= i_xclk_clk,
		.I_CYC	= i_xclk_cyc,
		.I_STB	= i_xclk_stb,
		.I_WE	= i_xclk_we,
		.I_ADDR	= i_xclk_addr,
		.I_DATA	= i_xclk_data,
		.I_SEL	= i_xclk_sel,
		.O_STALL	= o_xclk_stall,
		.O_ACK	= o_xclk_ack,
		.O_DATA	= o_xclk_data,
		.O_ERR	= o_xclk_err
	) u_xclk_fifo (
		.I_CYC		-> o_xclk_cyc,
		.I_STB		-> o_xclk_stb,
		.I_WE		-> o_xclk_we,
		.I_ADDR		-> o_xclk_addr,
		.I_DATA		-> o_xclk_data,
		.I_SEL		-> o_xclk_sel,
		.O_STALL		-> o_xclk_stall,
		.O_ACK		-> o_xclk_ack,
		.O_DATA		-> o_xclk_data,
		.O_ERR		-> o_xclk_err
	);

	// Cross-domain handshake logic
	// This block handles the asynchronous crossing between WB and XCLK domains
	// It ensures that cycles are forwarded correctly and stalls are propagated
	
	wire wb_stall;
	wire xclk_stall;
	
	// Generate stall signals based on FIFO full/empty conditions
	// WB side stall: FIFO is full (cannot accept more cycles)
	assign wb_stall = u_wb_fifo.o_stall;
	
	// XCLK side stall: FIFO is empty (cannot send more cycles)
	assign xclk_stall = u_xclk_fifo.o_stall;
	
	// Cross-domain handshake logic
	// When WB wants to send a cycle, it checks if XCLK FIFO has space
	// When XCLK wants to send a cycle, it checks if WB FIFO has data
	
	// Simple asynchronous FIFO crossing using handshaking
	// We use a simple state machine to handle the crossing
	
	reg [LGFIFO-1:0] wb_fifo_ptr;
	reg [LGFIFO-1:0] xclk_fifo_ptr;
	reg wb_fifo_wr_en;
	reg xclk_fifo_rd_en;
	reg wb_fifo_rd_en;
	reg xclk_fifo_wr_en;
	reg wb_stb_valid;
	reg xclk_stb_valid;
	reg wb_cyc_valid;
	reg xclk_cyc_valid;
	reg wb_ack_valid;
	reg xclk_ack_valid;
	reg wb_err_valid;
	reg xclk_err_valid;
	reg wb_data_valid;
	reg xclk_data_valid;
	reg wb_sel_valid;
	reg xclk_sel_valid;
	reg wb_addr_valid;
	reg xclk_addr_valid;
	reg wb_we_valid;
	reg xclk_we_valid;
	
	// WB Side: Capture incoming cycles and forward to XCLK FIFO
	// When WB FIFO is not full, capture the cycle and forward to XCLK FIFO
	// When XCLK FIFO is full, stall WB
	
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_ptr <= '0;
			wb_stb_valid <= 1'b0;
			wb_cyc_valid <= 1'b0;
			wb_ack_valid <= 1'b0;
			wb_err_valid <= 1'b0;
			wb_data_valid <= 1'b0;
			wb_sel_valid <= 1'b0;
			wb_addr_valid <= 1'b0;
			wb_we_valid <= 1'b0;
		end else begin
			// Capture WB cycle if valid and FIFO not full
			if (i_wb_cyc && i_wb_stb && !wb_stall) begin
				wb_stb_valid <= 1'b1;
				wb_cyc_valid <= 1'b1;
				wb_ack_valid <= 1'b0;
				wb_err_valid <= 1'b0;
				wb_data_valid <= 1'b1;
				wb_sel_valid <= 1'b1;
				wb_addr_valid <= 1'b1;
				wb_we_valid <= 1'b1;
			end else begin
				wb_stb_valid <= 1'b0;
				wb_cyc_valid <= 1'b0;
				wb_ack_valid <= 1'b0;
				wb_err_valid <= 1'b0;
				wb_data_valid <= 1'b0;
				wb_sel_valid <= 1'b0;
				wb_addr_valid <= 1'b0;
				wb_we_valid <= 1'b0;
			end
		end
	end
	
	// XCLK Side: Capture outgoing cycles and forward to WB FIFO
	// When XCLK FIFO is not empty, capture the cycle and forward to WB FIFO
	// When WB FIFO is empty, stall XCLK
	
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_ptr <= '0;
			xclk_stb_valid <= 1'b0;
			xclk_cyc_valid <= 1'b0;
			xclk_ack_valid <= 1'b0;
			xclk_err_valid <= 1'b0;
			xclk_data_valid <= 1'b0;
			xclk_sel_valid <= 1'b0;
			xclk_addr_valid <= 1'b0;
			xclk_we_valid <= 1'b0;
		end else begin
			// Capture XCLK cycle if valid and FIFO not empty
			if (i_xclk_cyc && i_xclk_stb && !xclk_stall) begin
				xclk_stb_valid <= 1'b1;
				xclk_cyc_valid <= 1'b1;
				xclk_ack_valid <= 1'b0;
				xclk_err_valid <= 1'b0;
				xclk_data_valid <= 1'b1;
				xclk_sel_valid <= 1'b1;
				xclk_addr_valid <= 1'b1;
				xclk_we_valid <= 1'b1;
			end else begin
				xclk_stb_valid <= 1'b0;
				xclk_cyc_valid <= 1'b0;
				xclk_ack_valid <= 1'b0;
				xclk_err_valid <= 1'b0;
				xclk_data_valid <= 1'b0;
				xclk_sel_valid <= 1'b0;
				xclk_addr_valid <= 1'b0;
				xclk_we_valid <= 1'b0;
			end
		end
	end
	
	// Cross-domain handshake: Forward WB cycle to XCLK FIFO
	// When WB FIFO has a valid cycle and XCLK FIFO has space, forward it
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_wr_en <= 1'b0;
		end else begin
			// Forward WB cycle to XCLK FIFO if XCLK FIFO has space
			if (wb_stb_valid && !u_wb_fifo.o_stall) begin
				wb_fifo_wr_en <= 1'b1;
			end else begin
				wb_fifo_wr_en <= 1'b0;
			end
		end
	end
	
	// Cross-domain handshake: Forward XCLK cycle to WB FIFO
	// When XCLK FIFO has a valid cycle and WB FIFO has space, forward it
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_rd_en <= 1'b0;
		end else begin
			// Forward XCLK cycle to WB FIFO if WB FIFO has space
			if (xclk_stb_valid && !u_xclk_fifo.o_stall) begin
				xclk_fifo_rd_en <= 1'b1;
			end else begin
				xclk_fifo_rd_en <= 1'b0;
			end
		end
	end
	
	// Generate output signals based on FIFO status
	// WB side outputs are driven by the WB FIFO
	// XCLK side outputs are driven by the XCLK FIFO
	
	assign o_wb_stall = u_wb_fifo.o_stall;
	assign o_wb_ack = u_wb_fifo.o_ack;
	assign o_wb_data = u_wb_fifo.o_data;
	assign o_wb_err = u_wb_fifo.o_err;
	
	assign o_xclk_cyc = u_xclk_fifo.o_cyc;
	assign o_xclk_stb = u_xclk_fifo.o_stb;
	assign o_xclk_we = u_xclk_fifo.o_we;
	assign o_xclk_addr = u_xclk_fifo.o_addr;
	assign o_xclk_data = u_xclk_fifo.o_data;
	assign o_xclk_sel = u_xclk_fifo.o_sel;
	
	// Cross-domain handshake: Handle stall propagation
	// When XCLK FIFO is full, stall WB
	// When WB FIFO is empty, stall XCLK
	
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_stall <= 1'b0;
		end else begin
			// Stall WB if XCLK FIFO is full
			o_xclk_stall <= u_xclk_fifo.o_stall;
		end
	end
	
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 1'b0;
		end else begin
			// Stall XCLK if WB FIFO is empty
			o_wb_stall <= u_wb_fifo.o_stall;
		end
	end
	
endmodule

module wbxclk #(
	parameter	AW=32,
	parameter	DW=32,
	parameter	LGFIFO = 5
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

	localparam	DEPTH = 1 << LGFIFO;

	// Wishbone Side FIFO (Input)
	wbx_fifo #(
		.AW		= AW,
		.DW		= DW,
		.DEP		= DEPTH,
		.RST		= i_reset,
		.CLK		= i_wb_clk,
		.I_CYC	= i_wb_cyc,
		.I_STB	= i_wb_stb,
		.I_WE	= i_wb_we,
		.I_ADDR	= i_wb_addr,
		.I_DATA	= i_wb_data,
		.I_SEL	= i_wb_sel,
		.O_STALL	= o_wb_stall,
		.O_ACK	= o_wb_ack,
		.O_DATA	= o_wb_data,
		.O_ERR	= o_wb_err
	) u_wb_fifo (
		.I_CYC		-> i_wb_cyc,
		.I_STB		-> i_wb_stb,
		.I_WE		-> i_wb_we,
		.I_ADDR		-> i_wb_addr,
		.I_DATA		-> i_wb_data,
		.I_SEL		-> i_wb_sel,
		.O_STALL		-> o_wb_stall,
		.O_ACK		-> o_wb_ack,
		.O_DATA		-> o_wb_data,
		.O_ERR		-> o_wb_err
	);

	// XCLK Side FIFO (Output)
	wbx_fifo #(
		.AW		= AW,
		.DW		= DW,
		.DEP		= DEPTH,
		.RST		= i_reset,
		.CLK		= i_xclk_clk,
		.I_CYC	= i_xclk_cyc,
		.I_STB	= i_xclk_stb,
		.I_WE	= i_xclk_we,
		.I_ADDR	= i_xclk_addr,
		.I_DATA	= i_xclk_data,
		.I_SEL	= i_xclk_sel,
		.O_STALL	= o_xclk_stall,
		.O_ACK	= o_xclk_ack,
		.O_DATA	= o_xclk_data,
		.O_ERR	= o_xclk_err
	) u_xclk_fifo (
		.I_CYC		-> o_xclk_cyc,
		.I_STB		-> o_xclk_stb,
		.I_WE		-> o_xclk_we,
		.I_ADDR		-> o_xclk_addr,
		.I_DATA		-> o_xclk_data,
		.I_SEL		-> o_xclk_sel,
		.O_STALL		-> o_xclk_stall,
		.O_ACK		-> o_xclk_ack,
		.O_DATA		-> o_xclk_data,
		.O_ERR		-> o_xclk_err
	);

	// Cross-domain handshake logic
	// This block handles the asynchronous crossing between WB and XCLK domains
	
	reg [LGFIFO-1:0] wb_fifo_ptr;
	reg [LGFIFO-1:0] xclk_fifo_ptr;
	reg wb_fifo_wr_en;
	reg xclk_fifo_rd_en;
	reg wb_fifo_rd_en;
	reg xclk_fifo_wr_en;
	reg wb_stb_valid;
	reg xclk_stb_valid;
	reg wb_cyc_valid;
	reg xclk_cyc_valid;
	reg wb_ack_valid;
	reg xclk_ack_valid;
	reg wb_err_valid;
	reg xclk_err_valid;
	reg wb_data_valid;
	reg xclk_data_valid;
	reg wb_sel_valid;
	reg xclk_sel_valid;
	reg wb_addr_valid;
	reg xclk_addr_valid;
	reg wb_we_valid;
	reg xclk_we_valid;
	
	// WB Side: Capture incoming cycles and forward to XCLK FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_ptr <= '0;
			wb_stb_valid <= 1'b0;
			wb_cyc_valid <= 1'b0;
			wb_ack_valid <= 1'b0;
			wb_err_valid <= 1'b0;
			wb_data_valid <= 1'b0;
			wb_sel_valid <= 1'b0;
			wb_addr_valid <= 1'b0;
			wb_we_valid <= 1'b0;
		end else begin
			// Capture WB cycle if valid and FIFO not full
			if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
				wb_stb_valid <= 1'b1;
				wb_cyc_valid <= 1'b1;
				wb_ack_valid <= 1'b0;
				wb_err_valid <= 1'b0;
				wb_data_valid <= 1'b1;
				wb_sel_valid <= 1'b1;
				wb_addr_valid <= 1'b1;
				wb_we_valid <= 1'b1;
			end else begin
				wb_stb_valid <= 1'b0;
				wb_cyc_valid <= 1'b0;
				wb_ack_valid <= 1'b0;
				wb_err_valid <= 1'b0;
				wb_data_valid <= 1'b0;
				wb_sel_valid <= 1'b0;
				wb_addr_valid <= 1'b0;
				wb_we_valid <= 1'b0;
			end
		end
	end
	
	// XCLK Side: Capture outgoing cycles and forward to WB FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_ptr <= '0;
			xclk_stb_valid <= 1'b0;
			xclk_cyc_valid <= 1'b0;
			xclk_ack_valid <= 1'b0;
			xclk_err_valid <= 1'b0;
			xclk_data_valid <= 1'b0;
			xclk_sel_valid <= 1'b0;
			xclk_addr_valid <= 1'b0;
			xclk_we_valid <= 1'b0;
		end else begin
			// Capture XCLK cycle if valid and FIFO not empty
			if (i_xclk_cyc && i_xclk_stb && !o_xclk_stall) begin
				xclk_stb_valid <= 1'b1;
				xclk_cyc_valid <= 1'b1;
				xclk_ack_valid <= 1'b0;
				xclk_err_valid <= 1'b0;
				xclk_data_valid <= 1'b1;
				xclk_sel_valid <= 1'b1;
				xclk_addr_valid <= 1'b1;
				xclk_we_valid <= 1'b1;
			end else begin
				xclk_stb_valid <= 1'b0;
				xclk_cyc_valid <= 1'b0;
				xclk_ack_valid <= 1'b0;
				xclk_err_valid <= 1'b0;
				xclk_data_valid <= 1'b0;
				xclk_sel_valid <= 1'b0;
				xclk_addr_valid <= 1'b0;
				xclk_we_valid <= 1'b0;
			end
		end
	end
	
	// Cross-domain handshake: Forward WB cycle to XCLK FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_wr_en <= 1'b0;
		end else begin
			// Forward WB cycle to XCLK FIFO if XCLK FIFO has space
			if (wb_stb_valid && !u_xclk_fifo.o_stall) begin
				wb_fifo_wr_en <= 1'b1;
			end else begin
				wb_fifo_wr_en <= 1'b0;
			end
		end
	end
	
	// Cross-domain handshake: Forward XCLK cycle to WB FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_rd_en <= 1'b0;
		end else begin
			// Forward XCLK cycle to WB FIFO if WB FIFO has space
			if (xclk_stb_valid && !u_wb_fifo.o_stall) begin
				xclk_fifo_rd_en <= 1'b1;
			end else begin
				xclk_fifo_rd_en <= 1'b0;
			end
		end
	end
	
	// Generate output signals based on FIFO status
	assign o_wb_stall = u_wb_fifo.o_stall;
	assign o_wb_ack = u_wb_fifo.o_ack;
	assign o_wb_data = u_wb_fifo.o_data;
	assign o_wb_err = u_wb_fifo.o_err;
	
	assign o_xclk_cyc = u_xclk_fifo.o_cyc;
	assign o_xclk_stb = u_xclk_fifo.o_stb;
	assign o_xclk_we = u_xclk_fifo.o_we;
	assign o_xclk_addr = u_xclk_fifo.o_addr;
	assign o_xclk_data = u_xclk_fifo.o_data;
	assign o_xclk_sel = u_xclk_fifo.o_sel;
	
endmodule

module wbxclk #(
	parameter	AW=32,
	parameter	DW=32,
	parameter	LGFIFO = 5
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

	localparam	DEPTH = 1 << LGFIFO;

	// Wishbone Side FIFO (Input)
	wbx_fifo #(
		.AW		= AW,
		.DW		= DW,
		.DEP		= DEPTH,
		.RST		= i_reset,
		.CLK		= i_wb_clk,
		.I_CYC	= i_wb_cyc,
		.I_STB	= i_wb_stb,
		.I_WE	= i_wb_we,
		.I_ADDR	= i_wb_addr,
		.I_DATA	= i_wb_data,
		.I_SEL	= i_wb_sel,
		.O_STALL	= o_wb_stall,
		.O_ACK	= o_wb_ack,
		.O_DATA	= o_wb_data,
		.O_ERR	= o_wb_err
	) u_wb_fifo (
		.I_CYC		-> i_wb_cyc,
		.I_STB		-> i_wb_stb,
		.I_WE		-> i_wb_we,
		.I_ADDR		-> i_wb_addr,
		.I_DATA		-> i_wb_data,
		.I_SEL		-> i_wb_sel,
		.O_STALL		-> o_wb_stall,
		.O_ACK		-> o_wb_ack,
		.O_DATA		-> o_wb_data,
		.O_ERR		-> o_wb_err
	);

	// XCLK Side FIFO (Output)
	wbx_fifo #(
		.AW		= AW,
		.DW		= DW,
		.DEP		= DEPTH,
		.RST		= i_reset,
		.CLK		= i_xclk_clk,
		.I_CYC	= i_xclk_cyc,
		.I_STB	= i_xclk_stb,
		.I_WE	= i_xclk_we,
		.I_ADDR	= i_xclk_addr,
		.I_DATA	= i_xclk_data,
		.I_SEL	= i_xclk_sel,
		.O_STALL	= o_xclk_stall,
		.O_ACK	= o_xclk_ack,
		.O_DATA	= o_xclk_data,
		.O_ERR	= o_xclk_err
	) u_xclk_fifo (
		.I_CYC		-> o_xclk_cyc,
		.I_STB		-> o_xclk_stb,
		.I_WE		-> o_xclk_we,
		.I_ADDR		-> o_xclk_addr,
		.I_DATA		-> o_xclk_data,
		.I_SEL		-> o_xclk_sel,
		.O_STALL		-> o_xclk_stall,
		.O_ACK		-> o_xclk_ack,
		.O_DATA		-> o_xclk_data,
		.O_ERR		-> o_xclk_err
	);

	// Cross-domain handshake logic
	// This block handles the asynchronous crossing between WB and XCLK domains
	
	reg [LGFIFO-1:0] wb_fifo_ptr;
	reg [LGFIFO-1:0] xclk_fifo_ptr;
	reg wb_fifo_wr_en;
	reg xclk_fifo_rd_en;
	reg wb_fifo_rd_en;
	reg xclk_fifo_wr_en;
	reg wb_stb_valid;
	reg xclk_stb_valid;
	reg wb_cyc_valid;
	reg xclk_cyc_valid;
	reg wb_ack_valid;
	reg xclk_ack_valid;
	reg wb_err_valid;
	reg xclk_err_valid;
	reg wb_data_valid;
	reg xclk_data_valid;
	reg wb_sel_valid;
	reg xclk_sel_valid;
	reg wb_addr_valid;
	reg xclk_addr_valid;
	reg wb_we_valid;
	reg xclk_we_valid;
	
	// WB Side: Capture incoming cycles and forward to XCLK FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_ptr <= '0;
			wb_stb_valid <= 1'b0;
			wb_cyc_valid <= 1'b0;
			wb_ack_valid <= 1'b0;
			wb_err_valid <= 1'b0;
			wb_data_valid <= 1'b0;
			wb_sel_valid <= 1'b0;
			wb_addr_valid <= 1'b0;
			wb_we_valid <= 1'b0;
		end else begin
			// Capture WB cycle if valid and FIFO not full
			if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
				wb_stb_valid <= 1'b1;
				wb_cyc_valid <= 1'b1;
				wb_ack_valid <= 1'b0;
				wb_err_valid <= 1'b0;
				wb_data_valid <= 1'b1;
				wb_sel_valid <= 1'b1;
				wb_addr_valid <= 1'b1;
				wb_we_valid <= 1'b1;
			end else begin
				wb_stb_valid <= 1'b0;
				wb_cyc_valid <= 1'b0;
				wb_ack_valid <= 1'b0;
				wb_err_valid <= 1'b0;
				wb_data_valid <= 1'b0;
				wb_sel_valid <= 1'b0;
				wb_addr_valid <= 1'b0;
				wb_we_valid <= 1'b0;
			end
		end
	end
	
	// XCLK Side: Capture outgoing cycles and forward to WB FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_ptr <= '0;
			xclk_stb_valid <= 1'b0;
			xclk_cyc_valid <= 1'b0;
			xclk_ack_valid <= 1'b0;
			xclk_err_valid <= 1'b0;
			xclk_data_valid <= 1'b0;
			xclk_sel_valid <= 1'b0;
			xclk_addr_valid <= 1'b0;
			xclk_we_valid <= 1'b0;
		end else begin
			// Capture XCLK cycle if valid and FIFO not empty
			if (i_xclk_cyc && i_xclk_stb && !o_xclk_stall) begin
				xclk_stb_valid <= 1'b1;
				xclk_cyc_valid <= 1'b1;
				xclk_ack_valid <= 1'b0;
				xclk_err_valid <= 1'b0;
				xclk_data_valid <= 1'b1;
				xclk_sel_valid <= 1'b1;
				xclk_addr_valid <= 1'b1;
				xclk_we_valid <= 1'b1;
			end else begin
				xclk_stb_valid <= 1'b0;
				xclk_cyc_valid <= 1'b0;
				xclk_ack_valid <= 1'b0;
				xclk_err_valid <= 1'b0;
				xclk_data_valid <= 1'b0;
				xclk_sel_valid <= 1'b0;
				xclk_addr_valid <= 1'b0;
				xclk_we_valid <= 1'b0;
			end
		end
	end
	
	// Cross-domain handshake: Forward WB cycle to XCLK FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_wr_en <= 1'b0;
		end else begin
			// Forward WB cycle to XCLK FIFO if XCLK FIFO has space
			if (wb_stb_valid && !u_xclk_fifo.o_stall) begin
				wb_fifo_wr_en <= 1'b1;
			end else begin
				wb_fifo_wr_en <= 1'b0;
			end
		end
	end
	
	// Cross-domain handshake: Forward XCLK cycle to WB FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_rd_en <= 1'b0;
		end else begin
			// Forward XCLK cycle to WB FIFO if WB FIFO has space
			if (xclk_stb_valid && !u_wb_fifo.o_stall) begin
				xclk_fifo_rd_en <= 1'b1;
			end else begin
				xclk_fifo_rd_en <= 1'b0;
			end
		end
	end
	
	// Generate output signals based on FIFO status
	assign o_wb_stall = u_wb_fifo.o_stall;
	assign o_wb_ack = u_wb_fifo.o_ack;
	assign o_wb_data = u_wb_fifo.o_data;
	assign o_wb_err = u_wb_fifo.o_err;
	
	assign o_xclk_cyc = u_xclk_fifo.o_cyc;
	assign o_xclk_stb = u_xclk_fifo.o_stb;
	assign o_xclk_we = u_xclk_fifo.o_we;
	assign o_xclk_addr = u_xclk_fifo.o_addr;
	assign o_xclk_data = u_xclk_fifo.o_data;
	assign o_xclk_sel = u_xclk_fifo.o_sel;
	
endmodule
