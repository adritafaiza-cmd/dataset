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
			m_reset_done  <= m_reset_sync[3];
		end
	end

	assign M_PRESETn = m_reset_done;

	// S-domain: capture request when S_APB_PSEL && !S_APB_PENABLE (setup phase)
	// We need to detect the start of a new transaction.
	// APB: Setup phase is when PSEL=1 and PENABLE=0.
	// Access phase is when PSEL=1 and PENABLE=1.
	// A new transaction starts when PSEL goes from 0 to 1 (or when PSEL=1 and PENABLE=0 and we are not in a transaction).
	// Since we only support one outstanding transaction, we can use a simple state machine.

	// S-domain state
	// IDLE: waiting for PSEL
	// SETUP: PSEL=1, PENABLE=0, capture request
	// ACCESS: PSEL=1, PENABLE=1, waiting for PREADY
	// But we need to bridge to M domain.

	// Let's use a handshake approach.
	// S-domain: When a new request is detected (PSEL=1, PENABLE=0, and not already in a transaction),
	//   capture the request and assert a "req_valid" signal.
	// M-domain: When "req_valid" is high and M domain is ready, start the M_APB transaction.
	//   When M_APB_PREADY is high, complete the transaction and assert "resp_valid".
	// S-domain: When "resp_valid" is high, present the response and assert S_APB_PREADY.

	// S-domain registers
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;
	reg s_req_valid;
	reg s_resp_valid;
	reg [DW-1:0] s_rdata_reg;
	reg s_slverr_reg;

	// M-domain registers
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg m_req_valid;
	reg m_resp_valid;
	reg [DW-1:0] m_rdata_reg;
	reg m_slverr_reg;

	// S-domain: detect new request
	// A new request is when S_APB_PSEL=1 and S_APB_PENABLE=0 and s_req_valid=0
	// We capture the request on the rising edge of S_APB_PCLK.

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr_reg  <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
			s_req_valid <= 1'b0;
			s_resp_valid <= 1'b0;
			s_rdata_reg <= {DW{1'b0}};
			s_slverr_reg <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else begin
			// If we have a response pending, present it
			if (s_resp_valid) begin
				// S_APB_PREADY should be asserted when the response is valid
				// and the source is in the access phase (PSEL=1, PENABLE=1)
				if (S_APB_PSEL && S_APB_PENABLE) begin
					S_APB_PREADY <= 1'b1;
					s_resp_valid <= 1'b0;
				end else begin
					S_APB_PREADY <= 1'b0;
				end
			end else if (s_req_valid) begin
				// Request is in flight, wait for response
				S_APB_PREADY <= 1'b0;
			end else begin
				// Idle, check for new request
				if (S_APB_PSEL && !S_APB_PENABLE) begin
					// Capture request
					s_addr_reg  <= S_APB_PADDR;
					s_write_reg <= S_APB_PWRITE;
					s_wdata_reg <= S_APB_PWDATA;
					s_wstrb_reg <= S_APB_PWSTRB;
					s_pprot_reg <= S_APB_PPROT;
					s_req_valid <= 1'b1;
					S_APB_PREADY <= 1'b0;
				end else begin
					S_APB_PREADY <= 1'b0;
				end
			end
		end
	end

	// M-domain: process request and generate response
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_addr_reg  <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_req_valid <= 1'b0;
			m_resp_valid <= 1'b0;
			m_rdata_reg <= {DW{1'b0}};
			m_slverr_reg <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			if (m_resp_valid) begin
				// Response is ready, wait for S domain to consume it
				// Keep M_APB_PSEL and M_APB_PENABLE low
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end else if (m_req_valid) begin
				// Request is in flight
				// Check if M_APB_PREADY is high
				if (M_APB_PREADY) begin
					// Transfer complete
					m_rdata_reg <= M_APB_PRDATA;
					m_slverr_reg <= M_APB_PSLVERR;
					m_resp_valid <= 1'b1;
					m_req_valid <= 1'b0;
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end else begin
					// Still waiting
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end
			end else begin
				// Idle, check for new request from S domain
				if (s_req_valid) begin
					// Capture request
					m_addr_reg  <= s_addr_reg;
					m_write_reg <= s_write_reg;
					m_wdata_reg <= s_wdata_reg;
					m_wstrb_reg <= s_wstrb_reg;
					m_pprot_reg <= s_pprot_reg;
					m_req_valid <= 1'b1;
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
				end else begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end
			end
		end
	end

	// M_APB output assignments
	assign M_APB_PADDR  = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT  = m_pprot_reg;

	// S_APB response assignments
	assign S_APB_PRDATA  = s_rdata_reg;
	assign S_APB_PSLVERR = s_slverr_reg;

	// S-domain: update response registers when m_resp_valid is high
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata_reg  <= {DW{1'b0}};
			s_slverr_reg <= 1'b0;
		end else begin
			if (m_resp_valid) begin
				s_rdata_reg  <= m_rdata_reg;
				s_slverr_reg <= m_slverr_reg;
				s_resp_valid <= 1'b1;
			end
		end
	end

endmodule
