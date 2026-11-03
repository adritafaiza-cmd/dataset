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
	reg			s_req_sync;
	reg			m_req_sync;
	reg			s_req_valid;
	reg			m_req_valid;
	reg			s_req_ready;
	reg			m_req_ready;
	reg	[AW-1:0]	s_req_addr;
	reg			s_req_write;
	reg	[DW-1:0]	s_req_wdata;
	reg	[DW/8-1:0]	s_req_wstrb;
	reg	[2:0]		s_req_prot;
	reg	[AW-1:0]	m_req_addr;
	reg			m_req_write;
	reg	[DW-1:0]	m_req_wdata;
	reg	[DW/8-1:0]	m_req_wstrb;
	reg	[2:0]		m_req_prot;
	reg			m_resp_valid;
	reg			s_resp_valid;
	reg			m_resp_ready;
	reg			s_resp_ready;
	reg	[DW-1:0]	s_resp_rdata;
	reg			s_resp_slverr;
	reg	[DW-1:0]	m_resp_rdata;
	reg			m_resp_slverr;

	// Synchronizers for crossing from S_APB_PCLK to M_APB_PCLK
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_req_sync <= 1'b0;
		end else begin
			s_req_sync <= S_APB_PSEL & S_APB_PENABLE;
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_req_sync <= 1'b0;
		end else begin
			m_req_sync <= s_req_sync;
		end
	end

	// Request handling from slave to master
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_req_valid <= 1'b0;
			m_req_addr <= {AW{1'b0}};
			m_req_write <= 1'b0;
			m_req_wdata <= {DW{1'b0}};
			m_req_wstrb <= {DW/8{1'b0}};
			m_req_prot <= 3'b000;
		end else if (m_req_ready && m_req_valid) begin
			m_req_valid <= 1'b0;
		end else if (!m_req_valid && s_req_sync) begin
			m_req_valid <= 1'b1;
			m_req_addr <= S_APB_PADDR;
			m_req_write <= S_APB_PWRITE;
			m_req_wdata <= S_APB_PWDATA;
			m_req_wstrb <= S_APB_PWSTRB;
			m_req_prot <= S_APB_PPROT;
		end
	end

	// Response handling from master to slave
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_resp_valid <= 1'b0;
			s_resp_rdata <= {DW{1'b0}};
			s_resp_slverr <= 1'b0;
		end else if (s_resp_ready && s_resp_valid) begin
			s_resp_valid <= 1'b0;
		end else if (!s_resp_valid && m_resp_valid) begin
			s_resp_valid <= 1'b1;
			s_resp_rdata <= m_resp_rdata;
			s_resp_slverr <= m_resp_slverr;
		end
	end

	// Handshaking between slave and master
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_req_ready <= 1'b0;
		end else begin
			m_req_ready <= M_APB_PREADY;
		end
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_req_ready <= 1'b0;
		end else begin
			s_req_ready <= m_req_ready;
		end
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_resp_ready <= 1'b0;
		end else begin
			s_resp_ready <= S_APB_PENABLE;
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_resp_ready <= 1'b0;
		end else begin
			m_resp_ready <= s_resp_ready;
		end
	end

	// Master side outputs
	assign M_PRESETn = S_PRESETn;
	assign M_APB_PADDR = m_req_addr;
	assign M_APB_PWRITE = m_req_write;
	assign M_APB_PWDATA = m_req_wdata;
	assign M_APB_PWSTRB = m_req_wstrb;
	assign M_APB_PPROT = m_req_prot;
	assign M_APB_PSEL = m_req_valid;

	// Slave side outputs
	assign S_APB_PREADY = s_req_ready;
	assign S_APB_PRDATA = s_resp_rdata;
	assign S_APB_PSLVERR = s_resp_slverr;

endmodule
