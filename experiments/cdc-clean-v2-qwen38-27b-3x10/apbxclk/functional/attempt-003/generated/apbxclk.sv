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

	always @(posedge M_APB_PCLK or negedge m_reset_done) begin
		if (!m_reset_done) begin
			m_reset_sync <= 4'b0000;
			m_reset_done <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[2:0], 1'b1};
			if (m_reset_sync == 4'b1111)
				m_reset_done <= 1'b1;
		end
	end

	assign M_PRESETn = m_reset_done;

	// Handshake signals
	reg s_req_valid;
	reg m_req_ready;
	reg m_resp_valid;
	reg s_resp_ready;

	// S domain: capture request when S_APB_PSEL && S_APB_PENABLE
	// and when we are ready to accept (i.e., no outstanding transaction)
	reg s_busy;

	// M domain: hold request fields
	reg [AW-1:0] m_addr;
	reg m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0] m_pprot;

	// M domain: APB state machine
	reg m_sel;
	reg m_enable;
	reg m_pready;

	// S domain: hold response
	reg [DW-1:0] s_rdata;
	reg s_pslverr;

	// S domain: reset
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_busy <= 1'b0;
			s_req_valid <= 1'b0;
			s_resp_ready <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_rdata <= {DW{1'b0}};
			s_pslverr <= 1'b0;
		end else begin
			// Accept new request if not busy and in access phase
			if (!s_busy && S_APB_PSEL && S_APB_PENABLE) begin
				s_busy <= 1'b1;
				s_req_valid <= 1'b1;
				S_APB_PREADY <= 1'b0;
			end else if (s_busy && s_resp_ready) begin
				// Response consumed, clear busy
				s_busy <= 1'b0;
				s_req_valid <= 1'b0;
				S_APB_PREADY <= 1'b0;
			end else begin
				// Hold state
			end
		end
	end

	// S domain: response ready when not busy or when we can accept next
	// Actually, s_resp_ready should indicate that the S side is ready to accept the response
	// The response is valid when m_resp_valid is high (crossed to S domain)
	// We need to cross m_resp_valid to S domain

	// Cross m_resp_valid to S domain
	reg [1:0] m_resp_valid_sync;
	reg m_resp_valid_s;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_resp_valid_sync <= 2'b00;
			m_resp_valid_s <= 1'b0;
		end else begin
			m_resp_valid_sync <= {m_resp_valid_sync[0], m_resp_valid};
			m_resp_valid_s <= m_resp_valid_sync[1];
		end
	end

	// S domain: when m_resp_valid_s is high and we are busy, capture response and assert PREADY
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata <= {DW{1'b0}};
			s_pslverr <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else if (s_busy && m_resp_valid_s) begin
			s_rdata <= m_rdata_crossed;
			s_pslverr <= m_pslverr_crossed;
			S_APB_PREADY <= 1'b1;
		end else if (!s_busy) begin
			S_APB_PREADY <= 1'b0;
		end
	end

	// Cross m_rdata and m_pslverr to S domain
	reg [DW-1:0] m_rdata_crossed;
	reg m_pslverr_crossed;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_rdata_crossed <= {DW{1'b0}};
			m_pslverr_crossed <= 1'b0;
		end else begin
			m_rdata_crossed <= M_APB_PRDATA;
			m_pslverr_crossed <= M_APB_PSLVERR;
		end
	end

	// M domain: reset
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_sel <= 1'b0;
			m_enable <= 1'b0;
			m_pready <= 1'b0;
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_pprot <= 3'b000;
			m_req_ready <= 1'b0;
			m_resp_valid <= 1'b0;
		end else begin
			// APB state machine
			if (!m_sel) begin
				// Idle: wait for request
				if (s_req_valid) begin
					m_sel <= 1'b1;
					m_enable <= 1'b0;
					m_addr <= s_addr_crossed;
					m_write <= s_write_crossed;
					m_wdata <= s_wdata_crossed;
					m_wstrb <= s_wstrb_crossed;
					m_pprot <= s_pprot_crossed;
					m_req_ready <= 1'b0;
					m_resp_valid <= 1'b0;
				end else begin
					m_sel <= 1'b0;
					m_enable <= 1'b0;
					m_req_ready <= 1'b0;
					m_resp_valid <= 1'b0;
				end
			end else if (!m_enable) begin
				// Setup phase
				m_sel <= 1'b1;
				m_enable <= 1'b1;
			end else begin
				// Access phase
				if (M_APB_PREADY) begin
					// Transfer complete
					m_sel <= 1'b0;
					m_enable <= 1'b0;
					m_resp_valid <= 1'b1;
				end else begin
					// Wait
					m_sel <= 1'b1;
					m_enable <= 1'b1;
				end
			end
		end
	end

	// Cross S request fields to M domain
	reg [AW-1:0] s_addr_crossed;
	reg s_write_crossed;
	reg [DW-1:0] s_wdata_crossed;
	reg [DW/8-1:0] s_wstrb_crossed;
	reg [2:0] s_pprot_crossed;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_addr_crossed <= {AW{1'b0}};
			s_write_crossed <= 1'b0;
			s_wdata_crossed <= {DW{1'b0}};
			s_wstrb_crossed <= {(DW/8){1'b0}};
			s_pprot_crossed <= 3'b000;
		end else begin
			s_addr_crossed <= S_APB_PADDR;
			s_write_crossed <= S_APB_PWRITE;
			s_wdata_crossed <= S_APB_PWDATA;
			s_wstrb_crossed <= S_APB_PWSTRB;
			s_pprot_crossed <= S_APB_PPROT;
		end
	end

	// M domain: APB outputs
	assign M_APB_PSEL = m_sel;
	assign M_APB_PENABLE = m_enable;
	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_pprot;

	// S domain: response outputs
	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_pslverr;

endmodule
