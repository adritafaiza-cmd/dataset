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

reg [AW-1:0] addr_sync;
reg [DW-1:0] wdata_sync;
reg [DW/8-1:0] wstrb_sync;
reg [2:0] prot_sync;
reg write_sync;
reg sel_sync;
reg enable_sync;
reg presetn_sync;

wire req_sync;
wire ack_sync;

assign req_sync = sel_sync && enable_sync;
assign ack_sync = M_APB_PREADY && M_APB_PSEL;

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		sel_sync <= 1'b0;
		enable_sync <= 1'b0;
	end
	else
	begin
		sel_sync <= S_APB_PSEL;
		enable_sync <= S_APB_PENABLE;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn)
	begin
		M_PRESETn <= 1'b0;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
	end
	else
	begin
		M_PRESETn <= S_PRESETn;
		M_APB_PSEL <= req_sync;
		M_APB_PENABLE <= req_sync;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		addr_sync <= {AW{1'b0}};
		wdata_sync <= {DW{1'b0}};
		wstrb_sync <= {DW/8{1'b0}};
		prot_sync <= {3{1'b0}};
		write_sync <= 1'b0;
	end
	else if (S_APB_PSEL && S_APB_PENABLE)
	begin
		addr_sync <= S_APB_PADDR;
		wdata_sync <= S_APB_PWDATA;
		wstrb_sync <= S_APB_PWSTRB;
		prot_sync <= S_APB_PPROT;
		write_sync <= S_APB_PWRITE;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn)
	begin
		M_APB_PADDR <= {AW{1'b0}};
		M_APB_PWRITE <= 1'b0;
		M_APB_PWDATA <= {DW{1'b0}};
		M_APB_PWSTRB <= {DW/8{1'b0}};
		M_APB_PPROT <= {3{1'b0}};
	end
	else if (req_sync)
	begin
		M_APB_PADDR <= addr_sync;
		M_APB_PWRITE <= write_sync;
		M_APB_PWDATA <= wdata_sync;
		M_APB_PWSTRB <= wstrb_sync;
		M_APB_PPROT <= prot_sync;
	end
end

reg [DW-1:0] rdata_sync;
reg slverr_sync;

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn)
	begin
		rdata_sync <= {DW{1'b0}};
		slverr_sync <= 1'b0;
	end
	else if (ack_sync)
	begin
		rdata_sync <= M_APB_PRDATA;
		slverr_sync <= M_APB_PSLVERR;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		S_APB_PRDATA <= {DW{1'b0}};
		S_APB_PSLVERR <= 1'b0;
	end
	else
	begin
		S_APB_PRDATA <= rdata_sync;
		S_APB_PSLVERR <= slverr_sync;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		S_APB_PREADY <= 1'b0;
	end
	else
	begin
		S_APB_PREADY <= ack_sync;
	end
end

endmodule
