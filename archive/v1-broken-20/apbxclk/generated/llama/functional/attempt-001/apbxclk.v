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

reg [AW-1:0] addr_reg;
reg [DW-1:0] data_reg;
reg [DW/8-1:0] strb_reg;
reg [2:0] prot_reg;
reg write_reg;
reg sel_reg;
reg enable_reg;
reg presetn_reg;
reg [DW-1:0] rdata_reg;
reg slverr_reg;

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		S_APB_PREADY <= 1'b0;
		sel_reg <= 1'b0;
		enable_reg <= 1'b0;
	end else if (S_APB_PSEL && !S_APB_PENABLE) begin
		sel_reg <= 1'b1;
		enable_reg <= 1'b0;
		addr_reg <= S_APB_PADDR;
		write_reg <= S_APB_PWRITE;
		data_reg <= S_APB_PWDATA;
		strb_reg <= S_APB_PWSTRB;
		prot_reg <= S_APB_PPROT;
	end else if (S_APB_PSEL && S_APB_PENABLE) begin
		sel_reg <= 1'b1;
		enable_reg <= 1'b1;
	end else if (!S_APB_PSEL) begin
		sel_reg <= 1'b0;
		enable_reg <= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		presetn_reg <= 1'b0;
		M_PRESETn <= 1'b0;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
		M_APB_PADDR <= {AW{1'b0}};
		M_APB_PWRITE <= 1'b0;
		M_APB_PWDATA <= {DW{1'b0}};
		M_APB_PWSTRB <= {DW/8{1'b0}};
		M_APB_PPROT <= 3'b0;
	end else begin
		presetn_reg <= S_PRESETn;
		M_PRESETn <= presetn_reg;
		M_APB_PSEL <= sel_reg;
		M_APB_PENABLE <= enable_reg;
		M_APB_PADDR <= addr_reg;
		M_APB_PWRITE <= write_reg;
		M_APB_PWDATA <= data_reg;
		M_APB_PWSTRB <= strb_reg;
		M_APB_PPROT <= prot_reg;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		rdata_reg <= {DW{1'b0}};
		slverr_reg <= 1'b0;
	end else if (M_APB_PREADY) begin
		rdata_reg <= M_APB_PRDATA;
		slverr_reg <= M_APB_PSLVERR;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		S_APB_PREADY <= 1'b0;
	end else if (M_APB_PREADY && enable_reg) begin
		S_APB_PREADY <= 1'b1;
	end else if (!M_APB_PREADY || !enable_reg) begin
		S_APB_PREADY <= 1'b0;
	end
end

assign S_APB_PRDATA = rdata_reg;
assign S_APB_PSLVERR = slverr_reg;

endmodule
