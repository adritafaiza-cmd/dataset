// =============================================================================
// afifo.v
// =============================================================================
//
// Asynchronous FIFO with Gray-coded pointer CDC.
//
// =============================================================================

`timescale 1ns / 1ps

`include "afifo.v"

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

	// =============================================================================
	// Local parameters
	// =============================================================================

	localparam	DEPTH = 1 << LGFIFO;
	localparam	ADDRW = LGFIFO;
	localparam	POSW  = LGFIFO + 1;

	// =============================================================================
	// Write domain
	// =============================================================================

	reg	[POSW-1:0]	wr_ptr;
	reg	[POSW-1:0]	wr_ptr_gray;
	reg	[POSW-1:0]	rd_ptr_gray_w;

	reg	[POSW-1:0]	wr_ptr_next;
	reg	[POSW-1:0]	wr_ptr_gray_next;
	reg	[POSW-1:0]	rd_ptr_gray_w_next;

	wire	wr_en;
	wire	wr_clk_edge;

	assign	wr_en = i_wr & ~o_wr_full;

	generate
		if (WRITE_ON_POSEDGE) begin : gen_wr_posedge
			assign	wr_clk_edge = i_wclk;
		end else begin : gen_wr_negedge
			assign	wr_clk_edge = ~i_wclk;
		end
	endgenerate

	always @(posedge i_wclk, posedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr        <= {POSW{1'b0}};
			wr_ptr_gray   <= {POSW{1'b0}};
			rd_ptr_gray_w <= {POSW{1'b0}};
		end else begin
			wr_ptr        <= wr_ptr_next;
			wr_ptr_gray   <= wr_ptr_gray_next;
			rd_ptr_gray_w <= rd_ptr_gray_w_next;
		end
	end

	always @* begin
		wr_ptr_next        = wr_en ? (wr_ptr + 1'b1) : wr_ptr;
		wr_ptr_gray_next   = (wr_ptr_next ^ (wr_ptr_next >> 1));
		rd_ptr_gray_w_next = rd_ptr_gray_w;
	end

	// =============================================================================
	// Read domain
	// =============================================================================

	reg	[POSW-1:0]	rd_ptr;
	reg	[POSW-1:0]	rd_ptr_gray;
	reg	[POSW-1:0]	wr_ptr_gray_r;

	reg	[POSW-1:0]	rd_ptr_next;
	reg	[POSW-1:0]	rd_ptr_gray_next;
	reg	[POSW-1:0]	wr_ptr_gray_r_next;

	wire	rd_en;
	wire	rd_clk_edge;

	assign	rd_en = i_rd & ~o_rd_empty;

	generate
		if (OPT_REGISTER_READS) begin : gen_rd_posedge
			assign	rd_clk_edge = i_rclk;
		end else begin : gen_rd_negedge
			assign	rd_clk_edge = ~i_rclk;
		end
	endgenerate

	always @(posedge i_rclk, posedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr        <= {POSW{1'b0}};
			rd_ptr_gray   <= {POSW{1'b0}};
			wr_ptr_gray_r <= {POSW{1'b0}};
		end else begin
			rd_ptr        <= rd_ptr_next;
			rd_ptr_gray   <= rd_ptr_gray_next;
			wr_ptr_gray_r <= wr_ptr_gray_r_next;
		end
	end

	always @* begin
		rd_ptr_next        = rd_en ? (rd_ptr + 1'b1) : rd_ptr;
		rd_ptr_gray_next   = (rd_ptr_next ^ (rd_ptr_next >> 1));
		wr_ptr_gray_r_next = wr_ptr_gray_r;
	end

	// =============================================================================
	// Memory
	// =============================================================================

	reg	[WIDTH-1:0]	mem [0:DEPTH-1];

	always @(posedge i_wclk) begin
		if (wr_en) begin
			mem[wr_ptr[ADDRW-1:0]] <= i_wr_data;
		end
	end

	// =============================================================================
	// Read data
	// =============================================================================

	wire	[WIDTH-1:0]	mem_rd_data;

	assign	mem_rd_data = mem[rd_ptr[ADDRW-1:0]];

	generate
		if (OPT_REGISTER_READS) begin : gen_rd_reg
			always @(posedge i_rclk) begin
				o_rd_data <= mem_rd_data;
			end
		end else begin : gen_rd_comb
			assign	o_rd_data = mem_rd_data;
		end
	endgenerate

	// =============================================================================
	// Full / Empty flags
	// =============================================================================

	always @(posedge i_wclk, posedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= (wr_ptr_gray == {~rd_ptr_gray_w[ADDRW:ADDRW-1], rd_ptr_gray_w[ADDRW-2:0]});
		end
	end

	always @(posedge i_rclk, posedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (rd_ptr_gray == wr_ptr_gray_r);
		end
	end

	// =============================================================================
	// CDC synchronizers
	// =============================================================================

	// rd_ptr_gray -> write domain
	(* ASYNC_REG = "TRUE" *)
	reg	[NFF-1:0][POSW-1:0]	rd_ptr_gray_w_ff;

	always @(posedge i_wclk, posedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rd_ptr_gray_w_ff <= {NFF{POSW{1'b0}}};
		end else begin
			rd_ptr_gray_w_ff <= {rd_ptr_gray_w_ff[NFF-2:0], rd_ptr_gray};
		end
	end

	assign	rd_ptr_gray_w_next = rd_ptr_gray_w_ff[NFF-1];

	// wr_ptr_gray -> read domain
	(* ASYNC_REG = "TRUE" *)
	reg	[NFF-1:0][POSW-1:0]	wr_ptr_gray_r_ff;

	always @(posedge i_rclk, posedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wr_ptr_gray_r_ff <= {NFF{POSW{1'b0}}};
		end else begin
			wr_ptr_gray_r_ff <= {wr_ptr_gray_r_ff[NFF-2:0], wr_ptr_gray};
		end
	end

	assign	wr_ptr_gray_r_next = wr_ptr_gray_r_ff[NFF-1];

endmodule