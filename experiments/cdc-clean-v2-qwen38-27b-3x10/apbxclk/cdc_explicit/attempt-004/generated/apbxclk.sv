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
	// Reset synchronization (RDC safe)
	// ------------------------------------------------------------------
	reg [1:0] m_reset_sync;
	reg       m_reset_active;

	always @(posedge M_APB_PCLK or negedge m_reset_active) begin
		if (!m_reset_active) begin
			m_reset_sync   <= 2'b00;
			m_reset_active <= 1'b1;
		end else begin
			m_reset_sync   <= {m_reset_sync[0], S_PRESETn};
			m_reset_active <= !m_reset_sync[1];
		end
	end

	assign M_PRESETn = !m_reset_active;

	// ------------------------------------------------------------------
	// Source-side (S_APB_PCLK domain)
	// ------------------------------------------------------------------
	// Latch the request when a new setup phase begins (PSEL high, PENABLE low)
	// and we are not already busy.
	reg       s_busy;
	reg [AW-1:0] s_latched_addr;
	reg       s_latched_write;
	reg [DW-1:0] s_latched_wdata;
	reg [DW/8-1:0] s_latched_wstrb;
	reg [2:0]  s_latched_pprot;

	// Handshake to destination: s_req goes high when we have a latched request
	// and the destination has acknowledged the previous one (or no previous).
	reg       s_req;
	reg       s_ack_sync; // synchronized ack from M domain

	// Synchronize M-side ack back to S domain
	reg [1:0] m_ack_sync;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_ack_sync <= 2'b00;
		else
			m_ack_sync <= {m_ack_sync[0], m_ack};
	end
	assign s_ack_sync = m_ack_sync[1];

	// Detect new setup phase: PSEL=1, PENABLE=0, and not busy
	wire s_setup_phase = S_APB_PSEL && !S_APB_PENABLE && !s_busy;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_busy          <= 1'b0;
			s_latched_addr  <= {AW{1'b0}};
			s_latched_write <= 1'b0;
			s_latched_wdata <= {DW{1'b0}};
			s_latched_wstrb <= {(DW/8){1'b0}};
			s_latched_pprot <= 3'b000;
			s_req           <= 1'b0;
			S_APB_PREADY    <= 1'b0;
		end else begin
			if (s_setup_phase) begin
				// Latch the request
				s_latched_addr  <= S_APB_PADDR;
				s_latched_write <= S_APB_PWRITE;
				s_latched_wdata <= S_APB_PWDATA;
				s_latched_wstrb <= S_APB_PWSTRB;
				s_latched_pprot <= S_APB_PPROT;
				s_busy          <= 1'b1;
				s_req           <= 1'b1;
				S_APB_PREADY    <= 1'b0;
			end else if (s_busy && s_ack_sync) begin
				// Destination completed the transfer
				s_busy <= 1'b0;
				s_req  <= 1'b0;
				// Assert PREADY in the access phase (PENABLE=1)
				if (S_APB_PENABLE)
					S_APB_PREADY <= 1'b1;
				else
					S_APB_PREADY <= 1'b0;
			end else if (s_busy && !s_ack_sync) begin
				// Still waiting for ack
				if (S_APB_PENABLE)
					S_APB_PREADY <= 1'b0;
			end
		end
	end

	// ------------------------------------------------------------------
	// Destination-side (M_APB_PCLK domain)
	// ------------------------------------------------------------------
	// Synchronize s_req from S domain
	reg [1:0] s_req_sync;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_req_sync <= 2'b00;
		else
			s_req_sync <= {s_req_sync[0], s_req};
	end
	wire m_req = s_req_sync[1];

	// Synchronize the payload fields. Since the payload is held stable
	// while s_req is high, we can safely synchronize each bit through
	// two-flop synchronizers.
	reg [AW-1:0] m_addr_sync;
	reg          m_write_sync;
	reg [DW-1:0] m_wdata_sync;
	reg [DW/8-1:0] m_wstrb_sync;
	reg [2:0]   m_pprot_sync;

	// Two-stage synchronizers for each payload field
	reg [AW-1:0] m_addr_s1, m_addr_s2;
	reg          m_write_s1, m_write_s2;
	reg [DW-1:0] m_wdata_s1, m_wdata_s2;
	reg [DW/8-1:0] m_wstrb_s1, m_wstrb_s2;
	reg [2:0]   m_pprot_s1, m_pprot_s2;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr_s1   <= {AW{1'b0}};
			m_addr_s2   <= {AW{1'b0}};
			m_write_s1  <= 1'b0;
			m_write_s2  <= 1'b0;
			m_wdata_s1  <= {DW{1'b0}};
			m_wdata_s2  <= {DW{1'b0}};
			m_wstrb_s1  <= {(DW/8){1'b0}};
			m_wstrb_s2  <= {(DW/8){1'b0}};
			m_pprot_s1  <= 3'b000;
			m_pprot_s2  <= 3'b000;
		end else begin
			m_addr_s1   <= s_latched_addr;
			m_addr_s2   <= m_addr_s1;
			m_write_s1  <= s_latched_write;
			m_write_s2  <= m_write_s1;
			m_wdata_s1  <= s_latched_wdata;
			m_wdata_s2  <= m_wdata_s1;
			m_wstrb_s1  <= s_latched_wstrb;
			m_wstrb_s2  <= m_wstrb_s1;
			m_pprot_s1  <= s_latched_pprot;
			m_pprot_s2  <= m_pprot_s1;
		end
	end

	assign m_addr_sync   = m_addr_s2;
	assign m_write_sync  = m_write_s2;
	assign m_wdata_sync  = m_wdata_s2;
	assign m_wstrb_sync  = m_wstrb_s2;
	assign m_pprot_sync  = m_pprot_s2;

	// APB state machine on M side
	// States: IDLE, SETUP, ACCESS
	localparam [1:0] ST_IDLE  = 2'b00,
	                 ST_SETUP = 2'b01,
	                 ST_ACCESS= 2'b10;

	reg [1:0] m_state;
	reg       m_ack;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= ST_IDLE;
			m_ack   <= 1'b0;
			M_APB_PSEL    <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			case (m_state)
				ST_IDLE: begin
					m_ack <= 1'b0;
					if (m_req) begin
						m_state       <= ST_SETUP;
						M_APB_PSEL    <= 1'b1;
						M_APB_PENABLE <= 1'b0;
					end
				end
				ST_SETUP: begin
					// Wait one cycle in setup, then go to access
					m_state       <= ST_ACCESS;
					M_APB_PSEL    <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end
				ST_ACCESS: begin
					if (M_APB_PREADY) begin
						m_state       <= ST_IDLE;
						M_APB_PSEL    <= 1'b0;
						M_APB_PENABLE <= 1'b0;
						m_ack         <= 1'b1;
					end
				end
				default: begin
					m_state <= ST_IDLE;
				end
			endcase
		end
	end

	// Drive M_APB address and data from synchronized values
	assign M_APB_PADDR  = m_addr_sync;
	assign M_APB_PWRITE = m_write_sync;
	assign M_APB_PWDATA = m_wdata_sync;
	assign M_APB_PWSTRB = m_wstrb_sync;
	assign M_APB_PPROT  = m_pprot_sync;

	// ------------------------------------------------------------------
	// Response path: M domain -> S domain
	// ------------------------------------------------------------------
	// Synchronize M_APB_PRDATA and M_APB_PSLVERR back to S domain.
	// These are stable during the access phase when PREADY is high.
	// We capture them when m_ack is asserted (transfer complete) and
	// hold them until the next transaction.

	reg [DW-1:0] m_rdata_hold;
	reg          m_pslverr_hold;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_rdata_hold   <= {DW{1'b0}};
			m_pslverr_hold <= 1'b0;
		end else if (m_ack) begin
			m_rdata_hold   <= M_APB_PRDATA;
			m_pslverr_hold <= M_APB_PSLVERR;
		end
	end

	// Synchronize the held response data back to S domain
	reg [DW-1:0] m_rdata_s1, m_rdata_s2;
	reg          m_pslverr_s1, m_pslverr_s2;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_rdata_s1   <= {DW{1'b0}};
			m_rdata_s2   <= {DW{1'b0}};
			m_pslverr_s1 <= 1'b0;
			m_pslverr_s2 <= 1'b0;
		end else begin
			m_rdata_s1   <= m_rdata_hold;
			m_rdata_s2   <= m_rdata_s1;
			m_pslverr_s1 <= m_pslverr_hold;
			m_pslverr_s2 <= m_pslverr_s1;
		end
	end

	assign S_APB_PRDATA  = m_rdata_s2;
	assign S_APB_PSLVERR = m_pslverr_s2;

endmodule
