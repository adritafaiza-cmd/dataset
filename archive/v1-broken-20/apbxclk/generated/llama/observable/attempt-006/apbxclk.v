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
reg	[DW-1:0]	m_pwd;
reg	[DW/8-1:0]	m_pstrb;
reg	[2:0]		m_pprot;
reg			m_psel;
reg			m_penable;
reg			m_pready;
reg			m_pslverr;
reg	[DW-1:0]	m_prdata;

reg			s_psel_sync;
reg			s_penable_sync;
reg	[AW-1:0]	s_paddr_sync;
reg			s_pwrite_sync;
reg	[DW-1:0]	s_pwd_sync;
reg	[DW/8-1:0]	s_pstrb_sync;
reg	[2:0]		s_pprot_sync;

reg			m_req;
reg			m_busy;
reg			m_done;

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn) begin
		m_paddr	<= {AW{1'b0}};
		m_pwrite	<= 1'b0;
		m_pwd	<= {DW{1'b0}};
		m_pstrb	<= {DW/8{1'b0}};
		m_pprot	<= {3{1'b0}};
		m_psel	<= 1'b0;
		m_penable	<= 1'b0;
		m_pready	<= 1'b0;
		m_pslverr	<= 1'b0;
		m_prdata	<= {DW{1'b0}};
		m_req		<= 1'b0;
		m_busy	<= 1'b0;
		m_done	<= 1'b0;
	end else begin
		if (m_req && M_APB_PREADY) begin
			m_penable	<= 1'b0;
			m_req		<= 1'b0;
			m_done	<= 1'b1;
		end else if (s_psel_sync && s_penable_sync) begin
			m_paddr	<= s_paddr_sync;
			m_pwrite	<= s_pwrite_sync;
			m_pwd	<= s_pwd_sync;
			m_pstrb	<= s_pstrb_sync;
			m_pprot	<= s_pprot_sync;
			m_psel	<= 1'b1;
			m_penable	<= 1'b1;
			m_req		<= 1'b1;
			m_busy	<= 1'b1;
			m_done	<= 1'b0;
		end else if (m_done) begin
			m_psel	<= 1'b0;
			m_penable	<= 1'b0;
			m_busy	<= 1'b0;
			m_done	<= 1'b0;
		end
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn) begin
		s_psel_sync	<= 1'b0;
		s_penable_sync	<= 1'b0;
		s_paddr_sync	<= {AW{1'b0}};
		s_pwrite_sync	<= 1'b0;
		s_pwd_sync	<= {DW{1'b0}};
		s_pstrb_sync	<= {DW/8{1'b0}};
		s_pprot_sync	<= {3{1'b0}};
		S_APB_PREADY	<= 1'b0;
		S_APB_PRDATA	<= {DW{1'b0}};
		S_APB_PSLVERR	<= 1'b0;
	end else begin
		s_psel_sync	<= S_APB_PSEL;
		s_penable_sync	<= S_APB_PENABLE;
		if (S_APB_PSEL && S_APB_PENABLE) begin
			s_paddr_sync	<= S_APB_PADDR;
			s_pwrite_sync	<= S_APB_PWRITE;
			s_pwd_sync	<= S_APB_PWDATA;
			s_pstrb_sync	<= S_APB_PWSTRB;
			s_pprot_sync	<= S_APB_PPROT;
		end
		if (m_done) begin
			S_APB_PREADY	<= 1'b1;
			S_APB_PRDATA	<= m_prdata;
			S_APB_PSLVERR	<= m_pslverr;
		end else begin
			S_APB_PREADY	<= 1'b0;
			S_APB_PRDATA	<= {DW{1'b0}};
			S_APB_PSLVERR	<= 1'b0;
		end
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn) begin
		m_prdata	<= {DW{1'b0}};
		m_pslverr	<= 1'b0;
	end else begin
		if (M_APB_PREADY) begin
			m_prdata	<= M_APB_PRDATA;
			m_pslverr	<= M_APB_PSLVERR;
		end
	end
end

assign M_PRESETn	= S_PRESETn;
assign M_APB_PADDR	= m_paddr;
assign M_APB_PWRITE	= m_pwrite;
assign M_APB_PWDATA	= m_pwd;
assign M_APB_PWSTRB	= m_pstrb;
assign M_APB_PPROT	= m_pprot;
assign M_APB_PSEL	= m_psel;
assign M_APB_PENABLE	= m_penable;

endmodule
