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
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;

	reg [DW-1:0] s_rdata_reg;
	reg s_pslverr_reg;

	reg m_req_valid;
	reg m_req_ready;
	reg s_resp_valid;
	reg s_resp_ready;

	// Reset synchronizer for M domain
	reg [1:0] m_reset_sync;
	reg m_reset_int;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync <= 2'b00;
			m_reset_int <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
			m_reset_int <= m_reset_sync[1];
		end
	end

	assign M_PRESETn = m_reset_int;

	// M domain: APB slave interface generation
	// We use a simple state machine to generate PSEL and PENABLE
	// States: IDLE, SETUP, ACCESS
	localparam S_IDLE = 2'd0;
	localparam S_SETUP = 2'd1;
	localparam S_ACCESS = 2'd2;

	reg [1:0] m_state;
	reg m_psel_int;
	reg m_penable_int;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= S_IDLE;
			m_psel_int <= 1'b0;
			m_penable_int <= 1'b0;
			m_req_ready <= 1'b1;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
		end else begin
			case (m_state)
				S_IDLE: begin
					m_psel_int <= 1'b0;
					m_penable_int <= 1'b0;
					if (m_req_valid) begin
						m_state <= S_SETUP;
						m_psel_int <= 1'b1;
						m_addr_reg <= S_APB_PADDR;
						m_write_reg <= S_APB_PWRITE;
						m_wdata_reg <= S_APB_PWDATA;
						m_wstrb_reg <= S_APB_PWSTRB;
						m_pprot_reg <= S_APB_PPROT;
						m_req_ready <= 1'b0;
					end
				end
				S_SETUP: begin
					m_psel_int <= 1'b1;
					m_penable_int <= 1'b1;
					m_state <= S_ACCESS;
				end
				S_ACCESS: begin
					m_psel_int <= 1'b1;
					m_penable_int <= 1'b1;
					if (M_APB_PREADY) begin
						m_state <= S_IDLE;
						m_psel_int <= 1'b0;
						m_penable_int <= 1'b0;
						m_req_ready <= 1'b1;
						s_resp_valid <= 1'b1;
					end
				end
				default: begin
					m_state <= S_IDLE;
					m_psel_int <= 1'b0;
					m_penable_int <= 1'b0;
				end
			endcase
		end
	end

	assign M_APB_PSEL = m_psel_int;
	assign M_APB_PENABLE = m_penable_int;
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	// S domain: APB master interface
	// Detect setup phase completion to send request to M domain
	// S_APB_PSEL && !S_APB_PENABLE is setup phase
	// S_APB_PSEL && S_APB_PENABLE is access phase

	reg s_setup_detected;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			S_APB_PRDATA <= {DW{1'b0}};
			S_APB_PSLVERR <= 1'b0;
			s_setup_detected <= 1'b0;
			s_resp_valid <= 1'b0;
			s_resp_ready <= 1'b1;
		end else begin
			// Default
			S_APB_PREADY <= 1'b0;

			// Handle response from M domain
			if (s_resp_valid && s_resp_ready) begin
				S_APB_PRDATA <= M_APB_PRDATA;
				S_APB_PSLVERR <= M_APB_PSLVERR;
				S_APB_PREADY <= 1'b1;
				s_resp_valid <= 1'b0;
				s_resp_ready <= 1'b1;
			end else if (s_resp_valid) begin
				s_resp_ready <= 1'b0;
			end else begin
				s_resp_ready <= 1'b1;
			end

			// Detect setup phase and send request
			if (S_APB_PSEL && !S_APB_PENABLE && m_req_ready) begin
				m_req_valid <= 1'b1;
				s_setup_detected <= 1'b1;
			end else begin
				m_req_valid <= 1'b0;
				if (S_APB_PSEL && S_APB_PENABLE) begin
					s_setup_detected <= 1'b0;
				end
			end
		end
	end

	// M domain: Capture response
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_resp_valid <= 1'b0;
		end else begin
			// s_resp_valid is set in M domain when PREADY is asserted
			// It is cleared in S domain
			// This is a handshake across domains
		end
	end

	// The s_resp_valid signal is set in M domain and cleared in S domain
	// This is a valid CDC handshake pattern (toggle or valid/ready)
	// But we need to ensure it's properly synchronized

	// Let's use a proper CDC handshake for the response
	// M domain sets s_resp_valid, S domain clears it

	// Actually, the above implementation has issues with CDC.
	// Let's use a proper 2-phase handshake for both request and response.

	// Request: S domain sets m_req_valid, M domain clears it
	// Response: M domain sets s_resp_valid, S domain clears it

	// For m_req_valid:
	// S domain: set when setup phase detected and m_req_ready
	// M domain: clear when request is accepted

	// For s_resp_valid:
	// M domain: set when PREADY is asserted
	// S domain: clear when response is consumed

	// We need to synchronize m_req_ready to S domain
	// And synchronize s_resp_valid to S domain (already done via handshake)

	// Let's add synchronization for m_req_ready
	reg [1:0] m_req_ready_sync;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_req_ready_sync <= 2'b00;
		end else begin
			m_req_ready_sync <= {m_req_ready_sync[0], m_req_ready};
		end
	end

	// Use synchronized version in S domain logic
	// But the above always block uses m_req_ready directly.
	// We need to fix this.

	// Let's restructure the S domain logic to use the synchronized signal

	// Actually, let's use a cleaner approach with proper CDC handshakes.

	// Request handshake:
	// S domain: req_valid (set), req_ready (from M domain, synchronized)
	// M domain: req_valid (synchronized), req_ready (set)

	// Response handshake:
	// M domain: resp_valid (set), resp_ready (from S domain, synchronized)
	// S domain: resp_valid (synchronized), resp_ready (set)

	// Let's implement this properly.

	// S domain request valid
	reg s_req_valid;

	// M domain request ready (synchronized to S domain)
	// Already have m_req_ready_sync

	// S domain request ready (from M domain)
	// m_req_ready is in M domain, synchronized to S domain via m_req_ready_sync

	// M domain request valid (synchronized to M domain)
	reg [1:0] s_req_valid_sync;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_req_valid_sync <= 2'b00;
		end else begin
			s_req_valid_sync <= {s_req_valid_sync[0], s_req_valid};
		end
	end

	// S domain response ready
	reg s_resp_ready_int;

	// M domain response ready (synchronized to M domain)
	reg [1:0] s_resp_ready_sync;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_resp_ready_sync <= 2'b00;
		end else begin
			s_resp_ready_sync <= {s_resp_ready_sync[0], s_resp_ready_int};
		end
	end

	// M domain response valid
	reg m_resp_valid;

	// S domain response valid (synchronized to S domain)
	reg [1:0] m_resp_valid_sync;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_resp_valid_sync <= 2'b00;
		end else begin
			m_resp_valid_sync <= {m_resp_valid_sync[0], m_resp_valid};
		end
	end

	// Now update the logic

	// S domain: Generate request
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			S_APB_PRDATA <= {DW{1'b0}};
			S_APB_PSLVERR <= 1'b0;
			s_req_valid <= 1'b0;
			s_resp_ready_int <= 1'b1;
		end else begin
			// Default
			S_APB_PREADY <= 1'b0;

			// Handle response
			if (m_resp_valid_sync[1] && s_resp_ready_int) begin
				S_APB_PRDATA <= M_APB_PRDATA;
				S_APB_PSLVERR <= M_APB_PSLVERR;
				S_APB_PREADY <= 1'b1;
				s_resp_ready_int <= 1'b0;
			end else if (m_resp_valid_sync[1]) begin
				s_resp_ready_int <= 1'b0;
			end else begin
				s_resp_ready_int <= 1'b1;
			end

			// Generate request
			if (S_APB_PSEL && !S_APB_PENABLE && m_req_ready_sync[1] && !s_req_valid) begin
				s_req_valid <= 1'b1;
			end else if (s_req_valid && m_req_ready_sync[1]) begin
				s_req_valid <= 1'b0;
			end
		end
	end

	// M domain: Handle request and generate response
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= S_IDLE;
			m_psel_int <= 1'b0;
			m_penable_int <= 1'b0;
			m_req_ready <= 1'b1;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_resp_valid <= 1'b0;
		end else begin
			// Handle request
			if (s_req_valid_sync[1] && m_req_ready) begin
				m_req_ready <= 1'b0;
				m_state <= S_SETUP;
				m_psel_int <= 1'b1;
				m_addr_reg <= S_APB_PADDR;
				m_write_reg <= S_APB_PWRITE;
				m_wdata_reg <= S_APB_PWDATA;
				m_wstrb_reg <= S_APB_PWSTRB;
				m_pprot_reg <= S_APB_PPROT;
			end

			// State machine
			case (m_state)
				S_IDLE: begin
					m_psel_int <= 1'b0;
					m_penable_int <= 1'b0;
				end
				S_SETUP: begin
					m_psel_int <= 1'b1;
					m_penable_int <= 1'b1;
					m_state <= S_ACCESS;
				end
				S_ACCESS: begin
					m_psel_int <= 1'b1;
					m_penable_int <= 1'b1;
					if (M_APB_PREADY) begin
						m_state <= S_IDLE;
						m_psel_int <= 1'b0;
						m_penable_int <= 1'b0;
						m_req_ready <= 1'b1;
						m_resp_valid <= 1'b1;
					end
				end
				default: begin
					m_state <= S_IDLE;
					m_psel_int <= 1'b0;
					m_penable_int <= 1'b0;
				end
			endcase

			// Handle response ready
			if (m_resp_valid && s_resp_ready_sync[1]) begin
				m_resp_valid <= 1'b0;
			end
		end
	end

endmodule
