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
	reg m_resetn;

	always @(posedge M_APB_PCLK or negedge m_resetn) begin
		if (!m_resetn) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], S_PRESETn};
		end
	end

	assign M_PRESETn = m_reset_sync[1];

	// Handshake signals
	reg s_req;
	reg [1:0] m_ack_sync;
	reg m_ack;
	reg m_req;
	reg [1:0] s_ack_sync;
	reg s_ack;

	// S domain: generate request pulse when APB setup phase completes
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_req <= 1'b0;
			s_ack_sync <= 2'b00;
			S_APB_PREADY <= 1'b0;
		end else begin
			s_ack_sync <= {s_ack_sync[0], m_ack};
			s_ack <= s_ack_sync[1];

			if (S_APB_PSEL && S_APB_PENABLE && !s_req) begin
				s_req <= 1'b1;
			end else if (s_ack) begin
				s_req <= 1'b0;
			end

			if (s_ack) begin
				S_APB_PREADY <= 1'b1;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// M domain: synchronize s_req, generate m_req, and drive APB signals
	reg m_req_sync;
	reg [1:0] s_req_sync;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_req_sync <= 2'b00;
			m_req_sync <= 1'b0;
			m_req <= 1'b0;
			m_ack_sync <= 2'b00;
			m_ack <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			s_req_sync <= {s_req_sync[0], s_req};
			m_req_sync <= s_req_sync[1];

			// Generate m_req pulse when s_req is detected
			if (m_req_sync && !m_req) begin
				m_req <= 1'b1;
			end else if (m_ack) begin
				m_req <= 1'b0;
			end

			// APB phase control
			if (m_req) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b0;
			end else if (M_APB_PSEL && M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end else if (M_APB_PSEL) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
			end

			// Acknowledge when transfer completes
			if (M_APB_PSEL && M_APB_PENABLE && M_APB_PREADY) begin
				m_ack_sync <= 2'b11;
			end else begin
				m_ack_sync <= {m_ack_sync[0], 1'b0};
			end
			m_ack <= m_ack_sync[1];
		end
	end

	// Data path: capture request fields in M domain
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

	// Response path: capture response fields in S domain
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
