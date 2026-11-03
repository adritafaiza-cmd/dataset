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
	wire	[AW-1:0]	m_apb_paddr;
	wire			m_apb_pwrite;
	wire	[DW-1:0]	m_apb_pwdata;
	wire	[DW/8-1:0]	m_apb_pwstrb;
	wire	[2:0]		m_apb_pprot;
	wire			m_apb_psel;
	wire			m_apb_penable;
	wire			m_apb_pready;
	wire	[DW-1:0]	m_apb_prdata;
	wire			m_apb_pslverr;

	wire			s_apb_pready;

	// Register crossing logic
	wire	[AW-1:0]	s_apb_paddr_reg;
	wire			s_apb_pwrite_reg;
	wire	[DW-1:0]	s_apb_pwdata_reg;
	wire	[DW/8-1:0]	s_apb_pwstrb_reg;
	wire	[2:0]		s_apb_pprot_reg;
	wire			s_apb_psel_reg;
	wire			s_apb_penable_reg;
	wire			s_apb_pready_reg;
	wire	[DW-1:0]	s_apb_prdata_reg;
	wire			s_apb_pslverr_reg;

	wire			m_apb_paddr_reg;
	wire			m_apb_pwrite_reg;
	wire	[DW-1:0]	m_apb_pwdata_reg;
	wire	[DW/8-1:0]	m_apb_pwstrb_reg;
	wire	[2:0]		m_apb_pprot_reg;
	wire			m_apb_psel_reg;
	wire			m_apb_penable_reg;
	wire			m_apb_pready_reg;
	wire	[DW-1:0]	m_apb_prdata_reg;
	wire			m_apb_pslverr_reg;

	// Instantiate CDC primitives
	cdc_sync #(.WIDTH(AW), .DST_REG(OPT_REGISTERED)) cdc_apb_addr (
		.clk_src(S_APB_PCLK),
		.clk_dst(M_APB_PCLK),
		.din(S_APB_PADDR),
		.dout(m_apb_paddr_reg)
	);

	cdc_sync #(.WIDTH(1), .DST_REG(OPT_REGISTERED)) cdc_apb_write (
		.clk_src(S_APB_PCLK),
		.clk_dst(M_APB_PCLK),
		.din(S_APB_PWRITE),
		.dout(m_apb_pwrite_reg)
	);

	cdc_sync #(.WIDTH(DW), .DST_REG(OPT_REGISTERED)) cdc_apb_pwdata (
		.clk_src(S_APB_PCLK),
		.clk_dst(M_APB_PCLK),
		.din(S_APB_PWDATA),
		.dout(m_apb_pwdata_reg)
	);

	cdc_sync #(.WIDTH(DW/8), .DST_REG(OPT_REGISTERED)) cdc_apb_pwstrb (
		.clk_src(S_APB_PCLK),
		.clk_dst(M_APB_PCLK),
		.din(S_APB_PWSTRB),
		.dout(m_apb_pwstrb_reg)
	);

	cdc_sync #(.WIDTH(3), .DST_REG(OPT_REGISTERED)) cdc_apb_pprot (
		.clk_src(S_APB_PCLK),
		.clk_dst(M_APB_PCLK),
		.din(S_APB_PPROT),
		.dout(m_apb_pprot_reg)
	);

	cdc_sync #(.WIDTH(1), .DST_REG(OPT_REGISTERED)) cdc_apb_psel (
		.clk_src(S_APB_PCLK),
		.clk_dst(M_APB_PCLK),
		.din(S_APB_PSEL),
		.dout(m_apb_psel_reg)
	);

	cdc_sync #(.WIDTH(1), .DST_REG(OPT_REGISTERED)) cdc_apb_penable (
		.clk_src(S_APB_PCLK),
		.clk_dst(M_APB_PCLK),
		.din(S_APB_PENABLE),
		.dout(m_apb_penable_reg)
	);

	cdc_sync #(.WIDTH(1), .DST_REG(OPT_REGISTERED)) cdc_apb_pready (
		.clk_src(M_APB_PCLK),
		.clk_dst(S_APB_PCLK),
		.din(M_APB_PREADY),
		.dout(s_apb_pready_reg)
	);

	cdc_sync #(.WIDTH(DW), .DST_REG(OPT_REGISTERED)) cdc_apb_prdata (
		.clk_src(M_APB_PCLK),
		.clk_dst(S_APB_PCLK),
		.din(M_APB_PRDATA),
		.dout(s_apb_prdata_reg)
	);

	cdc_sync #(.WIDTH(1), .DST_REG(OPT_REGISTERED)) cdc_apb_pslverr (
		.clk_src(M_APB_PCLK),
		.clk_dst(S_APB_PCLK),
		.din(M_APB_PSLVERR),
		.dout(s_apb_pslverr_reg)
	);

	// Register crossing logic for S_APB side
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_pready <= 1'b0;
			s_apb_prdata <= {DW{1'b0}};
			s_apb_pslverr <= 1'b0;
		end else begin
			s_apb_pready <= s_apb_pready_reg;
			s_apb_prdata <= s_apb_prdata_reg;
			s_apb_pslverr <= s_apb_pslverr_reg;
		end
	end

	// Register crossing logic for M_APB side
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b1;
		end else begin
			M_PRESETn <= 1'b0;
		end
	end

	// M_APB interface
	assign M_APB_PSEL = m_apb_psel_reg;
	assign M_APB_PENABLE = m_apb_penable_reg;
	assign M_APB_PADDR = m_apb_paddr_reg;
	assign M_APB_PWRITE = m_apb_pwrite_reg;
	assign M_APB_PWDATA = m_apb_pwdata_reg;
	assign M_APB_PWSTRB = m_apb_pwstrb_reg;
	assign M_APB_PPROT = m_apb_pprot_reg;

	// S_APB interface
	assign S_APB_PREADY = s_apb_pready_reg;
	assign S_APB_PRDATA = s_apb_prdata_reg;
	assign S_APB_PSLVERR = s_apb_pslverr_reg;

endmodule
