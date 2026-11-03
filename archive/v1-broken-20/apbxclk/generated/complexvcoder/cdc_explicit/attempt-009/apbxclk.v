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

reg [AW-1:0] s_addr, m_addr;
reg s_write, m_write;
reg [DW-1:0] s_wdata, m_wdata;
reg [DW/8-1:0] s_wstrb, m_wstrb;
reg [2:0] s_prot, m_prot;
wire s_ready, m_ready;
wire [DW-1:0] s_prdata;
wire s_slv_err;

register_crossing #(
		.C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
		.C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
		.OPT_REGISTERED(OPT_REGISTERED)
	) s_to_m (
		.s_clk(S_APB_PCLK),
		.s_rst(S_PRESETn),
		.s_sel(S_APB_PSEL),
		.s_enable(S_APB_PENABLE),
		.s_addr(s_addr),
		.s_write(s_write),
		.s_wdata(s_wdata),
		.s_wstrb(s_wstrb),
		.s_prot(s_prot),
		.m_ready(s_ready),
		.m_prdata(s_prdata),
		.m_slv_err(s_slv_err)
	);

register_crossing #(
		.C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
		.C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
		.OPT_REGISTERED(OPT_REGISTERED)
	) m_to_s (
		.s_clk(M_APB_PCLK),
		.s_rst(M_PRESETn),
		.s_sel(M_APB_PSEL),
		.s_enable(M_APB_PENABLE),
		.s_addr(m_addr),
		.s_write(m_write),
		.s_wdata(m_wdata),
		.s_wstrb(m_wstrb),
		.s_prot(m_prot),
		.m_ready(m_ready),
		.m_prdata(S_APB_PRDATA),
		.m_slv_err(S_APB_PSLVERR)
	);

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		S_APB_PREADY <= 1'b0;
		M_PRESETn <= 1'b1;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
	end else begin
		M_APB_PSEL <= s_sel;
		M_APB_PENABLE <= s_enable;
		M_APB_PADDR <= s_addr;
		M_APB_PWRITE <= s_write;
		M_APB_PWDATA <= s_wdata;
		M_APB_PWSTRB <= s_wstrb;
		M_APB_PPROT <= s_prot;
		S_APB_PREADY <= s_ready;
		S_APB_PRDATA <= s_prdata;
		S_APB_PSLVERR <= s_slv_err;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
	if (!M_PRESETn) begin
		M_PRESETn <= 1'b1;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
	end else begin
		M_APB_PSEL <= m_sel;
		M_APB_PENABLE <= m_enable;
		M_APB_PADDR <= m_addr;
		M_APB_PWRITE <= m_write;
		M_APB_PWDATA <= m_wdata;
		M_APB_PWSTRB <= m_wstrb;
		M_APB_PPROT <= m_prot;
	end
end

endmodule

module register_crossing #(
		.parameter	C_APB_ADDR_WIDTH = 12,
		.parameter	C_APB_DATA_WIDTH = 32,
		.parameter [0:0]	OPT_REGISTERED = 1'b0
	) (
		.input	wire			s_clk, s_rst,
		.input	wire			s_sel, s_enable,
		.input	wire	[C_APB_ADDR_WIDTH-1:0]	s_addr,
		.input	wire			s_write,
		.input	wire	[C_APB_DATA_WIDTH-1:0]	s_wdata,
		.input	wire	[C_APB_DATA_WIDTH/8-1:0]	s_wstrb,
		.input	wire	[2:0]		s_prot,
		.output	wire			m_ready,
		.output	wire	[C_APB_DATA_WIDTH-1:0]	m_prdata,
		.output	wire			m_slv_err
	);

reg [C_APB_ADDR_WIDTH-1:0] m_addr;
reg m_write;
reg [C_APB_DATA_WIDTH-1:0] m_wdata;
reg [C_APB_DATA_WIDTH/8-1:0] m_wstrb;
reg [2:0] m_prot;
wire s_ready;

assign m_ready = s_ready;
assign m_prdata = s_prdata;
assign m_slv_err = s_slv_err;

always @(posedge s_clk or negedge s_rst) begin
	if (!s_rst) begin
		m_addr <= 0;
		m_write <= 0;
		m_wdata <= 0;
		m_wstrb <= 0;
		m_prot <= 0;
	end else if (s_sel && s_enable) begin
		m_addr <= s_addr;
		m_write <= s_write;
		m_wdata <= s_wdata;
		m_wstrb <= s_wstrb;
		m_prot <= s_prot;
	end
end

endmodule
