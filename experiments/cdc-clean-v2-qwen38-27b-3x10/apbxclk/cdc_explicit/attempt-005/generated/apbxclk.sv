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
	reg m_busy;
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg m_setup_done;

	// S domain response
	reg [DW-1:0] s_rdata_reg;
	reg s_pslverr_reg;

	// Reset synchronization for M domain
	reg [1:0] s_presetn_sync;

	// S domain: Capture request when PSEL && PENABLE
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
			s_req <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_rdata_reg <= {DW{1'b0}};
			s_pslverr_reg <= 1'b0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_pprot_reg <= S_APB_PPROT;
				s_req <= 1'b1;
			end else if (m_ack_sync[1]) begin
				s_req <= 1'b0;
				S_APB_PREADY <= 1'b1;
				s_rdata_reg <= M_APB_PRDATA;
				s_pslverr_reg <= M_APB_PSLVERR;
			end else begin
				S_APB_PREADY <= 1'b0;
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

	// S domain: Synchronize s_presetn for M domain reset
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_presetn_sync <= 2'b00;
		end else begin
			s_presetn_sync <= {s_presetn_sync[0], S_PRESETn};
		end
	end

	// M domain: Synchronize s_req
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_req_sync <= 2'b00;
		end else begin
			s_req_sync <= {s_req_sync[0], s_req};
		end
	end

	// M domain: Synchronize s_ack
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_ack_sync <= 2'b00;
		end else begin
			s_ack_sync <= {s_ack_sync[0], s_ack};
		end
	end

	// M domain: Reset output
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_PRESETn <= 1'b0;
		end else begin
			M_PRESETn <= s_presetn_sync[1];
		end
	end

	// M domain: APB state machine
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_busy <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_setup_done <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m_req <= 1'b0;
			m_ack <= 1'b0;
		end else begin
			if (!m_busy) begin
				if (s_req_sync[1]) begin
					// Start new transaction: setup phase
					m_busy <= 1'b1;
					m_setup_done <= 1'b0;
					m_addr_reg <= s_addr_reg;
					m_write_reg <= s_write_reg;
					m_wdata_reg <= s_wdata_reg;
					m_wstrb_reg <= s_wstrb_reg;
					m_pprot_reg <= s_pprot_reg;
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
					m_req <= 1'b1;
					m_ack <= 1'b0;
				end else begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_req <= 1'b0;
					m_ack <= 1'b0;
				end
			end else begin
				if (!m_setup_done) begin
					// Setup phase complete, move to access phase
					m_setup_done <= 1'b1;
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end else begin
					// Access phase
					if (M_APB_PREADY) begin
						// Transaction complete
						m_busy <= 1'b0;
						m_setup_done <= 1'b0;
						M_APB_PSEL <= 1'b0;
						M_APB_PENABLE <= 1'b0;
						m_req <= 1'b0;
						m_ack <= 1'b1;
					end else begin
						// Wait for ready
						M_APB_PSEL <= 1'b1;
						M_APB_PENABLE <= 1'b1;
						m_req <= 1'b1;
						m_ack <= 1'b0;
					end
				end
			end
		end
	end

	// M domain: Synchronize m_ack to S domain
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_ack <= 1'b0;
		end else begin
			if (m_busy && m_setup_done && M_APB_PREADY) begin
				m_ack <= 1'b1;
			end else if (!m_busy) begin
				m_ack <= 1'b0;
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

	// S domain: Synchronize s_ack to M domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_ack <= 1'b0;
		end else begin
			if (m_ack_sync[1]) begin
				s_ack <= 1'b1;
			end else begin
				s_ack <= 1'b0;
			end
		end
	end

	// M domain: Synchronize s_ack
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_ack_sync <= 2'b00;
		end else begin
			s_ack_sync <= {s_ack_sync[0], s_ack};
		end
	end

	// M domain: Clear m_req when s_ack is received
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_req <= 1'b0;
		end else begin
			if (s_ack_sync[1]) begin
				m_req <= 1'b0;
			end
		end
	end

	// Output assignments
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	assign S_APB_PRDATA = s_rdata_reg;
	assign S_APB_PSLVERR = s_pslverr_reg;

endmodule
