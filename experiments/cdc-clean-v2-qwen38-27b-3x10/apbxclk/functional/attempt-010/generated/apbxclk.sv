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
			m_reset_done  <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[2:0], 1'b1};
			if (m_reset_sync == 4'b1111)
				m_reset_done <= 1'b1;
		end
	end

	assign M_PRESETn = m_reset_done;

	// S-domain: detect setup phase completion (PSEL & !PENABLE)
	// We capture the request when PSEL is high and PENABLE is low (setup phase)
	// and the bridge is idle.

	// S-domain state
	reg s_idle;
	reg s_req_valid;  // request has been captured and forwarded

	// M-domain state
	reg m_idle;
	reg m_setup_done; // M_APB_PENABLE is high (access phase)

	// Handshake signals
	reg s_to_m_req;   // S domain: request valid for M domain
	reg m_to_s_ack;   // M domain: transaction complete, ack to S domain

	// S-domain: capture request on setup phase
	// We use a simple handshake: S asserts s_to_m_req when it captures a request.
	// M domain deasserts m_to_s_ack when it completes the transaction.

	// S-domain logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_idle      <= 1'b1;
			s_req_valid <= 1'b0;
			s_to_m_req  <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else begin
			// If M domain has acknowledged, we can complete the S-side transaction
			if (m_to_s_ack) begin
				// Complete the S-side access phase
				S_APB_PREADY <= 1'b1;
				s_req_valid  <= 1'b0;
				s_to_m_req   <= 1'b0;
				s_idle       <= 1'b1;
			end else if (s_idle && S_APB_PSEL && !S_APB_PENABLE) begin
				// Setup phase: capture request
				s_idle       <= 1'b0;
				s_req_valid  <= 1'b1;
				s_to_m_req   <= 1'b1;
				S_APB_PREADY <= 1'b0;
			end else if (!s_idle && S_APB_PSEL && S_APB_PENABLE) begin
				// Access phase: wait for M to complete
				S_APB_PREADY <= 1'b0;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// M-domain logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_idle       <= 1'b1;
			m_setup_done <= 1'b0;
			m_to_s_ack   <= 1'b0;
			M_APB_PSEL   <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			if (m_idle) begin
				if (s_to_m_req) begin
					// Start setup phase
					m_idle        <= 1'b0;
					m_setup_done  <= 1'b0;
					m_to_s_ack    <= 1'b0;
					M_APB_PSEL    <= 1'b1;
					M_APB_PENABLE <= 1'b0;
				end else begin
					M_APB_PSEL    <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end
			end else if (!m_setup_done) begin
				// Setup phase: transition to access phase
				m_setup_done  <= 1'b1;
				M_APB_PSEL    <= 1'b1;
				M_APB_PENABLE <= 1'b1;
			end else begin
				// Access phase: wait for PREADY
				if (M_APB_PREADY) begin
					// Transaction complete
					m_idle        <= 1'b1;
					m_setup_done  <= 1'b0;
					m_to_s_ack    <= 1'b1;
					M_APB_PSEL    <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end else begin
					M_APB_PSEL    <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end
			end
		end
	end

	// M-domain: deassert ack after one cycle
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_to_s_ack <= 1'b0;
		end else begin
			// Keep ack high for one cycle after being set
			if (m_to_s_ack && m_idle)
				m_to_s_ack <= 1'b0;
		end
	end

	// M-domain: capture and hold request fields
	reg [AW-1:0] m_addr;
	reg          m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0]    m_pprot;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr   <= {AW{1'b0}};
			m_write  <= 1'b0;
			m_wdata  <= {DW{1'b0}};
			m_wstrb  <= {(DW/8){1'b0}};
			m_pprot  <= 3'b000;
		end else if (s_to_m_req && m_idle) begin
			m_addr   <= S_APB_PADDR;
			m_write  <= S_APB_PWRITE;
			m_wdata  <= S_APB_PWDATA;
			m_wstrb  <= S_APB_PWSTRB;
			m_pprot  <= S_APB_PPROT;
		end
	end

	assign M_APB_PADDR  = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT  = m_pprot;

	// S-domain: capture response from M domain
	reg [DW-1:0] s_rdata;
	reg          s_pslverr;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata   <= {DW{1'b0}};
			s_pslverr <= 1'b0;
		end else if (m_to_s_ack) begin
			s_rdata   <= M_APB_PRDATA;
			s_pslverr <= M_APB_PSLVERR;
		end
	end

	assign S_APB_PRDATA  = s_rdata;
	assign S_APB_PSLVERR = s_pslverr;

endmodule
