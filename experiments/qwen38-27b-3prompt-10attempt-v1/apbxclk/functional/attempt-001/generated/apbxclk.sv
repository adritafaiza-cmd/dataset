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

	// Synchronizers
	reg [1:0] s_reset_sync;
	reg [1:0] s_req_sync;
	reg [1:0] m_ready_sync;
	reg [1:0] m_slverr_sync;

	// M-domain state
	reg m_reset;
	reg m_sel;
	reg m_enable;
	reg [AW-1:0] m_addr;
	reg m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0] m_pprot;

	// S-domain state
	reg s_busy;
	reg [DW-1:0] s_rdata;
	reg s_slverr;

	// Synchronizer logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_reset_sync <= 2'b00;
			s_req_sync <= 2'b00;
		end else begin
			s_reset_sync <= {s_reset_sync[0], 1'b1};
			s_req_sync <= {s_req_sync[0], s_busy};
		end
	end

	always @(posedge M_APB_PCLK or posedge m_reset) begin
		if (m_reset) begin
			m_ready_sync <= 2'b00;
			m_slverr_sync <= 2'b00;
		end else begin
			m_ready_sync <= {m_ready_sync[0], M_APB_PREADY};
			m_slverr_sync <= {m_slverr_sync[0], M_APB_PSLVERR};
		end
	end

	// M-domain reset
	always @(posedge M_APB_PCLK or posedge m_reset) begin
		if (m_reset) begin
			M_PRESETn <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;
		end
	end

	// M-domain request generation
	always @(posedge M_APB_PCLK or posedge m_reset) begin
		if (m_reset) begin
			m_sel <= 1'b0;
			m_enable <= 1'b0;
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_pprot <= 3'b000;
		end else begin
			if (s_req_sync[1] && !m_sel) begin
				m_sel <= 1'b1;
				m_enable <= 1'b0;
				m_addr <= S_APB_PADDR;
				m_write <= S_APB_PWRITE;
				m_wdata <= S_APB_PWDATA;
				m_wstrb <= S_APB_PWSTRB;
				m_pprot <= S_APB_PPROT;
			end else if (m_sel && !m_enable && M_APB_PREADY) begin
				m_enable <= 1'b1;
			end else if (m_sel && m_enable && M_APB_PREADY) begin
				m_sel <= 1'b0;
				m_enable <= 1'b0;
			end
		end
	end

	// M-domain outputs
	assign M_APB_PSEL = m_sel;
	assign M_APB_PENABLE = m_enable;
	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_pprot;

	// S-domain response handling
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_busy <= 1'b0;
			s_rdata <= {DW{1'b0}};
			s_slverr <= 1'b0;
			S_APB_PREADY <= 1'b1;
		end else begin
			if (s_busy) begin
				if (m_ready_sync[1]) begin
					s_busy <= 1'b0;
					S_APB_PREADY <= 1'b1;
					if (OPT_REGISTERED) begin
						s_rdata <= M_APB_PRDATA;
						s_slverr <= M_APB_PSLVERR;
					end
				end
			end else begin
				if (S_APB_PSEL && !S_APB_PENABLE) begin
					s_busy <= 1'b1;
					S_APB_PREADY <= 1'b0;
					if (OPT_REGISTERED) begin
						s_rdata <= {DW{1'b0}};
						s_slverr <= 1'b0;
					end
				end
			end
		end
	end

	// S-domain outputs
	assign S_APB_PRDATA = OPT_REGISTERED ? s_rdata : M_APB_PRDATA;
	assign S_APB_PSLVERR = OPT_REGISTERED ? s_slverr : M_APB_PSLVERR;

endmodule
