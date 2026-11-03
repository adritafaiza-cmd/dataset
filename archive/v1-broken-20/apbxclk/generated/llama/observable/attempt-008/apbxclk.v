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

reg			m_psel;
reg			m_penable;

always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
	if (!M_PRESETn) begin
		m_psel <= 1'b0;
		m_penable <= 1'b0;
	end else if (m_valid && M_APB_PREADY) begin
		m_psel <= 1'b0;
		m_penable <= 1'b0;
	end else if (m_valid) begin
		m_psel <= 1'b1;
		m_penable <= 1'b1;
	end else begin
		m_psel <= 1'b0;
		m_penable <= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
	if (!M_PRESETn) begin
		m_addr <= {AW{1'b0}};
		m_write <= 1'b0;
		m_wdata <= {DW{1'b0}};
		m_wstrb <= {DW/8{1'b0}};
		m_prot <= 3'b0;
		m_valid <= 1'b0;
	end else if (m_valid && M_APB_PREADY) begin
		m_addr <= {AW{1'b0}};
		m_write <= 1'b0;
		m_wdata <= {DW{1'b0}};
		m_wstrb <= {DW/8{1'b0}};
		m_prot <= 3'b0;
		m_valid <= 1'b0;
	end else if (S_APB_PSEL && S_APB_PENABLE && S_PRESETn) begin
		m_addr <= S_APB_PADDR;
		m_write <= S_APB_PWRITE;
		m_wdata <= S_APB_PWDATA;
		m_wstrb <= S_APB_PWSTRB;
		m_prot <= S_APB_PPROT;
		m_valid <= 1'b1;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		S_APB_PREADY <= 1'b0;
	end else if (m_ready) begin
		S_APB_PREADY <= 1'b1;
	end else begin
		S_APB_PREADY <= 1'b0;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		S_APB_PRDATA <= {DW{1'b0}};
		S_APB_PSLVERR <= 1'b0;
	end else if (m_ready) begin
		S_APB_PRDATA <= s_rdata;
		S_APB_PSLVERR <= s_error;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
	if (!M_PRESETn) begin
		s_rdata <= {DW{1'b0}};
		s_error <= 1'b0;
		m_ready <= 1'b0;
	end else if (M_APB_PREADY && m_valid) begin
		s_rdata <= M_APB_PRDATA;
		s_error <= M_APB_PSLVERR;
		m_ready <= 1'b1;
	end else if (m_valid && m_ready) begin
		s_rdata <= {DW{1'b0}};
		s_error <= 1'b0;
		m_ready <= 1'b0;
	end
end

assign M_PRESETn = S_PRESETn;
assign M_APB_PADDR = m_addr;
assign M_APB_PWRITE = m_write;
assign M_APB_PWDATA = m_wdata;
assign M_APB_PWSTRB = m_wstrb;
assign M_APB_PPROT = m_prot;
assign M_APB_PSEL = m_psel;
assign M_APB_PENABLE = m_penable;

endmodule
