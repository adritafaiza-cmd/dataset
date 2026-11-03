module apbxclk #(
	parameter C_APB_ADDR_WIDTH = 12,
	parameter C_APB_DATA_WIDTH = 32,
	parameter [0:0] OPT_REGISTERED = 1'b0,
	localparam AW = C_APB_ADDR_WIDTH,
	localparam DW = C_APB_DATA_WIDTH
) (
	input wire S_APB_PCLK, S_PRESETn,
	input wire S_APB_PSEL,
	input wire S_APB_PENABLE,
	output reg S_APB_PREADY,
	input wire [AW-1:0] S_APB_PADDR,
	input wire S_APB_PWRITE,
	input wire [DW-1:0] S_APB_PWDATA,
	input wire [DW/8-1:0] S_APB_PWSTRB,
	input wire [2:0] S_APB_PPROT,
	output wire [DW-1:0] S_APB_PRDATA,
	output wire S_APB_PSLVERR,
	input wire M_APB_PCLK,
	output reg M_PRESETn,
	output reg M_APB_PSEL,
	output reg M_APB_PENABLE,
	input wire M_APB_PREADY,
	output wire [AW-1:0] M_APB_PADDR,
	output wire M_APB_PWRITE,
	output wire [DW-1:0] M_APB_PWDATA,
	output wire [DW/8-1:0] M_APB_PWSTRB,
	output wire [2:0] M_APB_PPROT,
	input wire [DW-1:0] M_APB_PRDATA,
	input wire M_APB_PSLVERR
);

reg [AW-1:0] apb_addr;
reg apb_write;
reg [DW-1:0] apb_wdata;
reg [DW/8-1:0] apb_wstrb;
reg [2:0] apb_prot;
wire [DW-1:0] apb_rdata;
wire apb_rvalid;
wire apb_rready;
wire apb_rslverr;

reg s_apb_pready;
reg s_apb_prdata;
reg s_apb_pslverr;

reg m_apb_psel;
reg m_apb_penable;
reg [AW-1:0] m_apb_paddr;
reg m_apb_pwrite;
reg [DW-1:0] m_apb_pwdata;
reg [DW/8-1:0] m_apb_pwstrb;
reg [2:0] m_apb_pprot;

always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		s_apb_pready <= 0;
		s_apb_prdata <= 0;
		s_apb_pslverr <= 0;
		end else begin
		s_apb_pready <= M_APB_PREADY;
		s_apb_prdata <= apb_rdata;
		s_apb_pslverr <= apb_rslverr;
		end
	end

always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
	if (!S_PRESETn) begin
		M_PRESETn <= 1;
		m_apb_psel <= 0;
		m_apb_penable <= 0;
		end else begin
		M_PRESETn <= 0;
		m_apb_psel <= S_APB_PSEL;
		m_apb_penable <= S_APB_PENABLE;
		m_apb_paddr <= S_APB_PADDR;
		m_apb_pwrite <= S_APB_PWRITE;
		m_apb_pwdata <= S_APB_PWDATA;
		m_apb_pwstrb <= S_APB_PWSTRB;
		m_apb_pprot <= S_APB_PPROT;
		end
	end

apb_crossing #(
	.C_APB_ADDR_WIDTH(AW),
	.C_APB_DATA_WIDTH(DW),
	.OPT_REGISTERED(OPT_REGISTERED)
) apb_crossing_inst (
	.S_APB_PCLK(S_APB_PCLK),
	.S_PRESETn(S_PRESETn),
	.S_APB_PSEL(S_APB_PSEL),
	.S_APB_PENABLE(S_APB_PENABLE),
	.S_APB_PREADY(s_apb_pready),
	.S_APB_PADDR(S_APB_PADDR),
	.S_APB_PWRITE(S_APB_PWRITE),
	.S_APB_PWDATA(S_APB_PWDATA),
	.S_APB_PWSTRB(S_APB_PWSTRB),
	.S_APB_PPROT(S_APB_PPROT),
	.S_APB_PRDATA(s_apb_prdata),
	.S_APB_PSLVERR(s_apb_pslverr),
	.M_APB_PCLK(M_APB_PCLK),
	.M_PRESETn(M_PRESETn),
	.M_APB_PSEL(m_apb_psel),
	.M_APB_PENABLE(m_apb_penable),
	.M_APB_PREADY(M_APB_PREADY),
	.M_APB_PADDR(m_apb_paddr),
	.M_APB_PWRITE(m_apb_pwrite),
	.M_APB_PWDATA(m_apb_pwdata),
	.M_APB_PWSTRB(m_apb_pwstrb),
	.M_APB_PPROT(m_apb_pprot),
	.M_APB_PRDATA(apb_rdata),
	.M_APB_PSLVERR(apb_rslverr)
);

endmodule
