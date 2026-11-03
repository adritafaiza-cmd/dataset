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
reg			m_error;
reg	[DW-1:0]	m_rdata;

reg			s_valid;
reg			s_ready;
reg			s_error;
reg	[DW-1:0]	s_rdata;

wire			s_req;
wire			m_req;
wire			s_ack;
wire			m_ack;

assign	s_req = S_APB_PSEL && S_APB_PENABLE;
assign	m_req = M_APB_PSEL && M_APB_PENABLE;
assign	s_ack = S_APB_PREADY;
assign	m_ack = M_APB_PREADY;

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		S_APB_PREADY <= 1'b0;
		s_valid <= 1'b0;
		s_ready <= 1'b0;
		s_error <= 1'b0;
		s_rdata <= {DW{1'b0}};
	end
	else
	begin
		if (s_req)
		begin
			s_valid <= 1'b1;
			s_ready <= 1'b0;
			s_error <= 1'b0;
			s_rdata <= {DW{1'b0}};
		end
		else if (s_ack)
		begin
			s_valid <= 1'b0;
			s_ready <= 1'b1;
			s_error <= M_APB_PSLVERR;
			s_rdata <= M_APB_PRDATA;
		end
		else
		begin
			s_valid <= s_valid;
			s_ready <= s_ready;
			s_error <= s_error;
			s_rdata <= s_rdata;
		end
		if (s_req)
		begin
			S_APB_PREADY <= 1'b1;
		end
		else
		begin
			S_APB_PREADY <= 1'b0;
		end
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn)
	begin
		M_PRESETn <= 1'b1;
		M_APB_PSEL <= 1'b0;
		M_APB_PENABLE <= 1'b0;
		m_valid <= 1'b0;
		m_ready <= 1'b0;
		m_error <= 1'b0;
		m_rdata <= {DW{1'b0}};
	end
	else
	begin
		if (m_req)
		begin
			m_valid <= 1'b1;
			m_ready <= 1'b0;
			m_error <= 1'b0;
			m_rdata <= {DW{1'b0}};
		end
		else if (m_ack)
		begin
			m_valid <= 1'b0;
			m_ready <= 1'b1;
			m_error <= M_APB_PSLVERR;
			m_rdata <= M_APB_PRDATA;
		end
		else
		begin
			m_valid <= m_valid;
			m_ready <= m_ready;
			m_error <= m_error;
			m_rdata <= m_rdata;
		end
		if (m_req)
		begin
			M_APB_PSEL <= 1'b1;
			M_APB_PENABLE <= 1'b1;
		end
		else
		begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end
	end
end

always @(posedge S_APB_PCLK or negedge S_PRESETn)
begin
	if (!S_PRESETn)
	begin
		M_APB_PADDR <= {AW{1'b0}};
		M_APB_PWRITE <= 1'b0;
		M_APB_PWDATA <= {DW{1'b0}};
		M_APB_PWSTRB <= {DW/8{1'b0}};
		M_APB_PPROT <= {3{1'b0}};
	end
	else
	begin
		if (s_req)
		begin
			M_APB_PADDR <= S_APB_PADDR;
			M_APB_PWRITE <= S_APB_PWRITE;
			M_APB_PWDATA <= S_APB_PWDATA;
			M_APB_PWSTRB <= S_APB_PWSTRB;
			M_APB_PPROT <= S_APB_PPROT;
		end
		else
		begin
			M_APB_PADDR <= M_APB_PADDR;
			M_APB_PWRITE <= M_APB_PWRITE;
			M_APB_PWDATA <= M_APB_PWDATA;
			M_APB_PWSTRB <= M_APB_PWSTRB;
			M_APB_PPROT <= M_APB_PPROT;
		end
	end
end

always @(posedge M_APB_PCLK or negedge M_PRESETn)
begin
	if (!M_PRESETn)
	begin
		S_APB_PRDATA <= {DW{1'b0}};
		S_APB_PSLVERR <= 1'b0;
	end
	else
	begin
		if (m_ack)
		begin
			S_APB_PRDATA <= M_APB_PRDATA;
			S_APB_PSLVERR <= M_APB_PSLVERR;
		end
		else
		begin
			S_APB_PRDATA <= S_APB_PRDATA;
			S_APB_PSLVERR <= S_APB_PSLVERR;
		end
	end
end

endmodule
