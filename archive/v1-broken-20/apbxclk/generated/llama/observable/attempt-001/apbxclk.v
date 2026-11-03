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

reg	[AW-1:0]	m_paddr;
reg			m_pwrite;
reg	[DW-1:0]	m_pwdata;
reg	[DW/8-1:0]	m_pwstrb;
reg	[2:0]		m_pprot;
reg			m_psel;
reg			m_penable;
reg			m_pready;
reg	[DW-1:0]	m_prdata;
reg			m_pslverr;
reg			s_pready;
reg			s_pslverr;
reg	[DW-1:0]	s_prdata;

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		s_pready <= 1'b0;
		s_pslverr <= 1'b0;
		s_prdata <= {DW{1'b0}};
	end else if (S_APB_PSEL && S_APB_PENABLE) begin
		s_pready <= 1'b1;
		s_pslverr <= 1'b0;
		s_prdata <= {DW{1'b0}};
	end else if (m_pready && m_penable) begin
		s_pready <= 1'b0;
		s_pslverr <= m_pslverr;
		s_prdata <= m_prdata;
	end else begin
		s_pready <= 1'b0;
		s_pslverr <= 1'b0;
		s_prdata <= {DW{1'b0}};
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
	if (!M_PRESETn) begin
		m_paddr <= {AW{1'b0}};
		m_pwrite <= 1'b0;
		m_pwdata <= {DW{1'b0}};
		m_pwstrb <= {DW/8{1'b0}};
		m_pprot <= {3{1'b0}};
		m_psel <= 1'b0;
		m_penable <= 1'b0;
		m_pready <= 1'b0;
		m_prdata <= {DW{1'b0}};
		m_pslverr <= 1'b0;
		M_PRESETn <= 1'b0;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
		M_APB_PADDR <= {AW{1'b0}};
		M_APB_PWRITE <= 1'b0;
		M_APB_PWDATA <= {DW{1'b0}};
		M_APB_PWSTRB <= {DW/8{1'b0}};
		M_APB_PPROT <= {3{1'b0}};
	end else if (S_APB_PSEL && S_APB_PENABLE && !s_pready) begin
		m_paddr <= S_APB_PADDR;
		m_pwrite <= S_APB_PWRITE;
		m_pwdata <= S_APB_PWDATA;
		m_pwstrb <= S_APB_PWSTRB;
		m_pprot <= S_APB_PPROT;
		m_psel <= 1'b1;
		m_penable <= 1'b0;
		m_pready <= 1'b0;
		m_prdata <= {DW{1'b0}};
		m_pslverr <= 1'b0;
		M_PRESETn <= S_PRESETn;
		M_APB_PSEL <= 1'b1;
		M_APB_PENABLE <= 1'b0;
		M_APB_PADDR <= S_APB_PADDR;
		M_APB_PWRITE <= S_APB_PWRITE;
		M_APB_PWDATA <= S_APB_PWDATA;
		M_APB_PWSTRB <= S_APB_PWSTRB;
		M_APB_PPROT <= S_APB_PPROT;
	end else if (M_APB_PREADY && !m_penable) begin
		m_psel <= 1'b1;
		m_penable <= 1'b1;
		M_APB_PSEL <= 1'b1;
		M_APB_PENABLE <= 1'b1;
	end else if (M_APB_PREADY && m_penable) begin
		m_psel <= 1'b0;
		m_penable <= 1'b0;
		m_pready <= 1'b1;
		m_prdata <= M_APB_PRDATA;
		m_pslverr <= M_APB_PSLVERR;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
	end else begin
		m_psel <= 1'b0;
		m_penable <= 1'b0;
		m_pready <= 1'b0;
		m_prdata <= {DW{1'b0}};
		m_pslverr <= 1'b0;
		M_PRESETn <= S_PRESETn;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
	end
end

assign S_APB_PREADY = s_pready;
assign S_APB_PSLVERR = s_pslverr;
assign S_APB_PRDATA = s_prdata;

endmodule
