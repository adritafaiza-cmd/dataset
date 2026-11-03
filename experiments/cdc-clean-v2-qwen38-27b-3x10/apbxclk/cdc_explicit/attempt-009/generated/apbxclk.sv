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

	// ------------------------------------------------------------------
	// Reset synchronization for M_APB domain
	// ------------------------------------------------------------------
	reg [1:0] m_reset_sync;
	reg       m_reset_int;

	always @(posedge M_APB_PCLK or negedge m_reset_int) begin
		if (!m_reset_int) begin
			m_reset_sync <= 2'b00;
			m_reset_int   <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[0], S_PRESETn};
			m_reset_int   <= m_reset_sync[1];
		end
	end

	assign M_PRESETn = m_reset_int;

	// ------------------------------------------------------------------
	// Source domain: capture request on setup phase, generate handshake
	// ------------------------------------------------------------------
	reg       s_req_valid;
	reg [AW-1:0] s_addr;
	reg       s_write;
	reg [DW-1:0] s_wdata;
	reg [DW/8-1:0] s_wstrb;
	reg [2:0]  s_pprot;

	// Synchronization of request valid from S to M domain
	reg [1:0] req_sync;
	reg       m_req_valid;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_req_valid <= 1'b0;
			s_addr      <= {AW{1'b0}};
			s_write     <= 1'b0;
			s_wdata     <= {DW{1'b0}};
			s_wstrb     <= {(DW/8){1'b0}};
			s_pprot     <= 3'b000;
		end else begin
			// Capture request during setup phase (PSEL high, PENABLE low)
			if (S_APB_PSEL && !S_APB_PENABLE && !s_req_valid) begin
				s_req_valid <= 1'b1;
				s_addr      <= S_APB_PADDR;
				s_write     <= S_APB_PWRITE;
				s_wdata     <= S_APB_PWDATA;
				s_wstrb     <= S_APB_PWSTRB;
				s_pprot     <= S_APB_PPROT;
			end
			// Clear request valid when destination completes (synchronized back)
			else if (s_req_valid && m_done_sync[1]) begin
				s_req_valid <= 1'b0;
			end
		end
	end

	// Synchronize s_req_valid to M domain
	always @(posedge M_APB_PCLK or negedge m_reset_int) begin
		if (!m_reset_int) begin
			req_sync    <= 2'b00;
			m_req_valid <= 1'b0;
		end else begin
			req_sync    <= {req_sync[0], s_req_valid};
			m_req_valid <= req_sync[1];
		end
	end

	// ------------------------------------------------------------------
	// Destination domain: APB state machine
	// ------------------------------------------------------------------
	reg       m_fsm_idle;
	reg       m_fsm_setup;
	reg       m_fsm_access;

	reg [AW-1:0] m_addr;
	reg       m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0]  m_pprot;

	// Synchronize done from M to S domain
	reg [1:0] done_sync;
	reg       m_done;

	always @(posedge M_APB_PCLK or negedge m_reset_int) begin
		if (!m_reset_int) begin
			m_fsm_idle   <= 1'b1;
			m_fsm_setup  <= 1'b0;
			m_fsm_access <= 1'b0;
			m_addr       <= {AW{1'b0}};
			m_write      <= 1'b0;
			m_wdata      <= {DW{1'b0}};
			m_wstrb      <= {(DW/8){1'b0}};
			m_pprot      <= 3'b000;
			m_done       <= 1'b0;
			done_sync    <= 2'b00;
		end else begin
			m_done <= 1'b0;
			done_sync <= {done_sync[0], m_done};

			if (m_fsm_idle) begin
				if (m_req_valid) begin
					m_fsm_idle   <= 1'b0;
					m_fsm_setup  <= 1'b1;
					m_fsm_access <= 1'b0;
					m_addr       <= s_addr;
					m_write      <= s_write;
					m_wdata      <= s_wdata;
					m_wstrb      <= s_wstrb;
					m_pprot      <= s_pprot;
				end
			end
			else if (m_fsm_setup) begin
				m_fsm_idle   <= 1'b0;
				m_fsm_setup  <= 1'b0;
				m_fsm_access <= 1'b1;
			end
			else if (m_fsm_access) begin
				if (M_APB_PREADY) begin
					m_fsm_idle   <= 1'b1;
					m_fsm_setup  <= 1'b0;
					m_fsm_access <= 1'b0;
					m_done       <= 1'b1;
				end
			end
		end
	end

	// ------------------------------------------------------------------
	// Destination APB outputs
	// ------------------------------------------------------------------
	assign M_APB_PSEL    = m_fsm_setup | m_fsm_access;
	assign M_APB_PENABLE = m_fsm_access;
	assign M_APB_PADDR   = m_addr;
	assign M_APB_PWRITE  = m_write;
	assign M_APB_PWDATA  = m_wdata;
	assign M_APB_PWSTRB  = m_wstrb;
	assign M_APB_PPROT   = m_pprot;

	// ------------------------------------------------------------------
	// Response path: M to S
	// ------------------------------------------------------------------
	reg [DW-1:0] m_rdata_sync;
	reg       m_pslverr_sync;
	reg [1:0]   rdata_valid_sync;
	reg       s_rdata_valid;

	// Capture response when access completes
	reg       m_resp_capture;

	always @(posedge M_APB_PCLK or negedge m_reset_int) begin
		if (!m_reset_int) begin
			m_resp_capture   <= 1'b0;
			m_rdata_sync     <= {DW{1'b0}};
			m_pslverr_sync   <= 1'b0;
			rdata_valid_sync <= 2'b00;
		end else begin
			m_resp_capture <= 1'b0;
			if (m_fsm_access && M_APB_PREADY) begin
				m_resp_capture   <= 1'b1;
				m_rdata_sync     <= M_APB_PRDATA;
				m_pslverr_sync   <= M_APB_PSLVERR;
				rdata_valid_sync <= 2'b10;
			end else begin
				rdata_valid_sync <= {rdata_valid_sync[0], 1'b0};
			end
		end
	end

	// Synchronize response valid to S domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata_valid <= 1'b0;
		end else begin
			s_rdata_valid <= rdata_valid_sync[1];
		end
	end

	// ------------------------------------------------------------------
	// Source APB outputs
	// ------------------------------------------------------------------
	// S_APB_PREADY: assert when response is valid and request was pending
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
		end else begin
			if (s_req_valid && s_rdata_valid) begin
				S_APB_PREADY <= 1'b1;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	assign S_APB_PRDATA  = m_rdata_sync;
	assign S_APB_PSLVERR = m_pslverr_sync;

endmodule
