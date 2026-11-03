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
	// Slave-side state machine
	// ------------------------------------------------------------------
	localparam S_IDLE = 2'd0;
	localparam S_SETUP = 2'd1;
	localparam S_ACCESS = 2'd2;
	localparam S_WAIT = 2'd3;

	reg [1:0] s_state;
	reg [1:0] s_state_next;

	// Latch request fields on slave side
	reg [AW-1:0] s_addr;
	reg s_write;
	reg [DW-1:0] s_wdata;
	reg [DW/8-1:0] s_wstrb;
	reg [2:0] s_pprot;

	// Response from master side (synchronized back)
	reg [DW-1:0] s_rdata;
	reg s_rslverr;
	reg s_resp_valid;

	// ------------------------------------------------------------------
	// Master-side state machine
	// ------------------------------------------------------------------
	localparam M_IDLE = 2'd0;
	localparam M_SETUP = 2'd1;
	localparam M_ACCESS = 2'd2;
	localparam M_WAIT = 2'd3;

	reg [1:0] m_state;
	reg [1:0] m_state_next;

	// Latched request fields on master side
	reg [AW-1:0] m_addr;
	reg m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0] m_pprot;

	// Response from master APB
	reg [DW-1:0] m_rdata;
	reg m_rslverr;
	reg m_resp_valid;

	// ------------------------------------------------------------------
	// Handshake signals between domains
	// ------------------------------------------------------------------
	// Slave -> Master: request valid
	reg s_req_valid;
	reg s_req_valid_sync1;
	reg s_req_valid_sync2;
	reg s_req_valid_m;

	// Master -> Slave: response valid
	reg m_resp_valid_s;
	reg m_resp_valid_sync1;
	reg m_resp_valid_sync2;
	reg m_resp_valid_s_slave;

	// ------------------------------------------------------------------
	// Slave clock domain logic
	// ------------------------------------------------------------------
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			s_addr <= {AW{1'b0}};
			s_write <= 1'b0;
			s_wdata <= {DW{1'b0}};
			s_wstrb <= {(DW/8){1'b0}};
			s_pprot <= 3'b0;
			s_rdata <= {DW{1'b0}};
			s_rslverr <= 1'b0;
			s_resp_valid <= 1'b0;
			s_req_valid <= 1'b0;
			S_APB_PREADY <= 1'b1;
		end else begin
			s_state <= s_state_next;

			case (s_state)
				S_IDLE: begin
					if (S_APB_PSEL && !S_APB_PENABLE) begin
						// Capture request
						s_addr <= S_APB_PADDR;
						s_write <= S_APB_PWRITE;
						s_wdata <= S_APB_PWDATA;
						s_wstrb <= S_APB_PWSTRB;
						s_pprot <= S_APB_PPROT;
						s_req_valid <= 1'b1;
						S_APB_PREADY <= 1'b0;
					end else begin
						S_APB_PREADY <= 1'b1;
					end
				end

				S_SETUP: begin
					// Wait for master to accept
					if (s_req_valid_m) begin
						s_req_valid <= 1'b0;
						S_APB_PREADY <= 1'b0;
					end
				end

				S_ACCESS: begin
					// Wait for response
					if (m_resp_valid_s_slave) begin
						s_rdata <= m_rdata;
						s_rslverr <= m_rslverr;
						s_resp_valid <= 1'b1;
						S_APB_PREADY <= 1'b1;
					end
				end

				S_WAIT: begin
					// Done, back to idle
					S_APB_PREADY <= 1'b1;
				end

				default: begin
					S_APB_PREADY <= 1'b1;
				end
			endcase
		end
	end

	// Slave state next logic
	always @(*) begin
		s_state_next = s_state;
		case (s_state)
			S_IDLE: begin
				if (S_APB_PSEL && !S_APB_PENABLE)
					s_state_next = S_SETUP;
			end
			S_SETUP: begin
				if (s_req_valid_m)
					s_state_next = S_ACCESS;
			end
			S_ACCESS: begin
				if (m_resp_valid_s_slave)
					s_state_next = S_WAIT;
			end
			S_WAIT: begin
				s_state_next = S_IDLE;
			end
			default: s_state_next = S_IDLE;
		endcase
	end

	// Synchronize s_req_valid to master clock
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_req_valid_sync1 <= 1'b0;
			s_req_valid_sync2 <= 1'b0;
			s_req_valid_m <= 1'b0;
		end else begin
			s_req_valid_sync1 <= s_req_valid;
			s_req_valid_sync2 <= s_req_valid_sync1;
			s_req_valid_m <= s_req_valid_sync2;
		end
	end

	// Synchronize m_resp_valid to slave clock
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_resp_valid_sync1 <= 1'b0;
			m_resp_valid_sync2 <= 1'b0;
			m_resp_valid_s_slave <= 1'b0;
		end else begin
			m_resp_valid_sync1 <= m_resp_valid_s;
			m_resp_valid_sync2 <= m_resp_valid_sync1;
			m_resp_valid_s_slave <= m_resp_valid_sync2;
		end
	end

	// ------------------------------------------------------------------
	// Master clock domain logic
	// ------------------------------------------------------------------
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= M_IDLE;
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_pprot <= 3'b0;
			m_rdata <= {DW{1'b0}};
			m_rslverr <= 1'b0;
			m_resp_valid <= 1'b0;
			m_resp_valid_s <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_PRESETn <= 1'b1;
		end else begin
			M_PRESETn <= 1'b1;
			m_state <= m_state_next;

			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					if (s_req_valid_m) begin
						// Capture request from slave
						m_addr <= s_addr;
						m_write <= s_write;
						m_wdata <= s_wdata;
						m_wstrb <= s_wstrb;
						m_pprot <= s_pprot;
						M_APB_PSEL <= 1'b1;
						M_APB_PENABLE <= 1'b0;
					end
				end

				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end

				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m_rdata <= M_APB_PRDATA;
						m_rslverr <= M_APB_PSLVERR;
						m_resp_valid <= 1'b1;
						m_resp_valid_s <= 1'b1;
						M_APB_PSEL <= 1'b0;
						M_APB_PENABLE <= 1'b0;
					end
				end

				M_WAIT: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_resp_valid <= 1'b0;
					m_resp_valid_s <= 1'b0;
				end

				default: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end
			endcase
		end
	end

	// Master state next logic
	always @(*) begin
		m_state_next = m_state;
		case (m_state)
			M_IDLE: begin
				if (s_req_valid_m)
					m_state_next = M_SETUP;
			end
			M_SETUP: begin
				m_state_next = M_ACCESS;
			end
			M_ACCESS: begin
				if (M_APB_PREADY)
					m_state_next = M_WAIT;
			end
			M_WAIT: begin
				m_state_next = M_IDLE;
			end
			default: m_state_next = M_IDLE;
		endcase
	end

	// ------------------------------------------------------------------
	// Master APB outputs
	// ------------------------------------------------------------------
	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_pprot;

	// ------------------------------------------------------------------
	// Slave APB outputs
	// ------------------------------------------------------------------
	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_rslverr;

endmodule
