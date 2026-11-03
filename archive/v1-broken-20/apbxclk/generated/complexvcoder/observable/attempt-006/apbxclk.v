module apbxclk #(
	parameter C_APB_ADDR_WIDTH = 12,
	parameter C_APB_DATA_WIDTH = 32,
	parameter [0:0] OPT_REGISTERED = 1'b0,
	localparam AW = C_APB_ADDR_WIDTH,
	localparam DW = C_APB_DATA_WIDTH
) (
	input wire S_APB_PCLK, S_PRESETn,
	input wire S_APB_PSEL,
	input wire S_APB_PENABLE,
	output reg S_APB_PREADY,
	input wire [AW-1:0] S_APB_PADDR,
	input wire S_APB_PWRITE,
	input wire [DW-1:0] S_APB_PWDATA,
	input wire [DW/8-1:0] S_APB_PWSTRB,
	input wire [2:0] S_APB_PPROT,
	output wire [DW-1:0] S_APB_PRDATA,
	output wire S_APB_PSLVERR,
	input wire M_APB_PCLK,
	output reg M_PRESETn,
	output reg M_APB_PSEL,
	output reg M_APB_PENABLE,
	input wire M_APB_PREADY,
	output wire [AW-1:0] M_APB_PADDR,
	output wire M_APB_PWRITE,
	output wire [DW-1:0] M_APB_PWDATA,
	output wire [DW/8-1:0] M_APB_PWSTRB,
	output wire [2:0] M_APB_PPROT,
	input wire [DW-1:0] M_APB_PRDATA,
	input wire M_APB_PSLVERR
);

	// Internal signals
	wire slave_S_APB_PREADY;
	wire slave_S_APB_PRDATA;
	wire slave_S_APB_PSLVERR;
	wire master_M_APB_PSEL;
	wire master_M_APB_PENABLE;
	wire master_M_APB_PADDR;
	wire master_M_APB_PWRITE;
	wire master_M_APB_PWDATA;
	wire master_M_APB_PWSTRB;
	wire master_M_APB_PPROT;

	// Instantiate APB slave
	apb_slave #(
		.C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
		.C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
		.OPT_REGISTERED(OPT_REGISTERED)
	) slave (
		.S_APB_PCLK(S_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.S_APB_PSEL(S_APB_PSEL),
		.S_APB_PENABLE(S_APB_PENABLE),
		.S_APB_PREADY(slave_S_APB_PREADY),
		.S_APB_PADDR(S_APB_PADDR),
		.S_APB_PWRITE(S_APB_PWRITE),
		.S_APB_PWDATA(S_APB_PWDATA),
		.S_APB_PWSTRB(S_APB_PWSTRB),
		.S_APB_PPROT(S_APB_PPROT),
		.S_APB_PRDATA(slave_S_APB_PRDATA),
		.S_APB_PSLVERR(slave_S_APB_PSLVERR)
	);

	// Instantiate APB master
	apb_master #(
		.C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
		.C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
		.OPT_REGISTERED(OPT_REGISTERED)
	) master (
		.M_APB_PCLK(M_APB_PCLK),
		.M_PRESETn(M_PRESETn),
		.M_APB_PSEL(master_M_APB_PSEL),
		.M_APB_PENABLE(master_M_APB_PENABLE),
		.M_APB_PREADY(M_APB_PREADY),
		.M_APB_PADDR(master_M_APB_PADDR),
		.M_APB_PWRITE(master_M_APB_PWRITE),
		.M_APB_PWDATA(master_M_APB_PWDATA),
		.M_APB_PWSTRB(master_M_APB_PWSTRB),
		.M_APB_PPROT(master_M_APB_PPROT),
		.M_APB_PRDATA(M_APB_PRDATA),
		.M_APB_PSLVERR(M_APB_PSLVERR)
	);

	// Instantiate clock crossing logic
	clock_crossing #(
		.C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
		.C_APB_DATA_WIDTH(C_APB_DATA_WIDTH)
	) crossing (
		.S_APB_PCLK(S_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.M_APB_PCLK(M_APB_PCLK),
		.S_APB_PSEL(master_M_APB_PSEL),
		.S_APB_PENABLE(master_M_APB_PENABLE),
		.S_APB_PREADY(slave_S_APB_PREADY),
		.S_APB_PADDR(master_M_APB_PADDR),
		.S_APB_PWRITE(master_M_APB_PWRITE),
		.S_APB_PWDATA(master_M_APB_PWDATA),
		.S_APB_PWSTRB(master_M_APB_PWSTRB),
		.S_APB_PPROT(master_M_APB_PPROT),
		.S_APB_PRDATA(slave_S_APB_PRDATA),
		.S_APB_PSLVERR(slave_S_APB_PSLVERR),
		.M_APB_PSEL(M_APB_PSEL),
		.M_APB_PENABLE(M_APB_PENABLE),
		.M_APB_PREADY(M_APB_PREADY),
		.M_APB_PADDR(M_APB_PADDR),
		.M_APB_PWRITE(M_APB_PWRITE),
		.M_APB_PWDATA(M_APB_PWDATA),
		.M_APB_PWSTRB(M_APB_PWSTRB),
		.M_APB_PPROT(M_APB_PPROT)
	);

endmodule
