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

reg	[AW-1:0]	m_addr;
reg			m_write;
reg	[DW-1:0]	m_wdata;
reg	[DW/8-1:0]	m_wstrb;
reg	[2:0]		m_prot;
reg			m_valid;
reg			m_ready;
reg	[DW-1:0]	s_rdata;
reg			s_error;

wire	s_req = S_APB_PSEL && S_APB_PENABLE;
wire	m_ack = M_APB_PREADY && M_APB_PSEL && M_APB_PENABLE;

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn) begin
		S_APB_PREADY <= 1'b0;
		m_valid <= 1'b0;
	end else if (s_req && !m_valid) begin
		m_addr <= S_APB_PADDR;
		m_write <= S_APB_PWRITE;
		m_wdata <= S_APB_PWDATA;
		m_wstrb <= S_APB_PWSTRB;
		m_prot <= S_APB_PPROT;
		m_valid <= 1'b1;
		S_APB_PREADY <= 1'b1;
	end else if (m_valid && m_ready) begin
		m_valid <= 1'b0;
		S_APB_PREADY <= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn) begin
		M_PRESETn <= 1'b0;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
		m_ready <= 1'b0;
	end else if (m_valid && !m_ready) begin
		M_APB_PSEL <= 1'b1;
		M_APB_PENABLE <= 1'b1;
		M_APB_PADDR <= m_addr;
		M_APB_PWRITE <= m_write;
		M_APB_PWDATA <= m_wdata;
		M_APB_PWSTRB <= m_wstrb;
		M_APB_PPROT <= m_prot;
		m_ready <= 1'b1;
	end else if (m_ack) begin
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
		m_ready <= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn) begin
		s_rdata <= {DW{1'b0}};
		s_error <= 1'b0;
	end else if (m_ack) begin
		s_rdata <= M_APB_PRDATA;
		s_error <= M_APB_PSLVERR;
	end
end

assign S_APB_PRDATA = s_rdata;
assign S_APB_PSLVERR = s_error;

endmodule
