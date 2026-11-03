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

	// Internal signals
	reg	[AW-1:0]	s_addr_reg;
	reg			s_write_reg;
	reg	[DW-1:0]	s_wdata_reg;
	reg	[DW/8-1:0]	s_wstrb_reg;
	reg	[2:0]	s_prot_reg;
	reg			s_req_valid;

	reg			m_req_valid_sync1;
	reg			m_req_valid_sync2;
	reg			m_req_valid_sync3;
	reg			m_req_valid_sync4;

	reg			m_addr_valid;
	reg	[AW-1:0]	m_addr_reg;
	reg			m_write_reg;
	reg	[DW-1:0]	m_wdata_reg;
	reg	[DW/8-1:0]	m_wstrb_reg;
	reg	[2:0]	m_prot_reg;

	reg			m_fsm_idle;
	reg			m_fsm_setup;
	reg			m_fsm_access;

	reg			m_rdata_valid_sync1;
	reg			m_rdata_valid_sync2;
	reg			m_rdata_valid_sync3;
	reg			m_rdata_valid_sync4;

	reg			s_rdata_valid;
	reg	[DW-1:0]	s_rdata_reg;
	reg			s_pslverr_reg;

	// Reset synchronization for M domain
	reg			m_reset_sync1;
	reg			m_reset_sync2;
	reg			m_reset_sync3;
	reg			m_reset_sync4;

	// Reset synchronization for S domain (for S_PRESETn, though S_PRESETn is already in S domain)
	// We need to synchronize M_PRESETn release back to S domain? No, S_PRESETn is input.
	// But we need to ensure that when S_PRESETn is deasserted, the M domain is also ready.
	// Actually, the requirement says "Both interfaces must remain inactive during reset".
	// S_PRESETn is the source reset. M_PRESETn is the destination reset output.
	// We need to generate M_PRESETn from S_PRESETn with synchronization.
	// And we need to ensure that the M domain logic is reset when M_PRESETn is low.

	// Generate M_PRESETn by synchronizing S_PRESETn to M domain
	always @(posedge M_APB_PCLK or negedge m_reset_sync4) begin
		if (!m_reset_sync4) begin
			m_reset_sync1 <= 1'b0;
			m_reset_sync2 <= 1'b0;
			m_reset_sync3 <= 1'b0;
			m_reset_sync4 <= 1'b0;
		end else begin
			m_reset_sync1 <= S_PRESETn;
			m_reset_sync2 <= m_reset_sync1;
			m_reset_sync3 <= m_reset_sync2;
			m_reset_sync4 <= m_reset_sync3;
		end
	end

	assign M_PRESETn = m_reset_sync4;

	// S domain: Capture request when PSEL && PENABLE
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_prot_reg <= 3'b000;
			s_req_valid <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_rdata_valid <= 1'b0;
			s_rdata_reg <= {DW{1'b0}};
			s_pslverr_reg <= 1'b0;
		end else begin
			// Capture request at start of access phase
			if (S_APB_PSEL && S_APB_PENABLE && !s_req_valid) begin
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_prot_reg <= S_APB_PPROT;
				s_req_valid <= 1'b1;
			end

			// When response is valid, assert PREADY and clear request valid
			if (s_rdata_valid) begin
				S_APB_PREADY <= 1'b1;
				s_req_valid <= 1'b0;
				s_rdata_valid <= 1'b0;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// M domain: Synchronize request valid
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_req_valid_sync1 <= 1'b0;
			m_req_valid_sync2 <= 1'b0;
			m_req_valid_sync3 <= 1'b0;
			m_req_valid_sync4 <= 1'b0;
		end else begin
			m_req_valid_sync1 <= s_req_valid;
			m_req_valid_sync2 <= m_req_valid_sync1;
			m_req_valid_sync3 <= m_req_valid_sync2;
			m_req_valid_sync4 <= m_req_valid_sync3;
		end
	end

	// M domain: Capture payload when request valid is synchronized
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr_valid <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_prot_reg <= 3'b000;
			m_fsm_idle <= 1'b1;
			m_fsm_setup <= 1'b0;
			m_fsm_access <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			// Capture payload when request valid is fully synchronized
			if (m_req_valid_sync4 && !m_addr_valid) begin
				m_addr_valid <= 1'b1;
				m_addr_reg <= s_addr_reg;
				m_write_reg <= s_write_reg;
				m_wdata_reg <= s_wdata_reg;
				m_wstrb_reg <= s_wstrb_reg;
				m_prot_reg <= s_prot_reg;
			end

			// FSM
			if (m_fsm_idle) begin
				if (m_addr_valid) begin
					m_fsm_idle <= 1'b0;
					m_fsm_setup <= 1'b1;
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
				end else begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end
			end else if (m_fsm_setup) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
				m_fsm_setup <= 1'b0;
				m_fsm_access <= 1'b1;
			end else if (m_fsm_access) begin
				if (M_APB_PREADY) begin
					m_fsm_access <= 1'b0;
					m_fsm_idle <= 1'b1;
					m_addr_valid <= 1'b0;
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end else begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end
			end
		end
	end

	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_prot_reg;

	// M domain: Synchronize response valid (when M_APB_PREADY is high in access phase)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_rdata_valid_sync1 <= 1'b0;
			m_rdata_valid_sync2 <= 1'b0;
			m_rdata_valid_sync3 <= 1'b0;
			m_rdata_valid_sync4 <= 1'b0;
		end else begin
			m_rdata_valid_sync1 <= (m_fsm_access && M_APB_PREADY);
			m_rdata_valid_sync2 <= m_rdata_valid_sync1;
			m_rdata_valid_sync3 <= m_rdata_valid_sync2;
			m_rdata_valid_sync4 <= m_rdata_valid_sync3;
		end
	end

	// S domain: Synchronize response valid back to S domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			// Already handled in main S domain block
		end else begin
			// We need to synchronize m_rdata_valid_sync4 to S domain
			// But we already have s_rdata_valid in S domain. Let's use a separate sync chain.
		end
	end

	// Actually, let's restructure. We need to synchronize the response valid from M to S.
	// Let's add sync chains for response valid.

	reg			m_resp_valid_sync1;
	reg			m_resp_valid_sync2;
	reg			m_resp_valid_sync3;
	reg			m_resp_valid_sync4;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_resp_valid_sync1 <= 1'b0;
			m_resp_valid_sync2 <= 1'b0;
			m_resp_valid_sync3 <= 1'b0;
			m_resp_valid_sync4 <= 1'b0;
		end else begin
			m_resp_valid_sync1 <= (m_fsm_access && M_APB_PREADY);
			m_resp_valid_sync2 <= m_resp_valid_sync1;
			m_resp_valid_sync3 <= m_resp_valid_sync2;
			m_resp_valid_sync4 <= m_resp_valid_sync3;
		end
	end

	// S domain: Synchronize response valid
	reg			s_resp_valid_sync1;
	reg			s_resp_valid_sync2;
	reg			s_resp_valid_sync3;
	reg			s_resp_valid_sync4;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_resp_valid_sync1 <= 1'b0;
			s_resp_valid_sync2 <= 1'b0;
			s_resp_valid_sync3 <= 1'b0;
			s_resp_valid_sync4 <= 1'b0;
		end else begin
			s_resp_valid_sync1 <= m_resp_valid_sync4;
			s_resp_valid_sync2 <= s_resp_valid_sync1;
			s_resp_valid_sync3 <= s_resp_valid_sync2;
			s_resp_valid_sync4 <= s_resp_valid_sync3;
		end
	end

	// S domain: Capture response data when response valid is synchronized
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata_valid <= 1'b0;
			s_rdata_reg <= {DW{1'b0}};
			s_pslverr_reg <= 1'b0;
		end else begin
			if (s_resp_valid_sync4 && !s_rdata_valid) begin
				s_rdata_valid <= 1'b1;
				s_rdata_reg <= M_APB_PRDATA;
				s_pslverr_reg <= M_APB_PSLVERR;
			end else if (s_rdata_valid) begin
				// Keep valid until consumed
			end
		end
	end

	assign S_APB_PRDATA = s_rdata_reg;
	assign S_APB_PSLVERR = s_pslverr_reg;

endmodule
