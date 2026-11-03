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
reg			s_pready;
reg			m_presetn;
reg			m_psel_reg;
reg			m_penable_reg;
reg	[DW-1:0]	s_prdata;
reg			s_pslverr;
reg			s_req;
reg			m_req;
reg			m_ack;

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		s_pready <= 1'b0;
		s_req <= 1'b0;
	end
	else
	begin
		if (S_APB_PSEL && S_APB_PENABLE)
		begin
			s_pready <= 1'b1;
			s_req <= 1'b1;
		end
		else if (m_ack)
		begin
			s_pready <= 1'b0;
			s_req <= 1'b0;
		end
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn)
	begin
		m_psel_reg <= 1'b0;
		m_penable_reg <= 1'b0;
		m_req <= 1'b0;
		m_ack <= 1'b0;
	end
	else
	begin
		if (s_req && !m_req)
		begin
			m_psel_reg <= 1'b1;
			m_penable_reg <= 1'b1;
			m_req <= 1'b1;
		end
		else if (M_APB_PREADY && m_penable_reg)
		begin
			m_psel_reg <= 1'b0;
			m_penable_reg <= 1'b0;
			m_req <= 1'b0;
			m_ack <= 1'b1;
		end
		else if (m_ack && !M_APB_PREADY)
		begin
			m_ack <= 1'b0;
		end
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		s_prdata <= {DW{1'b0}};
		s_pslverr <= 1'b0;
	end
	else if (m_ack)
	begin
		s_prdata <= M_APB_PRDATA;
		s_pslverr <= M_APB_PSLVERR;
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn)
	begin
		m_paddr <= {AW{1'b0}};
		m_pwrite <= 1'b0;
		m_pwdata <= {DW{1'b0}};
		m_pwstrb <= {DW/8{1'b0}};
		m_pprot <= {3{1'b0}};
	end
	else if (s_req && !m_req)
	begin
		m_paddr <= S_APB_PADDR;
		m_pwrite <= S_APB_PWRITE;
		m_pwdata <= S_APB_PWDATA;
		m_pwstrb <= S_APB_PWSTRB;
		m_pprot <= S_APB_PPROT;
	end
end

assign M_PRESETn = S_PRESETn;
assign M_APB_PSEL = m_psel_reg;
assign M_APB_PENABLE = m_penable_reg;
assign M_APB_PADDR = m_paddr;
assign M_APB_PWRITE = m_pwrite;
assign M_APB_PWDATA = m_pwdata;
assign M_APB_PWSTRB = m_pwstrb;
assign M_APB_PPROT = m_pprot;
assign S_APB_PREADY = s_pready;
assign S_APB_PRDATA = s_prdata;
assign S_APB_PSLVERR = s_pslverr;

endmodule
