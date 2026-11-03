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

reg	[AW-1:0]	m_apb_paddr;
reg			m_apb_pwrite;
reg	[DW-1:0]	m_apb_pwd;
reg	[DW/8-1:0]	m_apb_pwstrb;
reg	[2:0]		m_apb_pprot;
reg			m_apb_psel;
reg			m_apb_penable;
reg			m_apb_pready;
reg	[DW-1:0]	s_apb_prdata;
reg			s_apb_pslverr;
reg			s_apb_pready;
reg			m_presetn;
reg			m_apb_psel_reg;

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		m_apb_paddr	<= {AW{1'b0}};
		m_apb_pwrite	<= 1'b0;
		m_apb_pwd	<= {DW{1'b0}};
		m_apb_pwstrb	<= {DW/8{1'b0}};
		m_apb_pprot	<= {3{1'b0}};
		m_apb_psel	<= 1'b0;
		m_apb_penable	<= 1'b0;
		m_presetn	<= 1'b0;
		m_apb_psel_reg	<= 1'b0;
		s_apb_pready	<= 1'b0;
	end
	else if (S_APB_PSEL && !S_APB_PENABLE)
	begin
		m_apb_paddr	<= S_APB_PADDR;
		m_apb_pwrite	<= S_APB_PWRITE;
		m_apb_pwd	<= S_APB_PWDATA;
		m_apb_pwstrb	<= S_APB_PWSTRB;
		m_apb_pprot	<= S_APB_PPROT;
		m_apb_psel	<= 1'b1;
		m_apb_penable	<= 1'b0;
		m_presetn	<= 1'b1;
		m_apb_psel_reg	<= 1'b1;
		s_apb_pready	<= 1'b0;
	end
	else if (S_APB_PSEL && S_APB_PENABLE)
	begin
		m_apb_penable	<= 1'b1;
	end
	else
	begin
		m_apb_psel	<= 1'b0;
		m_apb_penable	<= 1'b0;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		M_PRESETn	<= 1'b0;
		M_APB_PSEL	<= 1'b0;
		M_APB_PENABLE	<= 1'b0;
		M_APB_PADDR	<= {AW{1'b0}};
		M_APB_PWRITE	<= 1'b0;
		M_APB_PWDATA	<= {DW{1'b0}};
		M_APB_PWSTRB	<= {DW/8{1'b0}};
		M_APB_PPROT	<= {3{1'b0}};
	end
	else
	begin
		M_PRESETn	<= m_presetn;
		M_APB_PSEL	<= m_apb_psel;
		M_APB_PENABLE	<= m_apb_penable;
		M_APB_PADDR	<= m_apb_paddr;
		M_APB_PWRITE	<= m_apb_pwrite;
		M_APB_PWDATA	<= m_apb_pwd;
		M_APB_PWSTRB	<= m_apb_pwstrb;
		M_APB_PPROT	<= m_apb_pprot;
	end
end

always @(posedge M_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		s_apb_prdata	<= {DW{1'b0}};
		s_apb_pslverr	<= 1'b0;
	end
	else if (M_APB_PREADY)
	begin
		s_apb_prdata	<= M_APB_PRDATA;
		s_apb_pslverr	<= M_APB_PSLVERR;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		S_APB_PRDATA	<= {DW{1'b0}};
		S_APB_PSLVERR	<= 1'b0;
	end
	else
	begin
		S_APB_PRDATA	<= s_apb_prdata;
		S_APB_PSLVERR	<= s_apb_pslverr;
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		S_APB_PREADY	<= 1'b0;
	end
	else if (m_apb_psel_reg && M_APB_PREADY)
	begin
		S_APB_PREADY	<= 1'b1;
		m_apb_psel_reg	<= 1'b0;
	end
	else
	begin
		S_APB_PREADY	<= 1'b0;
	end
end

endmodule
