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

reg [AW-1:0] m_apb_paddr;
reg m_apb_pwrite;
reg [DW-1:0] m_apb_pwdata;
reg [DW/8-1:0] m_apb_pwstrb;
reg [2:0] m_apb_pprot;
wire m_apb_pready;

reg s_apb_pready_reg;
reg s_apb_pready_reg1;

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		s_apb_pready_reg <= 1'b0;
		s_apb_pready_reg1 <= 1'b0;
	end else begin
		s_apb_pready_reg <= M_APB_PREADY;
		s_apb_pready_reg1 <= s_apb_pready_reg;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		M_PRESETn <= 1'b0;
	end else begin
		M_PRESETn <= 1'b1;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
		M_APB_PADDR <= 1'b0;
		M_APB_PWRITE <= 1'b0;
		M_APB_PWDATA <= 1'b0;
		M_APB_PWSTRB <= 1'b0;
		M_APB_PPROT <= 1'b0;
	end else begin
		if (S_APB_PSEL && S_APB_PENABLE) begin
			M_APB_PSEL <= 1'b1;
			M_APB_PENABLE <= 1'b1;
			M_APB_PADDR <= S_APB_PADDR;
			M_APB_PWRITE <= S_APB_PWRITE;
			M_APB_PWDATA <= S_APB_PWDATA;
			M_APB_PWSTRB <= S_APB_PWSTRB;
			M_APB_PPROT <= S_APB_PPROT;
		end else begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end
	end
end

assign S_APB_PREADY = s_apb_pready_reg1;

assign S_APB_PRDATA = M_APB_PRDATA;

assign S_APB_PSLVERR = M_APB_PSLVERR;

endmodule
