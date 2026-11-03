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

reg [AW-1:0] m_apb_paddr_reg;
reg m_apb_pwrite_reg;
reg [DW-1:0] m_apb_pwdata_reg;
reg [DW/8-1:0] m_apb_pwstrb_reg;
reg [2:0] m_apb_pprot_reg;
reg m_apb_psel_reg;
reg m_apb_penable_reg;
wire m_apb_pready_reg;

wire s_apb_pready_reg;

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		m_apb_paddr_reg <= 0;
		m_apb_pwrite_reg <= 0;
		m_apb_pwdata_reg <= 0;
		m_apb_pwstrb_reg <= 0;
		m_apb_pprot_reg <= 0;
		m_apb_psel_reg <= 0;
		m_apb_penable_reg <= 0;
		s_apb_pready_reg <= 0;
	end else begin
		if (S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY) begin
			m_apb_paddr_reg <= S_APB_PADDR;
			m_apb_pwrite_reg <= S_APB_PWRITE;
			m_apb_pwdata_reg <= S_APB_PWDATA;
			m_apb_pwstrb_reg <= S_APB_PWSTRB;
			m_apb_pprot_reg <= S_APB_PPROT;
			m_apb_psel_reg <= 1;
			m_apb_penable_reg <= 1;
		end else begin
			m_apb_psel_reg <= 0;
			m_apb_penable_reg <= 0;
		end
		s_apb_pready_reg <= S_APB_PREADY;
	end
end

assign S_APB_PREADY = s_apb_pready_reg;

always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		M_PRESETn <= 1;
		M_APB_PADDR <= 0;
		M_APB_PWRITE <= 0;
		M_APB_PWDATA <= 0;
		M_APB_PWSTRB <= 0;
		M_APB_PPROT <= 0;
	end else begin
		if (m_apb_psel_reg && m_apb_penable_reg && !M_APB_PREADY) begin
			M_APB_PADDR <= m_apb_paddr_reg;
			M_APB_PWRITE <= m_apb_pwrite_reg;
			M_APB_PWDATA <= m_apb_pwdata_reg;
			M_APB_PWSTRB <= m_apb_pwstrb_reg;
			M_APB_PPROT <= m_apb_pprot_reg;
		end else begin
			M_APB_PADDR <= 0;
			M_APB_PWRITE <= 0;
			M_APB_PWDATA <= 0;
			M_APB_PWSTRB <= 0;
			M_APB_PPROT <= 0;
		end
		M_PRESETn <= 0;
	end
end

assign M_APB_PSEL = m_apb_psel_reg;
assign M_APB_PENABLE = m_apb_penable_reg;
assign M_APB_PADDR = m_apb_paddr_reg;
assign M_APB_PWRITE = m_apb_pwrite_reg;
assign M_APB_PWDATA = m_apb_pwdata_reg;
assign M_APB_PWSTRB = m_apb_pwstrb_reg;
assign M_APB_PPROT = m_apb_pprot_reg;

assign S_APB_PRDATA = M_APB_PRDATA;
assign S_APB_PSLVERR = M_APB_PSLVERR;

endmodule
