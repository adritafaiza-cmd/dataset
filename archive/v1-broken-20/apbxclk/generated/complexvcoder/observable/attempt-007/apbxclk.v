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

reg [AW-1:0] slave_addr;
reg slave_write;
reg [DW-1:0] slave_wdata;
reg [DW/8-1:0] slave_wstrb;
reg [2:0] slave_prot;
wire [DW-1:0] slave_rdata;
wire slave_rvalid;
wire slave_rready;
wire slave_err;

reg [AW-1:0] master_addr;
reg master_write;
reg [DW-1:0] master_wdata;
reg [DW/8-1:0] master_wstrb;
reg [2:0] master_prot;
wire [DW-1:0] master_rdata;
wire master_rvalid;
wire master_rready;
wire master_err;

// Clock Domain Crossing for Slave to Master
always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		slave_addr <= 0;
		slave_write <= 0;
		slave_wdata <= 0;
		slave_wstrb <= 0;
		slave_prot <= 0;
	end else begin
		slave_addr <= S_APB_PADDR;
		slave_write <= S_APB_PWRITE;
		slave_wdata <= S_APB_PWDATA;
		slave_wstrb <= S_APB_PWSTRB;
		slave_prot <= S_APB_PPROT;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		S_APB_PREADY <= 0;
		S_APB_PRDATA <= 0;
		S_APB_PSLVERR <= 0;
	end else begin
		S_APB_PREADY <= master_rready;
		S_APB_PRDATA <= master_rdata;
		S_APB_PSLVERR <= master_err;
	end
end

// Clock Domain Crossing for Master to Slave
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		master_addr <= 0;
		master_write <= 0;
		master_wdata <= 0;
		master_wstrb <= 0;
		master_prot <= 0;
	end else begin
		master_addr <= slave_addr;
		master_write <= slave_write;
		master_wdata <= slave_wdata;
		master_wstrb <= slave_wstrb;
		master_prot <= slave_prot;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		M_PRESETn <= 0;
		M_APB_PSEL <= 0;
		M_APB_PENABLE <= 0;
	end else begin
		M_PRESETn <= S_PRESETn;
		M_APB_PSEL <= master_rready;
		M_APB_PENABLE <= master_rready;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		M_APB_PADDR <= 0;
		M_APB_PWRITE <= 0;
		M_APB_PWDATA <= 0;
		M_APB_PWSTRB <= 0;
		M_APB_PPROT <= 0;
	end else begin
		M_APB_PADDR <= master_addr;
		M_APB_PWRITE <= master_write;
		M_APB_PWDATA <= master_wdata;
		M_APB_PWSTRB <= master_wstrb;
		M_APB_PPROT <= master_prot;
	end
end

// Master to Slave Data Path
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		slave_rvalid <= 0;
		slave_rready <= 0;
		slave_rdata <= 0;
		slave_err <= 0;
	end else begin
		slave_rvalid <= master_rvalid;
		slave_rready <= master_rready;
		slave_rdata <= master_rdata;
		slave_err <= master_err;
	end
end

endmodule
