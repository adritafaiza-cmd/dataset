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

reg [AW-1:0] addr;
reg [DW-1:0] wdata;
reg [DW/8-1:0] wstrb;
reg [2:0] prot;
reg write;
reg valid;
reg [DW-1:0] rdata;
reg slverr;

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		S_APB_PREADY <= 1'b0;
		valid <= 1'b0;
	end
	else if (S_APB_PSEL && !S_APB_PENABLE)
	begin
		addr <= S_APB_PADDR;
		wdata <= S_APB_PWDATA;
		wstrb <= S_APB_PWSTRB;
		prot <= S_APB_PPROT;
		write <= S_APB_PWRITE;
		valid <= 1'b1;
	end
	else if (valid && S_APB_PENABLE)
	begin
		S_APB_PREADY <= 1'b1;
		valid <= 1'b0;
	end
	else
	begin
		S_APB_PREADY <= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		M_PRESETn <= 1'b0;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
	end
	else if (valid)
	begin
		M_PRESETn <= 1'b1;
		M_APB_PSEL <= 1'b1;
		M_APB_PADDR <= addr;
		M_APB_PWRITE <= write;
		M_APB_PWDATA <= wdata;
		M_APB_PWSTRB <= wstrb;
		M_APB_PPROT <= prot;
	end
	else
	begin
		M_PRESETn <= 1'b1;
		M_APB_PSEL <= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		M_APB_PENABLE <= 1'b0;
	end
	else if (M_APB_PSEL && !M_APB_PENABLE)
	begin
		M_APB_PENABLE <= 1'b1;
	end
	else if (M_APB_PREADY)
	begin
		M_APB_PENABLE <= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		rdata <= {DW{1'b0}};
		slverr <= 1'b0;
	end
	else if (M_APB_PREADY)
	begin
		rdata <= M_APB_PRDATA;
		slverr <= M_APB_PSLVERR;
	end
end

assign S_APB_PRDATA = rdata;
assign S_APB_PSLVERR = slverr;

endmodule
