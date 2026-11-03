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

	// Internal signals for cross-domain communication
	wire	[AW-1:0]	m_addr;
	wire			m_write;
	wire	[DW-1:0]	m_wdata;
	wire	[DW/8-1:0]	m_wstrb;
	wire	[2:0]		m_prot;
	wire	[DW-1:0]	m_rdata;
	wire			m_rvalid;
	wire			m_rready;
	wire			m_slverr;

	// Clock-domain crossing for master side
	wire			m_clk;
	wire			m_resetn;

	// Instantiate the clock-domain crossing module
	apb_bridge #(
		.C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
		.C_APB_DATA_WIDTH(C_APB_DATA_WIDTH)
	) bridge (
		.S_APB_PCLK(S_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.S_APB_PSEL(S_APB_PSEL),
		.S_APB_PENABLE(S_APB_PENABLE),
		.S_APB_PREADY(S_APB_PREADY),
		.S_APB_PADDR(S_APB_PADDR),
		.S_APB_PWRITE(S_APB_PWRITE),
		.S_APB_PWDATA(S_APB_PWDATA),
		.S_APB_PWSTRB(S_APB_PWSTRB),
		.S_APB_PPROT(S_APB_PPROT),
		.S_APB_PRDATA(S_APB_PRDATA),
		.S_APB_PSLVERR(S_APB_PSLVERR),
		.M_APB_PCLK(M_APB_PCLK),
		.M_PRESETn(M_PRESETn),
		.M_APB_PSEL(M_APB_PSEL),
		.M_APB_PENABLE(M_APB_PENABLE),
		.M_APB_PREADY(M_APB_PREADY),
		.M_APB_PADDR(M_APB_PADDR),
		.M_APB_PWRITE(M_APB_PWRITE),
		.M_APB_PWDATA(M_APB_PWDATA),
		.M_APB_PWSTRB(M_APB_PWSTRB),
		.M_APB_PPROT(M_APB_PPROT),
		.M_APB_PRDATA(M_APB_PRDATA),
		.M_APB_PSLVERR(M_APB_PSLVERR)
	);

	// Instantiate the clock-domain crossing module
	apb_clk_cross #(
		.C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
		.C_APB_DATA_WIDTH(C_APB_DATA_WIDTH)
	) clk_cross (
		.sclk(S_APB_PCLK),
		.sreset(!S_PRESETn),
		.mclk(M_APB_PCLK),
		.mresetn(!M_PRESETn),
		.s_addr(S_APB_PADDR),
		.s_write(S_APB_PWRITE),
		.s_wdata(S_APB_PWDATA),
		.s_wstrb(S_APB_PWSTRB),
		.s_prot(S_APB_PPROT),
		.s_rdata(m_rdata),
		.s_rvalid(m_rvalid),
		.s_rready(m_rready),
		.s_slverr(m_slverr),
		.m_addr(m_addr),
		.m_write(m_write),
		.m_wdata(m_wdata),
		.m_wstrb(m_wstrb),
		.m_prot(m_prot)
	);

endmodule
