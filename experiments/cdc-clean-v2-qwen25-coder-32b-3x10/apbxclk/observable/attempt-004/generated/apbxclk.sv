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

reg [AW-1:0] s_addr_sync;
reg s_write_sync;
reg [DW-1:0] s_wdata_sync;
reg [DW/8-1:0] s_wstrb_sync;
reg [2:0] s_prot_sync;
reg s_req_sync;
reg s_req_sync2;

reg [AW-1:0] m_addr_reg;
reg m_write_reg;
reg [DW-1:0] m_wdata_reg;
reg [DW/8-1:0] m_wstrb_reg;
reg [2:0] m_prot_reg;
reg m_req_reg;

reg [DW-1:0] s_rdata_reg;
reg s_slverr_reg;
reg s_rvalid_reg;

// Synchronizer for slave to master
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		s_addr_sync <= 0;
		s_write_sync <= 0;
		s_wdata_sync <= 0;
		s_wstrb_sync <= 0;
		s_prot_sync <= 0;
		s_req_sync <= 0;
		s_req_sync2 <= 0;
	end else begin
		s_addr_sync <= S_APB_PADDR;
		s_write_sync <= S_APB_PWRITE;
		s_wdata_sync <= S_APB_PWDATA;
		s_wstrb_sync <= S_APB_PWSTRB;
		s_prot_sync <= S_APB_PPROT;
		s_req_sync <= S_APB_PSEL & S_APB_PENABLE;
		s_req_sync2 <= s_req_sync;
	end
end

// Master side logic
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		M_PRESETn <= 0;
		M_APB_PSEL <= 0;
		M_APB_PENABLE <= 0;
		m_addr_reg <= 0;
		m_write_reg <= 0;
		m_wdata_reg <= 0;
		m_wstrb_reg <= 0;
		m_prot_reg <= 0;
		m_req_reg <= 0;
		s_rdata_reg <= 0;
		s_slverr_reg <= 0;
		s_rvalid_reg <= 0;
	end else begin
		M_PRESETn <= S_PRESETn;
		if (s_req_sync2 && !m_req_reg) begin
			m_addr_reg <= s_addr_sync;
			m_write_reg <= s_write_sync;
			m_wdata_reg <= s_wdata_sync;
			m_wstrb_reg <= s_wstrb_sync;
			m_prot_reg <= s_prot_sync;
			m_req_reg <= 1;
		end else if (M_APB_PREADY) begin
			m_req_reg <= 0;
			s_rdata_reg <= M_APB_PRDATA;
			s_slverr_reg <= M_APB_PSLVERR;
			s_rvalid_reg <= 1;
		end
	end
end

// Slave side logic
always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		S_APB_PREADY <= 0;
	end else begin
		if (s_req_sync2 && !m_req_reg) begin
			S_APB_PREADY <= 0;
		end else if (s_rvalid_reg) begin
			S_APB_PREADY <= 1;
			s_rvalid_reg <= 0;
		end else begin
			S_APB_PREADY <= 1;
		end
	end
end

assign S_APB_PRDATA = s_rdata_reg;
assign S_APB_PSLVERR = s_slverr_reg;

assign M_APB_PADDR = m_addr_reg;
assign M_APB_PWRITE = m_write_reg;
assign M_APB_PWDATA = m_wdata_reg;
assign M_APB_PWSTRB = m_wstrb_reg;
assign M_APB_PPROT = m_prot_reg;

endmodule
