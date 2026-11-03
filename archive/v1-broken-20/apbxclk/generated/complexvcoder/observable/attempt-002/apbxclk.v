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
	reg [AW-1:0] slave_addr;
	reg slave_write;
	reg [DW-1:0] slave_wdata;
	reg [DW/8-1:0] slave_wstrb;
	reg [2:0] slave_prot;
	wire slave_ready;
	wire [DW-1:0] slave_rdata;
	wire slave_rslverr;

	// Instantiate the APB bridge module
	apb_bridge #(
		.C_APB_ADDR_WIDTH(AW),
		.C_APB_DATA_WIDTH(DW),
		.OPT_REGISTERED(OPT_REGISTERED)
	) bridge (
		.S_APB_PCLK(S_APB_PCLK),
		.M_APB_PCLK(M_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.S_APB_PSEL(S_APB_PSEL),
		.S_APB_PENABLE(S_APB_PENABLE),
		.S_APB_PREADY(slave_ready),
		.S_APB_PADDR(slave_addr),
		.S_APB_PWRITE(slave_write),
		.S_APB_PWDATA(slave_wdata),
		.S_APB_PWSTRB(slave_wstrb),
		.S_APB_PPROT(slave_prot),
		.S_APB_PRDATA(slave_rdata),
		.S_APB_PSLVERR(slave_rslverr),
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

	// Assign outputs
	assign S_APB_PRDATA = slave_rdata;
	assign S_APB_PSLVERR = slave_rslverr;

endmodule
