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

	// Internal signals
	wire [AW-1:0] s_addr, m_addr;
	wire s_write, m_write;
	wire [DW-1:0] s_wdata, m_wdata;
	wire [DW/8-1:0] s_wstrb, m_wstrb;
	wire [2:0] s_prot, m_prot;
	wire [DW-1:0] s_rdata, m_rdata;
	wire s_rvalid, m_rvalid;
	wire s_rready, m_rready;
	wire s_slverr, m_slverr;

	// APB slave bridge
	apb_slave_bridge #(
		.C_APB_ADDR_WIDTH(AW),
		.C_APB_DATA_WIDTH(DW),
		.OPT_REGISTERED(OPT_REGISTERED)
	) slave_bridge (
		.S_APB_PCLK(S_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.S_APB_PSEL(S_APB_PSEL),
		.S_APB_PENABLE(S_APB_PENABLE),
		.S_APB_PREADY(S_APB_PREADY),
		.S_APB_PADDR(s_addr),
		.S_APB_PWRITE(s_write),
		.S_APB_PWDATA(s_wdata),
		.S_APB_PWSTRB(s_wstrb),
		.S_APB_PPROT(s_prot),
		.S_APB_PRDATA(s_rdata),
		.S_APB_PSLVERR(s_slverr)
	);

	// APB master bridge
	apb_master_bridge #(
		.C_APB_ADDR_WIDTH(AW),
		.C_APB_DATA_WIDTH(DW),
		.OPT_REGISTERED(OPT_REGISTERED)
	) master_bridge (
		.M_APB_PCLK(M_APB_PCLK),
		.M_PRESETn(M_PRESETn),
		.M_APB_PSEL(m_sel),
		.M_APB_PENABLE(m_enable),
		.M_APB_PREADY(m_ready),
		.M_APB_PADDR(m_addr),
		.M_APB_PWRITE(m_write),
		.M_APB_PWDATA(m_wdata),
		.M_APB_PWSTRB(m_wstrb),
		.M_APB_PPROT(m_prot),
		.M_APB_PRDATA(m_rdata),
		.M_APB_PSLVERR(m_slverr)
	);

	// Clock-domain crossing for master signals
	wire m_sel;
	wire m_enable;
	wire m_ready;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_sel <= 0;
			m_enable <= 0;
			m_ready <= 0;
		end else begin
			m_sel <= M_APB_PSEL;
			m_enable <= M_APB_PENABLE;
			m_ready <= M_APB_PREADY;
		end
	end

	// Clock-domain crossing for slave signals
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			S_APB_PSEL <= 0;
			S_APB_PENABLE <= 0;
			S_APB_PREADY <= 0;
		end else begin
			S_APB_PSEL <= s_sel;
			S_APB_PENABLE <= s_enable;
			S_APB_PREADY <= s_ready;
		end
	end

	// Connect internal signals
	assign s_addr = M_APB_PADDR;
	assign s_write = M_APB_PWRITE;
	assign s_wdata = M_APB_PWDATA;
	assign s_wstrb = M_APB_PWSTRB;
	assign s_prot = M_APB_PPROT;
	assign s_rready = S_APB_PREADY;
	assign m_addr = s_addr;
	assign m_write = s_write;
	assign m_wdata = s_wdata;
	assign m_wstrb = s_wstrb;
	assign m_prot = s_prot;
	assign m_rready = s_ready;
	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_slverr;

endmodule
