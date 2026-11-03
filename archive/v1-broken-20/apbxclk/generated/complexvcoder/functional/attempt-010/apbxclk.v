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
	reg [AW-1:0] core_S_APB_PADDR;
	reg [DW-1:0] core_S_APB_PWDATA;
	reg [DW/8-1:0] core_S_APB_PWSTRB;
	reg core_S_APB_PWRITE;
	reg core_S_APB_PENABLE;
	reg core_S_APB_PSEL;
	reg [DW-1:0] core_S_APB_PRDATA;
	reg core_S_APB_PSLVERR;
	reg core_M_APB_PREADY;

	// Instantiate the core logic module
	apbxclk_core core (
		.S_APB_PCLK(S_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.S_APB_PSEL(core_S_APB_PSEL),
		.S_APB_PENABLE(core_S_APB_PENABLE),
		.S_APB_PREADY(core_S_APB_PREADY),
		.S_APB_PADDR(core_S_APB_PADDR),
		.S_APB_PWRITE(core_S_APB_PWRITE),
		.S_APB_PWDATA(core_S_APB_PWDATA),
		.S_APB_PWSTRB(core_S_APB_PWSTRB),
		.S_APB_PPROT(S_APB_PPROT),
		.S_APB_PRDATA(core_S_APB_PRDATA),
		.S_APB_PSLVERR(core_S_APB_PSLVERR),
		.M_APB_PCLK(M_APB_PCLK),
		.M_PRESETn(M_PRESETn),
		.M_APB_PSEL(M_APB_PSEL),
		.M_APB_PENABLE(M_APB_PENABLE),
		.M_APB_PREADY(core_M_APB_PREADY),
		.M_APB_PADDR(M_APB_PADDR),
		.M_APB_PWRITE(M_APB_PWRITE),
		.M_APB_PWDATA(M_APB_PWDATA),
		.M_APB_PWSTRB(M_APB_PWSTRB),
		.M_APB_PPROT(M_APB_PPROT),
		.M_APB_PRDATA(M_APB_PRDATA),
		.M_APB_PSLVERR(M_APB_PSLVERR)
	);

	// S_APB_PREADY logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 0;
		end else begin
			S_APB_PREADY <= core_S_APB_PREADY;
		end
	end

	// M_PRESETn logic
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1;
		end else begin
			M_PRESETn <= S_PRESETn;
		end
	end

	// Core to S_APB signal mapping
	assign S_APB_PRDATA = core_S_APB_PRDATA;
	assign S_APB_PSLVERR = core_S_APB_PSLVERR;

	// Core to M_APB signal mapping
	assign M_APB_PSEL = core_S_APB_PSEL;
	assign M_APB_PENABLE = core_S_APB_PENABLE;
	assign M_APB_PADDR = core_S_APB_PADDR;
	assign M_APB_PWRITE = core_S_APB_PWRITE;
	assign M_APB_PWDATA = core_S_APB_PWDATA;
	assign M_APB_PWSTRB = core_S_APB_PWSTRB;
	assign M_APB_PPROT = S_APB_PPROT;

endmodule
