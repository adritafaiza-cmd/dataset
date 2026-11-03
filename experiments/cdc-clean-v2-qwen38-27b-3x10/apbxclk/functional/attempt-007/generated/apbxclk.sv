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
	reg [1:0] m_reset_sync;
	reg m_reset;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end

	assign m_reset = ~m_reset_sync[1];
	assign M_PRESETn = ~m_reset;

	// S domain: detect setup phase completion (PSEL & PENABLE)
	// We capture the request when PSEL is high and PENABLE is high (access phase start)
	// Actually, in APB, the setup phase is when PSEL=1, PENABLE=0.
	// The access phase is when PSEL=1, PENABLE=1.
	// We should capture the request at the end of the setup phase / start of access phase.
	// But since we are bridging, we need to forward the request to the M side.
	// The standard approach: when S_APB_PSEL && S_APB_PENABLE, the transfer is in access phase.
	// We can capture the request at the rising edge of PENABLE (when PSEL is high).
	// However, to be safe and simple, we can use a handshake.

	// Let's use a simple approach:
	// S side: when PSEL && PENABLE, we are in access phase. We will assert a "request valid" to M side.
	// But we need to wait for M side to complete before asserting S_APB_PREADY.

	// State machine for S side:
	// IDLE: waiting for PSEL
	// SETUP: PSEL=1, PENABLE=0. Capture request.
	// ACCESS: PSEL=1, PENABLE=1. Wait for M side to complete.

	// Actually, the APB protocol on S side:
	// The master drives PSEL, PENABLE, PADDR, etc.
	// The slave (us) drives PREADY.
	// In setup phase: PSEL=1, PENABLE=0.
	// In access phase: PSEL=1, PENABLE=1.
	// The transfer completes when PREADY=1 during access phase.

	// So we need to:
	// 1. Detect when a new transfer starts (PSEL goes high).
	// 2. Capture the request fields.
	// 3. Forward to M side.
	// 4. Wait for M side to complete.
	// 5. Assert S_APB_PREADY.

	// Let's use a simple handshake between S and M domains.

	// S domain registers
	reg [AW-1:0] s_addr;
	reg s_write;
	reg [DW-1:0] s_wdata;
	reg [DW/8-1:0] s_wstrb;
	reg [2:0] s_pprot;
	reg s_req_valid;  // Request valid to M side
	reg s_req_ready;  // M side ready to accept

	// M domain registers
	reg [AW-1:0] m_addr;
	reg m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0] m_pprot;
	reg m_req_valid;  // M side request valid
	reg m_req_ready;  // S side ready to accept (always 1 when not in transfer)

	// Response from M to S
	reg [DW-1:0] m_rdata;
	reg m_rerror;
	reg m_resp_valid;  // Response valid
	reg s_resp_ready;  // S side ready to accept response

	// S domain: detect access phase
	// We capture the request when PSEL && PENABLE is true.
	// But we need to ensure we only capture once per transfer.

	// Let's use a state machine:
	// S_IDLE: PSEL=0
	// S_SETUP: PSEL=1, PENABLE=0
	// S_ACCESS: PSEL=1, PENABLE=1

	reg s_state;
	localparam S_IDLE = 1'b0;
	localparam S_ACCESS = 1'b1;

	// M domain state machine
	reg m_state;
	localparam M_IDLE = 1'b0;
	localparam M_SETUP = 1'b1;
	localparam M_ACCESS = 1'b2;

	// S domain logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			s_addr <= {AW{1'b0}};
			s_write <= 1'b0;
			s_wdata <= {DW{1'b0}};
			s_wstrb <= {(DW/8){1'b0}};
			s_pprot <= 3'b000;
			s_req_valid <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_resp_ready <= 1'b1;
		end else begin
			case (s_state)
				S_IDLE: begin
					S_APB_PREADY <= 1'b0;
					s_req_valid <= 1'b0;
					if (S_APB_PSEL) begin
						s_state <= S_ACCESS;
						// Capture request
						s_addr <= S_APB_PADDR;
						s_write <= S_APB_PWRITE;
						s_wdata <= S_APB_PWDATA;
						s_wstrb <= S_APB_PWSTRB;
						s_pprot <= S_APB_PPROT;
						s_req_valid <= 1'b1;
						s_resp_ready <= 1'b0;
					end
				end
				S_ACCESS: begin
					// Wait for response from M side
					if (m_resp_valid && s_resp_ready) begin
						S_APB_PREADY <= 1'b1;
						s_state <= S_IDLE;
						s_req_valid <= 1'b0;
						s_resp_ready <= 1'b1;
					end
				end
				default: s_state <= S_IDLE;
			endcase
		end
	end

	// M domain logic
	always @(posedge M_APB_PCLK or negedge m_reset) begin
		if (m_reset) begin
			m_state <= M_IDLE;
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_pprot <= 3'b000;
			m_req_valid <= 1'b0;
			m_rdata <= {DW{1'b0}};
			m_rerror <= 1'b0;
			m_resp_valid <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_resp_valid <= 1'b0;
					if (s_req_valid && m_req_ready) begin
						m_state <= M_SETUP;
						m_addr <= s_addr;
						m_write <= s_write;
						m_wdata <= s_wdata;
						m_wstrb <= s_wstrb;
						m_pprot <= s_pprot;
						m_req_valid <= 1'b1;
					end
				end
				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
					m_state <= M_ACCESS;
				end
				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m_rdata <= M_APB_PRDATA;
						m_rerror <= M_APB_PSLVERR;
						m_resp_valid <= 1'b1;
						m_state <= M_IDLE;
						m_req_valid <= 1'b0;
					end
				end
				default: m_state <= M_IDLE;
			endcase
		end
	end

	// M side outputs
	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_pprot;

	// S side outputs
	assign S_APB_PRDATA = m_rdata;
	assign S_APB_PSLVERR = m_rerror;

	// Handshake signals
	assign m_req_ready = (m_state == M_IDLE);
	assign s_resp_ready = (s_state == S_ACCESS);

endmodule
