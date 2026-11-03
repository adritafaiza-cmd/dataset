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

	// Synchronous reset for M domain
	reg [3:0] m_rst_sync;
	reg m_rst;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_rst_sync <= 4'b0000;
		else
			m_rst_sync <= {m_rst_sync[2:0], 1'b1};
	end

	assign M_PRESETn = m_rst_sync[3];
	assign m_rst = ~m_rst_sync[3];

	// Handshake signals
	reg s_req;
	reg m_ack;
	reg m_req;
	reg s_ack;

	// S domain: detect APB setup phase completion (PSEL & PENABLE)
	// Capture request when S_APB_PSEL && S_APB_PENABLE
	reg s_req_valid;
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;

	// S domain: response from M domain
	reg [DW-1:0] s_rdata_reg;
	reg s_pslverr_reg;
	reg s_resp_valid;

	// M domain: request from S domain
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg m_req_valid;

	// M domain: response to S domain
	reg [DW-1:0] m_rdata_reg;
	reg m_pslverr_reg;
	reg m_resp_valid;

	// APB state machines
	// S domain: idle -> setup -> access
	// M domain: idle -> setup -> access

	// S domain state
	reg s_idle;
	reg s_setup;
	reg s_access;

	// M domain state
	reg m_idle;
	reg m_setup;
	reg m_access;

	// S domain: detect new APB request
	// A new request starts when PSEL is asserted and we are idle
	// The setup phase is when PSEL=1, PENABLE=0
	// The access phase is when PSEL=1, PENABLE=1

	// S domain: capture request at end of setup phase (when PENABLE goes high)
	// We need to detect the transition from setup to access

	// S domain: request valid when we detect PSEL && PENABLE and we are not already in a transaction
	reg s_trans_active;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_idle <= 1'b1;
			s_setup <= 1'b0;
			s_access <= 1'b0;
			s_trans_active <= 1'b0;
			s_req <= 1'b0;
			s_req_valid <= 1'b0;
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
			s_rdata_reg <= {DW{1'b0}};
			s_pslverr_reg <= 1'b0;
			s_resp_valid <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else begin
			// State machine
			if (s_idle) begin
				if (S_APB_PSEL && !S_APB_PENABLE) begin
					s_idle <= 1'b0;
					s_setup <= 1'b1;
				end
			end else if (s_setup) begin
				if (S_APB_PSEL && S_APB_PENABLE) begin
					s_setup <= 1'b0;
					s_access <= 1'b1;
					s_trans_active <= 1'b1;
					// Capture request
					s_addr_reg <= S_APB_PADDR;
					s_write_reg <= S_APB_PWRITE;
					s_wdata_reg <= S_APB_PWDATA;
					s_wstrb_reg <= S_APB_PWSTRB;
					s_pprot_reg <= S_APB_PPROT;
					s_req <= 1'b1;
					s_req_valid <= 1'b1;
				end
			end else if (s_access) begin
				if (S_APB_PREADY) begin
					s_access <= 1'b0;
					s_idle <= 1'b1;
					s_trans_active <= 1'b0;
					s_req <= 1'b0;
					s_req_valid <= 1'b0;
					S_APB_PREADY <= 1'b0;
				end
			end

			// Handle response from M domain
			if (s_ack && s_trans_active) begin
				s_rdata_reg <= s_rdata_reg; // Will be updated by s_ack logic
				s_pslverr_reg <= s_pslverr_reg;
				s_resp_valid <= 1'b1;
			end

			// S_APB_PREADY is asserted when response is valid and we are in access phase
			if (s_access && s_resp_valid) begin
				S_APB_PREADY <= 1'b1;
			end else if (!s_access) begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// S domain: response data and error
	assign S_APB_PRDATA = s_rdata_reg;
	assign S_APB_PSLVERR = s_pslverr_reg;

	// M domain state machine
	always @(posedge M_APB_PCLK or negedge m_rst) begin
		if (m_rst) begin
			m_idle <= 1'b1;
			m_setup <= 1'b0;
			m_access <= 1'b0;
			m_req <= 1'b0;
			m_req_valid <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_rdata_reg <= {DW{1'b0}};
			m_pslverr_reg <= 1'b0;
			m_resp_valid <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			// State machine
			if (m_idle) begin
				if (m_req) begin
					m_idle <= 1'b0;
					m_setup <= 1'b1;
					// Capture request
					m_addr_reg <= m_addr_reg; // Will be set by m_req logic
					m_write_reg <= m_write_reg;
					m_wdata_reg <= m_wdata_reg;
					m_wstrb_reg <= m_wstrb_reg;
					m_pprot_reg <= m_pprot_reg;
					m_req_valid <= 1'b1;
				end
			end else if (m_setup) begin
				m_setup <= 1'b0;
				m_access <= 1'b1;
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
			end else if (m_access) begin
				if (M_APB_PREADY) begin
					m_access <= 1'b0;
					m_idle <= 1'b1;
					m_req <= 1'b0;
					m_req_valid <= 1'b0;
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					// Capture response
					m_rdata_reg <= M_APB_PRDATA;
					m_pslverr_reg <= M_APB_PSLVERR;
					m_resp_valid <= 1'b1;
					m_ack <= 1'b1;
				end
			end

			// Handle request from S domain
			if (s_req && m_idle) begin
				m_req <= 1'b1;
				m_addr_reg <= s_addr_reg;
				m_write_reg <= s_write_reg;
				m_wdata_reg <= s_wdata_reg;
				m_wstrb_reg <= s_wstrb_reg;
				m_pprot_reg <= s_pprot_reg;
			end

			// Clear ack
			if (m_ack) begin
				m_ack <= 1'b0;
			end
		end
	end

	// M domain: output signals
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	// Cross-domain handshake: S req -> M ack
	// S domain: s_req is set, m_ack is cleared
	// M domain: m_req is set, s_ack is cleared

	// S domain: detect m_ack
	reg m_ack_s;
	reg m_ack_s_prev;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_ack_s <= 1'b0;
			m_ack_s_prev <= 1'b0;
			s_ack <= 1'b0;
		end else begin
			m_ack_s <= m_ack;
			m_ack_s_prev <= m_ack_s;
			// Detect rising edge of m_ack
			if (m_ack_s && !m_ack_s_prev) begin
				s_ack <= 1'b1;
				// Update response
				s_rdata_reg <= m_rdata_reg;
				s_pslverr_reg <= m_pslverr_reg;
			end else begin
				s_ack <= 1'b0;
			end
		end
	end

	// M domain: detect s_req
	reg s_req_m;
	reg s_req_m_prev;

	always @(posedge M_APB_PCLK or negedge m_rst) begin
		if (m_rst) begin
			s_req_m <= 1'b0;
			s_req_m_prev <= 1'b0;
		end else begin
			s_req_m <= s_req;
			s_req_m_prev <= s_req_m;
		end
	end

	// Clear s_req when m_ack is detected in S domain
	// This is handled in the S domain state machine above

	// Clear m_req when s_ack is detected in M domain
	// This is handled in the M domain state machine above

endmodule
