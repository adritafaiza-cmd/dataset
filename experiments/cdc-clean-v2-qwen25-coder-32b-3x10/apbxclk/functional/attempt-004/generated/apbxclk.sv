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

	reg [AW-1:0]	s_addr_reg;
	reg			s_write_reg;
	reg [DW-1:0]	s_wdata_reg;
	reg [DW/8-1:0]	s_wstrb_reg;
	reg [2:0]		s_prot_reg;
	reg [DW-1:0]	s_rdata_reg;
	reg			s_slverr_reg;
	reg			s_req_valid;
	reg			s_req_accepted;
	reg			m_req_valid;
	reg			m_req_accepted;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {DW/8{1'b0}};
			s_prot_reg <= 3'b000;
			s_req_valid <= 1'b0;
			s_req_accepted <= 1'b0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE && !s_req_valid) begin
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_prot_reg <= S_APB_PPROT;
				s_req_valid <= 1'b1;
			end else if (s_req_accepted) begin
				s_req_valid <= 1'b0;
				s_req_accepted <= 1'b0;
			end

			if (m_req_accepted) begin
				S_APB_PREADY <= 1'b1;
				s_rdata_reg <= M_APB_PRDATA;
				s_slverr_reg <= M_APB_PSLVERR;
			end else if (S_APB_PREADY) begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m_req_valid <= 1'b0;
			m_req_accepted <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;

			if (s_req_valid && !m_req_valid) begin
				M_APB_PSEL <= 1'b1;
				m_req_valid <= 1'b1;
			end else if (M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				m_req_valid <= 1'b0;
				m_req_accepted <= 1'b1;
				s_req_accepted <= 1'b1;
			end

			if (m_req_valid && !OPT_REGISTERED) begin
				M_APB_PENABLE <= 1'b1;
				M_APB_PADDR <= s_addr_reg;
				M_APB_PWRITE <= s_write_reg;
				M_APB_PWDATA <= s_wdata_reg;
				M_APB_PWSTRB <= s_wstrb_reg;
				M_APB_PPROT <= s_prot_reg;
			end else if (OPT_REGISTERED) begin
				reg [AW-1:0]	m_addr_reg;
				reg			m_write_reg;
				reg [DW-1:0]	m_wdata_reg;
				reg [DW/8-1:0]	m_wstrb_reg;
				reg [2:0]		m_prot_reg;

				if (s_req_valid && !m_req_valid) begin
					m_addr_reg <= s_addr_reg;
					m_write_reg <= s_write_reg;
					m_wdata_reg <= s_wdata_reg;
					m_wstrb_reg <= s_wstrb_reg;
					m_prot_reg <= s_prot_reg;
				end

				if (m_req_valid) begin
					M_APB_PENABLE <= 1'b1;
					M_APB_PADDR <= m_addr_reg;
					M_APB_PWRITE <= m_write_reg;
					M_APB_PWDATA <= m_wdata_reg;
					M_APB_PWSTRB <= m_wstrb_reg;
					M_APB_PPROT <= m_prot_reg;
				end else begin
					M_APB_PENABLE <= 1'b0;
				end
			end
		end
	end

	assign S_APB_PRDATA = s_rdata_reg;
	assign S_APB_PSLVERR = s_slverr_reg;

endmodule
