// =============================================================================
// Copyright (C) 2015-2024 Lattice Semiconductor.
// =============================================================================

`include "apbxclk.vh"

module apbxclk #(
	parameter	C_APB_ADDR_WIDTH = 12,
	parameter	C_APB_DATA_WIDTH = 32,
	parameter [0:0]	OPT_REGISTERED = 1'b0,
	localparam	AW = C_APB_ADDR_WIDTH,
	localparam	DW = C_APB_DATA_WIDTH
) (
	input	wire			S_APB_PCLK, S_PRESETn,
	input	wire			S_APB_PSEL,
	input	wire			S_APB_PENABLE,
	output	reg			S_APB_PREADY,
	input	wire	[AW-1:0]	S_APB_PADDR,
	input	wire			S_APB_PWRITE,
	input	wire	[DW-1:0]	S_APB_PWDATA,
	input	wire	[DW/8-1:0]	S_APB_PWSTRB,
	input	wire	[2:0]		S_APB_PPROT,
	output	wire	[DW-1:0]	S_APB_PRDATA,
	output	wire			S_APB_PSLVERR,
	input	wire			M_APB_PCLK,
	output	reg			M_PRESETn,
	output	reg			M_APB_PSEL,
	output	reg			M_APB_PENABLE,
	input	wire			M_APB_PREADY,
	output	wire	[AW-1:0]	M_APB_PADDR,
	output	wire			M_APB_PWRITE,
	output	wire	[DW-1:0]	M_APB_PWDATA,
	output	wire	[DW/8-1:0]	M_APB_PWSTRB,
	output	wire	[2:0]		M_APB_PPROT,
	input	wire	[DW-1:0]	M_APB_PRDATA,
	input	wire			M_APB_PSLVERR
);

	// =============================================================================
	// Signal Declarations
	// =============================================================================

	// =============================================================================
	// Reset Synchronizer
	// =============================================================================

	reg [1:0] r_m_presetn;

	initial begin
		r_m_presetn = 2'b00;
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			r_m_presetn <= 2'b00;
		end else begin
			r_m_presetn <= {r_m_presetn[0], 1'b1};
		end
	end

	assign M_PRESETn = r_m_presetn[1];

	// =============================================================================
	// APB Clock Domain Crossing
	// =============================================================================

	reg [1:0] r_s_apb_psel;
	reg [1:0] r_s_apb_penable;
	reg [1:0] r_s_apb_pwrite;
	reg [1:0] r_s_apb_pready;
	reg [1:0] r_m_apb_pready;

	reg [AW-1:0] r_s_apb_paddr;
	reg [DW-1:0] r_s_apb_pwdata;
	reg [DW/8-1:0] r_s_apb_pwstrb;
	reg [2:0] r_s_apb_pprot;

	reg [DW-1:0] r_m_apb_prdata;
	reg r_m_apb_pslverr;

	// =============================================================================
	// Source APB Interface
	// =============================================================================

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			r_s_apb_psel <= 2'b00;
			r_s_apb_penable <= 2'b00;
			r_s_apb_pwrite <= 2'b00;
			r_s_apb_pready <= 2'b00;
			r_s_apb_paddr <= {AW{1'b0}};
			r_s_apb_pwdata <= {DW{1'b0}};
			r_s_apb_pwstrb <= {(DW/8){1'b0}};
			r_s_apb_pprot <= 3'b000;
		end else begin
			r_s_apb_psel <= {r_s_apb_psel[0], S_APB_PSEL};
			r_s_apb_penable <= {r_s_apb_penable[0], S_APB_PENABLE};
			r_s_apb_pwrite <= {r_s_apb_pwrite[0], S_APB_PWRITE};
			r_s_apb_pready <= {r_s_apb_pready[0], r_m_apb_pready[1]};
			if (S_APB_PSEL && !S_APB_PENABLE) begin
				r_s_apb_paddr <= S_APB_PADDR;
				r_s_apb_pwdata <= S_APB_PWDATA;
				r_s_apb_pwstrb <= S_APB_PWSTRB;
				r_s_apb_pprot <= S_APB_PPROT;
			end
		end
	end

	assign S_APB_PREADY = r_s_apb_pready[1];

	// =============================================================================
	// Destination APB Interface
	// =============================================================================

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			r_m_apb_pready <= 2'b00;
			r_m_apb_prdata <= {DW{1'b0}};
			r_m_apb_pslverr <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			r_m_apb_pready <= {r_m_apb_pready[0], M_APB_PREADY};
			if (M_APB_PSEL && M_APB_PENABLE && M_APB_PREADY) begin
				r_m_apb_prdata <= M_APB_PRDATA;
				r_m_apb_pslverr <= M_APB_PSLVERR;
			end
			M_APB_PSEL <= r_s_apb_psel[1];
			M_APB_PENABLE <= r_s_apb_penable[1];
		end
	end

	assign M_APB_PADDR = r_s_apb_paddr;
	assign M_APB_PWRITE = r_s_apb_pwrite[1];
	assign M_APB_PWDATA = r_s_apb_pwdata;
	assign M_APB_PWSTRB = r_s_apb_pwstrb;
	assign M_APB_PPROT = r_s_apb_pprot;

	// =============================================================================
	// Source APB Response
	// =============================================================================

	assign S_APB_PRDATA = r_m_apb_prdata;
	assign S_APB_PSLVERR = r_m_apb_pslverr;

endmodule