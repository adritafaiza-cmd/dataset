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
	reg [AW-1:0]	s_addr_reg;
	reg			s_write_reg;
	reg [DW-1:0]	s_wdata_reg;
	reg [DW/8-1:0]	s_wstrb_reg;
	reg [2:0]		s_prot_reg;
	reg [DW-1:0]	m_rdata_reg;
	reg			m_slverr_reg;
	reg			req_valid;
	reg			req_accepted;
	reg			resp_valid;

	// Source clock domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			req_valid <= 1'b0;
			req_accepted <= 1'b0;
			resp_valid <= 1'b0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE && !req_valid) begin
				req_valid <= 1'b1;
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_prot_reg <= S_APB_PPROT;
			end

			if (req_accepted) begin
				req_valid <= 1'b0;
				req_accepted <= 1'b0;
			end

			if (resp_valid) begin
				S_APB_PREADY <= 1'b1;
				resp_valid <= 1'b0;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// Destination clock domain
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			resp_valid <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;

			if (req_valid && !req_accepted) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PADDR <= s_addr_reg;
				M_APB_PWRITE <= s_write_reg;
				M_APB_PWDATA <= s_wdata_reg;
				M_APB_PWSTRB <= s_wstrb_reg;
				M_APB_PPROT <= s_prot_reg;
				req_accepted <= 1'b1;
			end

			if (M_APB_PENABLE && M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				m_rdata_reg <= M_APB_PRDATA;
				m_slverr_reg <= M_APB_PSLVERR;
				resp_valid <= 1'b1;
			end else if (M_APB_PSEL) begin
				M_APB_PENABLE <= 1'b1;
			end
		end
	end

	// Registered or combinational output
	generate
		if (OPT_REGISTERED) begin : registered_outputs
			reg [DW-1:0]	s_prdata_reg;
			reg			s_pslverr_reg;

			always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
				if (!S_PRESETn) begin
					s_prdata_reg <= 0;
					s_pslverr_reg <= 0;
				end else if (resp_valid) begin
					s_prdata_reg <= m_rdata_reg;
					s_pslverr_reg <= m_slverr_reg;
				end
			end

			assign S_APB_PRDATA = s_prdata_reg;
			assign S_APB_PSLVERR = s_pslverr_reg;
		end else begin : combinational_outputs
			assign S_APB_PRDATA = m_rdata_reg;
			assign S_APB_PSLVERR = m_slverr_reg;
		end
	endgenerate

endmodule
