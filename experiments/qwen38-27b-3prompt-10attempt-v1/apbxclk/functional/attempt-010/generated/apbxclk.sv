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
	reg m_reset_done;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync <= 2'b00;
			m_reset_done <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
			if (m_reset_sync == 2'b11)
				m_reset_done <= 1'b1;
		end
		end

	assign M_PRESETn = m_reset_done;

	// Handshake signals
	reg s_req;
	reg [1:0] m_ack_sync;
	reg m_ack;
	reg m_req_sync;
	reg m_req;

	// S domain: detect setup phase start
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_req <= 1'b0;
		end else begin
			if (S_APB_PSEL && !S_APB_PENABLE && !s_req)
				s_req <= 1'b1;
			else if (m_ack)
				s_req <= 1'b0;
		end
	end

	// M domain: synchronize s_req
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_req_sync <= 2'b00;
			m_req <= 1'b0;
		end else begin
			m_req_sync <= {m_req_sync[0], s_req};
			m_req <= m_req_sync[1];
		end
		end

	// M domain: APB state machine
	reg m_sel;
	reg m_enable;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_sel <= 1'b0;
			m_enable <= 1'b0;
		end else begin
			if (m_req) begin
				// Start setup phase
				m_sel <= 1'b1;
				m_enable <= 1'b0;
			end else if (m_sel && !m_enable) begin
				// Transition to access phase
				m_enable <= 1'b1;
			end else if (m_sel && m_enable && M_APB_PREADY) begin
				// Transfer complete, deassert
				m_sel <= 1'b0;
				m_enable <= 1'b0;
			end
		end
	end

	assign M_APB_PSEL = m_sel;
	assign M_APB_PENABLE = m_enable;

	// M domain: synchronize m_ack back to S domain
	// m_ack is asserted when transfer completes in M domain
	reg m_ack_pulse;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_ack_pulse <= 1'b0;
		end else begin
			m_ack_pulse <= (m_sel && m_enable && M_APB_PREADY);
		end
	end

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_ack_sync <= 2'b00;
			m_ack <= 1'b0;
		end else begin
			m_ack_sync <= {m_ack_sync[0], m_ack_pulse};
			m_ack <= m_ack_sync[1];
		end
	end

	// S domain: synchronize m_ack
	reg [1:0] s_ack_sync;
	reg s_ack;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_ack_sync <= 2'b00;
			s_ack <= 1'b0;
		end else begin
			s_ack_sync <= {s_ack_sync[0], m_ack};
			s_ack <= s_ack_sync[1];
		end
	end

	// S domain: PREADY
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE && s_ack)
				S_APB_PREADY <= 1'b1;
			else
				S_APB_PREADY <= 1'b0;
		end
	end

	// Payload crossing: S to M
	// Capture request fields in M domain when m_req is asserted
	reg [AW-1:0] m_addr;
	reg m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0] m_pprot;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_pprot <= 3'b000;
		end else if (m_req) begin
			m_addr <= S_APB_PADDR;
			m_write <= S_APB_PWRITE;
			m_wdata <= S_APB_PWDATA;
			m_wstrb <= S_APB_PWSTRB;
			m_pprot <= S_APB_PPROT;
		end
	end

	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_pprot;

	// Response crossing: M to S
	// Capture response fields in S domain when s_ack is asserted
	reg [DW-1:0] s_rdata;
	reg s_pslverr;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata <= {DW{1'b0}};
			s_pslverr <= 1'b0;
		end else if (s_ack) begin
			s_rdata <= M_APB_PRDATA;
			s_pslverr <= M_APB_PSLVERR;
		end
	end

	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_pslverr;

endmodule
