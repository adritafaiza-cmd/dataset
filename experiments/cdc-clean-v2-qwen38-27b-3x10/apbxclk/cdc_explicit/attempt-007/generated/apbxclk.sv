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
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;

	// Handshake signals
	reg s_req;
	reg m_ack;
	reg m_req;
	reg s_ack;

	// Synchronization chains
	reg [1:0] s_req_sync;
	reg [1:0] m_ack_sync;
	reg [1:0] m_req_sync;
	reg [1:0] s_ack_sync;

	// M domain state
	reg m_sel_reg;
	reg m_enable_reg;
	reg m_addr_reg [AW-1:0];
	reg m_write_reg;
	reg m_wdata_reg [DW-1:0];
	reg m_wstrb_reg [DW/8-1:0];
	reg m_pprot_reg [2:0];
	reg m_busy;

	// S domain response
	reg [DW-1:0] s_rdata_reg;
	reg s_pslverr_reg;
	reg s_ready_reg;

	// Reset synchronization for M domain
	reg [1:0] m_reset_sync;

	// S domain: Capture request on setup phase
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b0;
			s_req <= 1'b0;
			s_rdata_reg <= {DW{1'b0}};
			s_pslverr_reg <= 1'b0;
			s_ready_reg <= 1'b0;
		end else begin
			// Capture request during setup phase (PSEL=1, PENABLE=0)
			if (S_APB_PSEL && !S_APB_PENABLE) begin
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_pprot_reg <= S_APB_PPROT;
			end

			// Issue request when entering access phase (PSEL=1, PENABLE=1)
			// and not already waiting for a response
			if (S_APB_PSEL && S_APB_PENABLE && !s_ready_reg) begin
				s_req <= 1'b1;
			end

			// Deassert request when ack received
			if (m_ack_sync[1]) begin
				s_req <= 1'b0;
			end

			// Update response when ack received
			if (m_ack_sync[1]) begin
				s_rdata_reg <= s_rdata_reg; // Will be updated from m domain via sync
				s_pslverr_reg <= s_pslverr_reg;
				s_ready_reg <= 1'b1;
			end

			// Deassert ready on next setup phase
			if (S_APB_PSEL && !S_APB_PENABLE) begin
				s_ready_reg <= 1'b0;
			end
		end
	end

	// S domain: Synchronize m_ack
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_ack_sync <= 2'b00;
		end else begin
			m_ack_sync <= {m_ack_sync[0], m_ack};
		end
	end

	// S domain: Synchronize m_req (for potential future use, but we use m_ack)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_req_sync <= 2'b00;
		end else begin
			m_req_sync <= {m_req_sync[0], m_req};
		end
		end

	// M domain: Reset synchronization
	always @(posedge M_APB_PCLK) begin
		m_reset_sync <= {m_reset_sync[0], S_PRESETn};
	end

	// M domain: Generate M_PRESETn
	always @(*) begin
		M_PRESETn = m_reset_sync[1];
	end

	// M domain: Synchronize s_req
	always @(posedge M_APB_PCLK) begin
		s_req_sync <= {s_req_sync[0], s_req};
	end

	// M domain: Synchronize s_ack
	always @(posedge M_APB_PCLK) begin
		s_ack_sync <= {s_ack_sync[0], s_ack};
	end

	// M domain: State machine
	always @(posedge M_APB_PCLK) begin
		if (!M_PRESETn) begin
			m_sel_reg <= 1'b0;
			m_enable_reg <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b0;
			m_busy <= 1'b0;
			m_req <= 1'b0;
			m_ack <= 1'b0;
		end else begin
			// Default: deassert ack
			m_ack <= 1'b0;

			// If not busy and s_req is synchronized, start transaction
			if (!m_busy && s_req_sync[1]) begin
				// Capture payload
				m_addr_reg <= s_addr_reg;
				m_write_reg <= s_write_reg;
				m_wdata_reg <= s_wdata_reg;
				m_wstrb_reg <= s_wstrb_reg;
				m_pprot_reg <= s_pprot_reg;
				m_sel_reg <= 1'b1;
				m_enable_reg <= 1'b0;
				m_busy <= 1'b1;
				m_req <= 1'b1;
			end else if (m_busy) begin
				// In access phase
				if (m_sel_reg && !m_enable_reg) begin
					// Setup phase: move to access
					m_enable_reg <= 1'b1;
				end else if (m_sel_reg && m_enable_reg) begin
					// Access phase: wait for PREADY
					if (M_APB_PREADY) begin
						// Transaction complete
						m_sel_reg <= 1'b0;
						m_enable_reg <= 1'b0;
						m_busy <= 1'b0;
						m_req <= 1'b0;
						m_ack <= 1'b1;
					end
				end
			end
		end
	end

	// M domain: Output assignments
	assign M_APB_PSEL = m_sel_reg;
	assign M_APB_PENABLE = m_enable_reg;
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	// S domain: Synchronize M_APB_PRDATA and M_APB_PSLVERR
	reg [DW-1:0] m_rdata_sync;
	reg m_pslverr_sync;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_rdata_sync <= {DW{1'b0}};
			m_pslverr_sync <= 1'b0;
		end else begin
			m_rdata_sync <= M_APB_PRDATA;
			m_pslverr_sync <= M_APB_PSLVERR;
		end
	end

	// S domain: Output assignments
	assign S_APB_PRDATA = m_rdata_sync;
	assign S_APB_PSLVERR = m_pslverr_sync;
	assign S_APB_PREADY = s_ready_reg;

	// S domain: Generate s_ack (not used in current design, but kept for completeness)
	always @(*) begin
		s_ack = 1'b0;
	end

endmodule
