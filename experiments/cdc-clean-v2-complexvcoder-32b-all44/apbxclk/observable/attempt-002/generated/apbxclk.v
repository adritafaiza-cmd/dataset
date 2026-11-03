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
	reg [AW-1:0]	s_req_addr;
	reg		s_req_write;
	reg [DW-1:0]	s_req_wdata;
	reg [DW/8-1:0]	s_req_wstrb;
	reg [2:0]		s_req_prot;
	reg [AW-1:0]	m_req_addr;
	reg		m_req_write;
	reg [DW-1:0]	m_req_wdata;
	reg [DW/8-1:0]	m_req_wstrb;
	reg [2:0]		m_req_prot;
	reg		s_req_valid;
	reg		s_req_ready;
	reg		m_req_valid;
	reg		m_req_ready;
	reg [DW-1:0]	s_resp_rdata;
	reg		s_resp_slverr;
	reg [DW-1:0]	m_resp_rdata;
	reg		m_resp_slverr;
	reg		s_resp_valid;
	reg		s_resp_ready;
	reg		m_resp_valid;
	reg		m_resp_ready;
	reg		s_req_valid_synced;
	reg		m_req_valid_synced;
	reg		s_resp_valid_synced;
	reg		m_resp_valid_synced;

	// Synchronizers for request and response valid signals
	synchronizer #(.WIDTH(1)) sync_s_req_valid (
		.clk_dst(M_APB_PCLK),
		.rst_n(M_PRESETn),
		.d_src(s_req_valid),
		.q_dst(s_req_valid_synced)
	);

	synchronizer #(.WIDTH(1)) sync_m_req_valid (
		.clk_dst(S_APB_PCLK),
		.rst_n(S_PRESETn),
		.d_src(m_req_valid),
		.q_dst(m_req_valid_synced)
	);

	synchronizer #(.WIDTH(1)) sync_s_resp_valid (
		.clk_dst(M_APB_PCLK),
		.rst_n(M_PRESETn),
		.d_src(s_resp_valid),
		.q_dst(s_resp_valid_synced)
	);

	synchronizer #(.WIDTH(1)) sync_m_resp_valid (
		.clk_dst(S_APB_PCLK),
		.rst_n(S_PRESETn),
		.d_src(m_resp_valid),
		.q_dst(m_resp_valid_synced)
	);

	// Master side logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_PRESETn <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m_req_valid <= 1'b0;
			m_resp_ready <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;
			m_req_ready <= s_req_valid_synced;

			if (s_req_valid_synced && !m_req_valid) begin
				m_req_addr <= s_req_addr;
				m_req_write <= s_req_write;
				m_req_wdata <= s_req_wdata;
				m_req_wstrb <= s_req_wstrb;
				m_req_prot <= s_req_prot;
				m_req_valid <= 1'b1;
			end

			if (m_req_valid && M_APB_PREADY) begin
				m_req_valid <= 1'b0;
			end

			m_resp_valid <= m_req_valid && M_APB_PREADY;
			m_resp_ready <= s_resp_ready;
		end
	end

	// Slave side logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			s_req_valid <= 1'b0;
			s_resp_ready <= 1'b0;
		end else begin
			S_APB_PREADY <= m_req_valid_synced;
			s_req_ready <= m_req_ready;

			if (S_APB_PSEL && S_APB_PENABLE && !s_req_valid) begin
				s_req_addr <= S_APB_PADDR;
				s_req_write <= S_APB_PWRITE;
				s_req_wdata <= S_APB_PWDATA;
				s_req_wstrb <= S_APB_PWSTRB;
				s_req_prot <= S_APB_PPROT;
				s_req_valid <= 1'b1;
			end

			if (s_req_valid && m_req_ready) begin
				s_req_valid <= 1'b0;
			end

			s_resp_valid <= m_resp_valid_synced;
			s_resp_ready <= m_resp_ready;

			if (m_resp_valid_synced) begin
				s_resp_rdata <= M_APB_PRDATA;
				s_resp_slverr <= M_APB_PSLVERR;
			end
		end
	end

	// Assign output signals
	assign S_APB_PRDATA = s_resp_rdata;
	assign S_APB_PSLVERR = s_resp_slverr;
	assign M_APB_PADDR = m_req_addr;
	assign M_APB_PWRITE = m_req_write;
	assign M_APB_PWDATA = m_req_wdata;
	assign M_APB_PWSTRB = m_req_wstrb;
	assign M_APB_PPROT = m_req_prot;

endmodule

module synchronizer #(
		parameter WIDTH = 1
	) (
		input	wire	clk_dst,
		input	wire	rst_n,
		input	wire	[WIDTH-1:0]	d_src,
		output	reg	[WIDTH-1:0]	q_dst
	);

	// Two-stage synchronizer
	reg [WIDTH-1:0]	q_reg1, q_reg2;

	always @(posedge clk_dst or negedge rst_n) begin
		if (!rst_n) begin
			q_reg1 <= {WIDTH{1'b0}};
			q_reg2 <= {WIDTH{1'b0}};
			q_dst <= {WIDTH{1'b0}};
		end else begin
			q_reg1 <= d_src;
			q_reg2 <= q_reg1;
			q_dst <= q_reg2;
		end
	end

endmodule
