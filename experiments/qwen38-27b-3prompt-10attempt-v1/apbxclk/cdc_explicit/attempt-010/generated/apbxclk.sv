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

	// Handshake signals
	reg s_req_valid;
	reg m_req_ack;
	reg m_resp_valid;
	reg s_resp_ack;

	// Reset synchronizers
	reg [2:0] s_reset_sync;
	reg [2:0] m_reset_sync;

	// M domain reset generation
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync <= 3'b000;
		end else begin
			m_reset_sync <= {m_reset_sync[1:0], 1'b1};
		end
	end

	assign M_PRESETn = m_reset_sync[2];

	// S domain reset synchronizer (for internal use if needed, but S_PRESETn is direct)
	// We use S_PRESETn directly for S domain logic.

	// M domain: Generate M_APB signals
	// M_APB_PSEL is asserted when a request is pending and not yet acknowledged
	// M_APB_PENABLE is asserted during the access phase

	reg m_sel_int;
	reg m_en_int;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_sel_int <= 1'b0;
			m_en_int <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_req_ack <= 1'b0;
			m_resp_valid <= 1'b0;
		end else begin
			// Capture request from S domain when s_req_valid is high and not already in transaction
			if (s_req_valid && !m_sel_int) begin
				m_addr_reg <= S_APB_PADDR;
				m_write_reg <= S_APB_PWRITE;
				m_wdata_reg <= S_APB_PWDATA;
				m_wstrb_reg <= S_APB_PWSTRB;
				m_pprot_reg <= S_APB_PPROT;
				m_sel_int <= 1'b1;
				m_en_int <= 1'b0;
				m_req_ack <= 1'b0;
			end else if (m_sel_int && !m_en_int) begin
				// Setup phase: wait for one cycle then go to access
				m_en_int <= 1'b1;
			end else if (m_sel_int && m_en_int) begin
				// Access phase: wait for PREADY
				if (M_APB_PREADY) begin
					m_sel_int <= 1'b0;
					m_en_int <= 1'b0;
					m_req_ack <= 1'b1;
					m_resp_valid <= 1'b1;
				end
			end else begin
				// No transaction
				m_sel_int <= 1'b0;
				m_en_int <= 1'b0;
				m_req_ack <= 1'b0;
				m_resp_valid <= 1'b0;
			end
		end
	end

	assign M_APB_PSEL = m_sel_int;
	assign M_APB_PENABLE = m_en_int;
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	// S domain: Generate S_APB_PREADY and capture response
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			s_rdata_reg <= {DW{1'b0}};
			s_pslverr_reg <= 1'b0;
			s_req_valid <= 1'b0;
			s_resp_ack <= 1'b0;
		end else begin
			// Detect new request from S side
			// A new request is valid when PSEL is high and PENABLE is low (setup phase)
			// We can only accept a new request if no transaction is in progress
			if (S_APB_PSEL && !S_APB_PENABLE && !s_req_valid) begin
				s_req_valid <= 1'b1;
				S_APB_PREADY <= 1'b0;
			end else if (s_req_valid) begin
				// Wait for response from M domain
				if (m_resp_valid) begin
					s_rdata_reg <= M_APB_PRDATA;
					s_pslverr_reg <= M_APB_PSLVERR;
					S_APB_PREADY <= 1'b1;
					s_req_valid <= 1'b0;
				end
			end else begin
				// No request pending
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	assign S_APB_PRDATA = s_rdata_reg;
	assign S_APB_PSLVERR = s_pslverr_reg;

endmodule
