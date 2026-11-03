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
	reg s_req_valid;
	reg s_req_ack;
	reg s_req_ack_sync1;
	reg s_req_ack_sync2;
	reg s_req_ack_sync3;

	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg m_req_valid;
	reg m_req_ack;
	reg m_req_ack_sync1;
	reg m_req_ack_sync2;
	reg m_req_ack_sync3;

	reg [DW-1:0] m_rdata_reg;
	reg m_rdata_valid;
	reg m_rdata_valid_sync1;
	reg m_rdata_valid_sync2;
	reg m_rdata_valid_sync3;
	reg m_rdata_valid_sync4;
	reg m_rdata_valid_sync5;

	reg [DW-1:0] s_rdata_reg;
	reg s_rdata_valid;
	reg s_rdata_valid_sync1;
	reg s_rdata_valid_sync2;
	reg s_rdata_valid_sync3;
	reg s_rdata_valid_sync4;
	reg s_rdata_valid_sync5;

	reg m_pslverr_reg;
	reg m_pslverr_valid;
	reg m_pslverr_valid_sync1;
	reg m_pslverr_valid_sync2;
	reg m_pslverr_valid_sync3;
	reg m_pslverr_valid_sync4;
	reg m_pslverr_valid_sync5;

	reg s_pslverr_reg;
	reg s_pslverr_valid;
	reg s_pslverr_valid_sync1;
	reg s_pslverr_valid_sync2;
	reg s_pslverr_valid_sync3;
	reg s_pslverr_valid_sync4;
	reg s_pslverr_valid_sync5;

	reg m_reset_sync1;
	reg m_reset_sync2;
	reg m_reset_sync3;
	reg m_reset_sync4;

	reg s_reset_sync1;
	reg s_reset_sync2;
	reg s_reset_sync3;
	reg s_reset_sync4;

	// Source domain: capture request when PSEL && PENABLE
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
			s_req_valid <= 1'b0;
			s_req_ack <= 1'b0;
			s_req_ack_sync1 <= 1'b0;
			s_req_ack_sync2 <= 1'b0;
			s_req_ack_sync3 <= 1'b0;
			s_rdata_reg <= {DW{1'b0}};
			s_rdata_valid <= 1'b0;
			s_rdata_valid_sync1 <= 1'b0;
			s_rdata_valid_sync2 <= 1'b0;
			s_rdata_valid_sync3 <= 1'b0;
			s_rdata_valid_sync4 <= 1'b0;
			s_rdata_valid_sync5 <= 1'b0;
			s_pslverr_reg <= 1'b0;
			s_pslverr_valid <= 1'b0;
			s_pslverr_valid_sync1 <= 1'b0;
			s_pslverr_valid_sync2 <= 1'b0;
			s_pslverr_valid_sync3 <= 1'b0;
			s_pslverr_valid_sync4 <= 1'b0;
			s_pslverr_valid_sync5 <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else begin
			// Synchronize ack from destination
			s_req_ack_sync1 <= m_req_ack;
			s_req_ack_sync2 <= s_req_ack_sync1;
			s_req_ack_sync3 <= s_req_ack_sync2;
			s_req_ack <= s_req_ack_sync3;

			// Synchronize rdata valid from destination
			s_rdata_valid_sync1 <= m_rdata_valid;
			s_rdata_valid_sync2 <= s_rdata_valid_sync1;
			s_rdata_valid_sync3 <= s_rdata_valid_sync2;
			s_rdata_valid_sync4 <= s_rdata_valid_sync3;
			s_rdata_valid_sync5 <= s_rdata_valid_sync4;
			s_rdata_valid <= s_rdata_valid_sync5;

			// Synchronize pslverr valid from destination
			s_pslverr_valid_sync1 <= m_pslverr_valid;
			s_pslverr_valid_sync2 <= s_pslverr_valid_sync1;
			s_pslverr_valid_sync3 <= s_pslverr_valid_sync2;
			s_pslverr_valid_sync4 <= s_pslverr_valid_sync3;
			s_pslverr_valid_sync5 <= s_pslverr_valid_sync4;
			s_pslverr_valid <= s_pslverr_valid_sync5;

			// Capture request on setup phase (PSEL && !PENABLE)
			if (S_APB_PSEL && !S_APB_PENABLE && !s_req_valid) begin
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_pprot_reg <= S_APB_PPROT;
				s_req_valid <= 1'b1;
			end

			// Clear request valid when ack received
			if (s_req_valid && s_req_ack) begin
				s_req_valid <= 1'b0;
			end

			// Capture response data when valid
			if (s_rdata_valid) begin
				s_rdata_reg <= m_rdata_reg;
				s_rdata_valid <= 1'b0;
			end

			if (s_pslverr_valid) begin
				s_pslverr_reg <= m_pslverr_reg;
				s_pslverr_valid <= 1'b0;
			end

			// Assert PREADY when response is ready
			if (s_rdata_valid || s_pslverr_valid) begin
				S_APB_PREADY <= 1'b1;
			end else if (S_APB_PSEL && S_APB_PENABLE) begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// Destination domain: reset synchronization
	always @(posedge M_APB_PCLK) begin
		m_reset_sync1 <= S_PRESETn;
		m_reset_sync2 <= m_reset_sync1;
		m_reset_sync3 <= m_reset_sync2;
		m_reset_sync4 <= m_reset_sync3;
		M_PRESETn <= m_reset_sync4;
	end

	// Destination domain: main logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_req_valid <= 1'b0;
			m_req_ack <= 1'b0;
			m_req_ack_sync1 <= 1'b0;
			m_req_ack_sync2 <= 1'b0;
			m_req_ack_sync3 <= 1'b0;
			m_rdata_reg <= {DW{1'b0}};
			m_rdata_valid <= 1'b0;
			m_rdata_valid_sync1 <= 1'b0;
			m_rdata_valid_sync2 <= 1'b0;
			m_rdata_valid_sync3 <= 1'b0;
			m_rdata_valid_sync4 <= 1'b0;
			m_rdata_valid_sync5 <= 1'b0;
			m_pslverr_reg <= 1'b0;
			m_pslverr_valid <= 1'b0;
			m_pslverr_valid_sync1 <= 1'b0;
			m_pslverr_valid_sync2 <= 1'b0;
			m_pslverr_valid_sync3 <= 1'b0;
			m_pslverr_valid_sync4 <= 1'b0;
			m_pslverr_valid_sync5 <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			// Synchronize req valid from source
			m_req_ack_sync1 <= s_req_valid;
			m_req_ack_sync2 <= m_req_ack_sync1;
			m_req_ack_sync3 <= m_req_ack_sync2;
			m_req_valid <= m_req_ack_sync3;

			// Synchronize ack to source
			m_req_ack_sync1 <= s_req_ack;
			m_req_ack_sync2 <= m_req_ack_sync1;
			m_req_ack_sync3 <= m_req_ack_sync2;
			m_req_ack <= m_req_ack_sync3;

			// Synchronize rdata valid to source
			m_rdata_valid_sync1 <= s_rdata_valid;
			m_rdata_valid_sync2 <= m_rdata_valid_sync1;
			m_rdata_valid_sync3 <= m_rdata_valid_sync2;
			m_rdata_valid_sync4 <= m_rdata_valid_sync3;
			m_rdata_valid_sync5 <= m_rdata_valid_sync4;
			m_rdata_valid <= m_rdata_valid_sync5;

			// Synchronize pslverr valid to source
			m_pslverr_valid_sync1 <= s_pslverr_valid;
			m_pslverr_valid_sync2 <= m_pslverr_valid_sync1;
			m_pslverr_valid_sync3 <= m_pslverr_valid_sync2;
			m_pslverr_valid_sync4 <= m_pslverr_valid_sync3;
			m_pslverr_valid_sync5 <= m_pslverr_valid_sync4;
			m_pslverr_valid <= m_pslverr_valid_sync5;

			// Capture request data when valid
			if (m_req_valid && !M_APB_PSEL) begin
				m_addr_reg <= s_addr_reg;
				m_write_reg <= s_write_reg;
				m_wdata_reg <= s_wdata_reg;
				m_wstrb_reg <= s_wstrb_reg;
				m_pprot_reg <= s_pprot_reg;
				M_APB_PSEL <= 1'b1;
			end

			// APB protocol: setup phase (PSEL=1, PENABLE=0) then access phase (PSEL=1, PENABLE=1)
			if (M_APB_PSEL && !M_APB_PENABLE) begin
				M_APB_PENABLE <= 1'b1;
			end

			// Complete transfer when PREADY
			if (M_APB_PSEL && M_APB_PENABLE && M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				m_req_ack <= 1'b1;

				// Capture response
				m_rdata_reg <= M_APB_PRDATA;
				m_pslverr_reg <= M_APB_PSLVERR;
				m_rdata_valid <= 1'b1;
				m_pslverr_valid <= 1'b1;
			end

			// Clear ack after one cycle
			if (m_req_ack && !m_req_valid) begin
				m_req_ack <= 1'b0;
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
