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
	reg [3:0] m_reset_sync;
	reg m_reset_done;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync <= 4'b0000;
			m_reset_done <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[2:0], 1'b1};
			m_reset_done <= m_reset_sync[3];
		end
	end

	assign M_PRESETn = m_reset_done;

	// Handshake signals
	reg s_req;
	reg m_ack;
	reg m_req;
	reg s_ack;

	// S domain: detect APB setup phase start
	// PSEL high and PENABLE low indicates setup phase
	// We capture the request when PSEL is high and PENABLE is low
	// and we are not already in a transaction

	reg s_busy;
	reg s_req_pending;

	// Capture request fields in S domain
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;

	// S domain: detect new APB transaction start
	// A new transaction starts when PSEL goes high and PENABLE is low
	// We need to detect the rising edge of PSEL or the start of setup phase

	// For APB, the master asserts PSEL in setup phase, then PENABLE in access phase
	// We capture the request at the beginning of the setup phase

	// Detect when a new request is presented: PSEL high, PENABLE low, and not busy
	wire s_new_req = S_APB_PSEL & ~S_APB_PENABLE & ~s_busy;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_busy <= 1'b0;
			s_req_pending <= 1'b0;
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
			s_req <= 1'b0;
			s_ack <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else begin
			// Handle handshake
			if (s_req_pending && s_ack) begin
				// Request acknowledged by M domain
				s_req_pending <= 1'b0;
				s_req <= 1'b0;
				s_ack <= 1'b0;
			end else if (s_new_req) begin
				// New request from S side
				s_req_pending <= 1'b1;
				s_req <= 1'b1;
				s_busy <= 1'b1;
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_pprot_reg <= S_APB_PPROT;
			end else if (s_req_pending) begin
				// Wait for ack
				s_req <= 1'b1;
			end else begin
				s_req <= 1'b0;
			end

			// S_ACK: when M domain completes the transfer
			// We need to detect when the M domain has completed
			// This is indicated by m_ack from M domain

			// S_APB_PREADY: assert when the transaction is complete
			// In APB, PREADY is asserted during the access phase when the slave is ready
			// We assert S_APB_PREADY when the M domain transfer is complete
			// and we are in the access phase (PENABLE high)

			if (s_busy && S_APB_PENABLE && m_ack) begin
				S_APB_PREADY <= 1'b1;
				s_busy <= 1'b0;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// M domain: receive request and drive APB signals
	reg m_busy;
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg m_phase; // 0: idle, 1: setup, 2: access

	// Synchronous reset for M domain signals
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_busy <= 1'b0;
			m_phase <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_req <= 1'b0;
			m_ack <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			// Handle handshake
			if (m_ack && s_req) begin
				// Request received and acknowledged
				m_ack <= 1'b0;
				m_req <= 1'b0;
			end else if (s_req && !m_busy) begin
				// New request from S domain
				m_req <= 1'b1;
				m_ack <= 1'b1;
				m_busy <= 1'b1;
				m_phase <= 1'b1; // setup phase
				m_addr_reg <= s_addr_reg;
				m_write_reg <= s_write_reg;
				m_wdata_reg <= s_wdata_reg;
				m_wstrb_reg <= s_wstrb_reg;
				m_pprot_reg <= s_pprot_reg;
			end else if (m_busy) begin
				// In transaction
				if (m_phase == 1'b1) begin
					// Setup phase: assert PSEL, PENABLE low
					// Move to access phase
					m_phase <= 1'b0; // Will be set to access
				end else begin
					// Access phase: PSEL and PENABLE high
					// Wait for PREADY
					if (M_APB_PREADY) begin
						// Transfer complete
						m_busy <= 1'b0;
						m_phase <= 1'b0;
					end
				end
			end else begin
				m_req <= 1'b0;
			end
		end
	end

	// Drive M_APB signals
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			if (m_busy) begin
				if (m_phase == 1'b1) begin
					// Setup phase
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
				end else begin
					// Access phase
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end
			end else begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end
		end
	end

	// M domain: capture response
	reg [DW-1:0] m_rdata_reg;
	reg m_pslverr_reg;
	reg m_resp_valid;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_rdata_reg <= {DW{1'b0}};
			m_pslverr_reg <= 1'b0;
			m_resp_valid <= 1'b0;
		end else begin
			if (m_busy && m_phase == 1'b0 && M_APB_PREADY) begin
				// Capture response at end of access phase
				m_rdata_reg <= M_APB_PRDATA;
				m_pslverr_reg <= M_APB_PSLVERR;
				m_resp_valid <= 1'b1;
			end else if (m_resp_valid && !m_busy) begin
				// Response consumed
				m_resp_valid <= 1'b0;
			end
		end
	end

	// S domain: capture response from M domain
	reg [DW-1:0] s_rdata_reg;
	reg s_pslverr_reg;
	reg s_resp_valid;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata_reg <= {DW{1'b0}};
			s_pslverr_reg <= 1'b0;
			s_resp_valid <= 1'b0;
		end else begin
			if (m_resp_valid) begin
				s_rdata_reg <= m_rdata_reg;
				s_pslverr_reg <= m_pslverr_reg;
				s_resp_valid <= 1'b1;
			end else if (s_resp_valid && !s_busy) begin
				s_resp_valid <= 1'b0;
			end
		end
	end

	// Drive S_APB response signals
	assign S_APB_PRDATA = s_resp_valid ? s_rdata_reg : {DW{1'b0}};
	assign S_APB_PSLVERR = s_resp_valid ? s_pslverr_reg : 1'b0;

	// Drive M_APB request signals
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

endmodule
