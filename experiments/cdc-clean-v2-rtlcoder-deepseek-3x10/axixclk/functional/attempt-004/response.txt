Sure, here is the complete Verilog code for the AXI4 clock-domain bridge module:

```
module axixclk #(
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
		parameter [0:0]	OPT_READ_ONLY = 1'b0,
		parameter	XCLOCK_FFS = 2,
		parameter	LGFIFO = 5
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
		input	wire [7 : 0]			S_AXI_AWLEN,
		input	wire [2 : 0]			S_AXI_AWSIZE,
		input	wire [1 : 0]			S_AXI_AWBURST,
		input	wire				S_AXI_AWLOCK,
		input	wire [3 : 0]			S_AXI_AWCACHE,
		input	wire [2 : 0]			S_AXI_AWPROT,
		input	wire [3 : 0]			S_AXI_AWQOS,
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
		output	wire [1 : 0]			S_AXI_BRESP,
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
		input	wire [7 : 0]			S_AXI_ARLEN,
		input	wire [2 : 0]			S_AXI_ARSIZE,
		input	wire [1 : 0]			S_AXI_ARBURST,
		input	wire				S_AXI_ARLOCK,
		input	wire [3 : 0]			S_AXI_ARCACHE,
		input	wire [2 : 0]			S_AXI_ARPROT,
		input	wire [3 : 0]			S_AXI_ARQOS,
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
		output	wire [1 : 0]			S_AXI_RRESP,
		output	wire				S_AXI_RLAST,
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		input	wire				M_AXI_ACLK,
		output	wire				M_AXI_ARESETN,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
		output	wire [7 : 0]			M_AXI_AWLEN,
		output	wire [2 : 0]			M_AXI_AWSIZE,
		output	wire [1 : 0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire [3 : 0]			M_AXI_AWCACHE,
		output	wire [2 : 0]			M_AXI_AWPROT,
		output	wire [3 : 0]			M_AXI_AWQOS,
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
		input	wire [1 : 0]			M_AXI_BRESP,
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
		output	wire [7 : 0]			M_AXI_ARLEN,
		output	wire [2 : 0]			M_AXI_ARSIZE,
		output	wire [1 : 0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire [3 : 0]			M_AXI_ARCACHE,
		output	wire [2 : 0]			M_AXI_ARPROT,
		output	wire [3 : 0]			M_AXI_ARQOS,
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
		input	wire [1 : 0]			M_AXI_RRESP,
		input	wire				M_AXI_RLAST,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY
	);

	// Internal signals
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_awid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr_int;
	reg [7 : 0] s_axi_awlen_int;
	reg [2 : 0] s_axi_awsize_int;
	reg [1 : 0] s_axi_awburst_int;
	reg s_axi_awlock_int;
	reg [3 : 0] s_axi_awcache_int;
	reg [2 : 0] s_axi_awprot_int;
	reg [3 : 0] s_axi_awqos_int;
	reg s_axi_awvalid_int;
	wire s_axi_awready_int;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int;
	reg s_axi_wlast_int;
	reg s_axi_wvalid_int;
	wire s_axi_wready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_bid_int;
	wire [1 : 0] s_axi_bresp_int;
	wire s_axi_bvalid_int;
	reg s_axi_bready_int;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_arid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr_int;
	reg [7 : 0] s_axi_arlen_int;
	reg [2 : 0] s_axi_arsize_int;
	reg [1 : 0] s_axi_arburst_int;
	reg s_axi_arlock_int;
	reg [3 : 0] s_axi_arcache_int;
	reg [2 : 0] s_axi_arprot_int;
	reg [3 : 0] s_axi_arqos_int;
	reg s_axi_arvalid_int;
	wire s_axi_arready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_rid_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int;
	wire [1 : 0] s_axi_rresp_int;
	wire s_axi_rlast_int;
	wire s_axi_rvalid_int;
	reg s_axi_rready_int;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_awid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr_int;
	reg [7 : 0] m_axi_awlen_int;
	reg [2 : 0] m_axi_awsize_int;
	reg [1 : 0] m_axi_awburst_int;
	reg m_axi_awlock_int;
	reg [3 : 0] m_axi_awcache_int;
	reg [2 : 0] m_axi_awprot_int;
	reg [3 : 0] m_axi_awqos_int;
	reg m_axi_awvalid_int;
	wire m_axi_awready_int;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int;
	reg m_axi_wlast_int;
	reg m_axi_wvalid_int;
	wire m_axi_wready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_bid_int;
	wire [1 : 0] m_axi_bresp_int;
	wire m_axi_bvalid_int;
	reg m_axi_bready_int;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_arid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr_int;
	reg [7 : 0] m_axi_arlen_int;
	reg [2 : 0] m_axi_arsize_int;
	reg [1 : 0] m_axi_arburst_int;
	reg m_axi_arlock_int;
	reg [3 : 0] m_axi_arcache_int;
	reg [2 : 0] m_axi_arprot_int;
	reg [3 : 0] m_axi_arqos_int;
	reg m_axi_arvalid_int;
	wire m_axi_arready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_rid_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int;
	wire [1 : 0] m_axi_rresp_int;
	wire m_axi_rlast_int;
	wire m_axi_rvalid_int;
	reg m_axi_rready_int;

	// Assign internal signals to output ports
	assign S_AXI_AWID = s_axi_awid_int;
	assign S_AXI_AWADDR = s_axi_awaddr_int;
	assign S_AXI_AWLEN = s_axi_awlen_int;
	assign S_AXI_AWSIZE = s_axi_awsize_int;
	assign S_AXI_AWBURST = s_axi_awburst_int;
	assign S_AXI_AWLOCK = s_axi_awlock_int;
	assign S_AXI_AWCACHE = s_axi_awcache_int;
	assign S_AXI_AWPROT = s_axi_awprot_int;
	assign S_AXI_AWQOS = s_axi_awqos_int;
	assign S_AXI_AWVALID = s_axi_awvalid_int;
	assign S_AXI_AWREADY = s_axi_awready_int;
	assign S_AXI_WDATA = s_axi_wdata_int;
	assign S_AXI_WSTRB = s_axi_wstrb_int;
	assign S_AXI_WLAST = s_axi_wlast_int;
	assign S_AXI_WVALID = s_axi_wvalid_int;
	assign S_AXI_WREADY = s_axi_wready_int;
	assign S_AXI_BID = s_axi_bid_int;
	assign S_AXI_BRESP = s_axi_bresp_int;
	assign S_AXI_BVALID = s_axi_bvalid_int;
	assign S_AXI_BREADY = s_axi_bready_int;
	assign S_AXI_ARID = s_axi_arid_int;
	assign S_AXI_ARADDR = s_axi_araddr_int;
	assign S_AXI_ARLEN = s_axi_arlen_int;
	assign S_AXI_ARSIZE = s_axi_arsize_int;
	assign S_AXI_ARBURST = s_axi_arburst_int;
	assign S_AXI_ARLOCK = s_axi_arlock_int;
	assign S_AXI_ARCACHE = s_axi_arcache_int;
	assign S_AXI_ARPROT = s_axi_arprot_int;
	assign S_AXI_ARQOS = s_axi_arqos_int;
	assign S_AXI_ARVALID = s_axi_arvalid_int;
	assign S_AXI_ARREADY = s_axi_arready_int;
	assign S_AXI_RID = s_axi_rid_int;
	assign S_AXI_RDATA = s_axi_rdata_int;
	assign S_AXI_RRESP = s_axi_rresp_int;
	assign S_AXI_RLAST = s_axi_rlast_int;
	assign S_AXI_RVALID = s_axi_rvalid_int;
	assign S_AXI_RREADY = s_axi_rready_int;
	assign M_AXI_ARESETN = M_AXI_ARESETN;
	assign M_AXI_AWID = m_axi_awid_int;
	assign M_AXI_AWADDR = m_axi_awaddr_int;
	assign M_AXI_AWLEN = m_axi_awlen_int;
	assign M_AXI_AWSIZE = m_axi_awsize_int;
	assign M_AXI_AWBURST = m_axi_awburst_int;
	assign M_AXI_AWLOCK = m_axi_awlock_int;
	assign M_AXI_AWCACHE = m_axi_awcache_int;
	assign M_AXI_AWPROT = m_axi_awprot_int;
	assign M_AXI_AWQOS = m_axi_awqos_int;
	assign M_AXI_AWVALID = m_axi_awvalid_int;
	assign M_AXI_AWREADY = m_axi_awready_int;
	assign M_AXI_WDATA = m_axi_wdata_int;
	assign M_AXI_WSTRB = m_axi_wstrb_int;
	assign M_AXI_WLAST = m_axi_wlast_int;
	assign M_AXI_WVALID = m_axi_wvalid_int;
	assign M_AXI_WREADY = m_axi_wready_int;
	assign M_AXI_BID = m_axi_bid_int;
	assign M_AXI_BRESP = m_axi_bresp_int;
	assign M_AXI_BVALID = m_axi_bvalid_int;
	assign M_AXI_BREADY = m_axi_bready_int;
	assign M_AXI_ARID = m_axi_arid_int;
	assign M_AXI_ARADDR = m_axi_araddr_int;
	assign M_AXI_ARLEN = m_axi_arlen_int;
	assign M_AXI_ARSIZE = m_axi_arsize_int;
	assign M_AXI_ARBURST = m_axi_arburst_int;
	assign M_AXI_ARLOCK = m_axi_arlock_int;
	assign M_AXI_ARCACHE = m_axi_arcache_int;
	assign M_AXI_ARPROT = m_axi_arprot_int;
	assign M_AXI_ARQOS = m_axi_arqos_int;
	assign M_AXI_ARVALID = m_axi_arvalid_int;
	assign M_AXI_ARREADY = m_axi_arready_int;
	assign M_AXI_RID = m_axi_rid_int;
	assign M_AXI_RDATA = m_axi_rdata_int;
	assign M_AXI_RRESP = m_axi_rresp_int;
	assign M_AXI_RLAST = m_axi_rlast_int;
	assign M_AXI_RVALID = m_axi_rvalid_int;
	assign M_AXI_RREADY = m_axi_rready_int;

	// Internal logic
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			s_axi_awid_int <= 0;
			s_axi_awaddr_int <= 0;
			s_axi_awlen_int <= 0;
			s_axi_awsize_int <= 0;
			s_axi_awburst_int <= 0;
			s_axi_awlock_int <= 0;
			s_axi_awcache_int <= 0;
			s_axi_awprot_int <= 0;
			s_axi_awqos_int <= 0;
			s_axi_awvalid_int <= 0;
			s_axi_wdata_int <= 0;
			s_axi_wstrb_int <= 0;
			s_axi_wlast_int <= 0;
			s_axi_wvalid_int <= 0;
			s_axi_bready_int <= 0;
			s_axi_arid_int <= 0;
			s_axi_araddr_int <= 0;
			s_axi_arlen_int <= 0;
			s_axi_arsize_int <= 0;
			s_axi_arburst_int <= 0;
			s_axi_arlock_int <= 0;
			s_axi_arcache_int <= 0;
			s_axi_arprot_int <= 0;
			s_axi_arqos_int <= 0;
			s_axi_arvalid_int <= 0;
			s_axi_rready_int <= 0;
		end else begin
			if (S_AXI_AWVALID && s_axi_awready_int) begin
				s_axi_awid_int <= S_AXI_AWID;
				s_axi_awaddr_int <= S_AXI_AWADDR;
				s_axi_awlen_int <= S_AXI_AWLEN;
				s_axi_awsize_int <= S_AXI_AWSIZE;
				s_axi_awburst_int <= S_AXI_AWBURST;
				s_axi_awlock_int <= S_AXI_AWLOCK;
				s_axi_awcache_int <= S_AXI_AWCACHE;
				s_axi_awprot_int <= S_AXI_AWPROT;
				s_axi_awqos_int <= S_AXI_AWQOS;
				s_axi_awvalid_int <= 1;
			end else begin
				s_axi_awvalid_int <= 0;
			end
			if (S_AXI_WVALID && s_axi_wready_int) begin
				s_axi_wdata_int <= S_AXI_WDATA;
				s_axi_wstrb_int <= S_AXI_WSTRB;
				s_axi_wlast_int <= S_AXI_WLAST;
				s_axi_wvalid_int <= 1;
			end else begin
				s_axi_wvalid_int <= 0;
			end
			if (S_AXI_BREADY && s_axi_bvalid_int) begin
				s_axi_bready_int <= 1;
			end else begin
				s_axi_bready_int <= 0;
			end
			if (S_AXI_ARVALID && s_axi_arready_int) begin
				s_axi_arid_int <= S_AXI_ARID;
				s_axi_araddr_int <= S_AXI_ARADDR;
				s_axi_arlen_int <= S_AXI_ARLEN;
				s_axi_arsize_int <= S_AXI_ARSIZE;
				s_axi_arburst_int <= S_AXI_ARBURST;
				s_axi_arlock_int <= S_AXI_ARLOCK;
				s_axi_arcache_int <= S_AXI_ARCACHE;
				s_axi_arprot_int <= S_AXI_ARPROT;
				s_axi_arqos_int <= S_AXI_ARQOS;
				s_axi_arvalid_int <= 1;
			end else begin
				s_axi_arvalid_int <= 0;
			end
			if (S_AXI_RREADY && s_axi_rvalid_int) begin
				s_axi_rready_int <= 1;
			end else begin
				s_axi_rready_int <= 0;
			end
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			m_axi_awid_int <= 0;
			m_axi_awaddr_int <= 0;
			m_axi_awlen_int <= 0;
			m_axi_awsize_int <= 0;
			m_axi_awburst_int <= 0;
			m_axi_awlock_int <= 0;
			m_axi_awcache_int <= 0;
			m_axi_awprot_int <= 0;
			m_axi_awqos_int <= 0;
			m_axi_awvalid_int <= 0;
			m_axi_wdata_int <= 0;
			m_axi_wstrb_int <= 0;
			m_axi_wlast_int <= 0;
			m_axi_wvalid_int <= 0;
			m_axi_bready_int <= 0;
			m_axi_arid_int <= 0;
			m_axi_araddr_int <= 0;
			m_axi_arlen_int <= 0;
			m_axi_arsize_int <= 0;
			m_axi_arburst_int <= 0;
			m_axi_arlock_int <= 0;
			m_axi_arcache_int <= 0;
			m_axi_arprot_int <= 0;
			m_axi_arqos_int <= 0;
			m_axi_arvalid_int <= 0;
			m_axi_rready_int <= 0;
		end else begin
			if (M_AXI_AWVALID && m_axi_awready_int) begin
				m_axi_awid_int <= M_AXI_AWID;
				m_axi_awaddr_int <= M_AXI_AWADDR;
				m_axi_awlen_int <= M_AXI_AWLEN;
				m_axi_awsize_int <= M_AXI_AWSIZE;
				m_axi_awburst_int <= M_AXI_AWBURST;
				m_axi_awlock_int <= M_AXI_AWLOCK;
				m_axi_awcache_int <= M_AXI_AWCACHE;
				m_axi_awprot_int <= M_AXI_AWPROT;
				m_axi_awqos_int <= M_AXI_AWQOS;
				m_axi_awvalid_int <= 1;
			end else begin
				m_axi_awvalid_int <= 0;
			end
			if (M_AXI_WVALID && m_axi_wready_int) begin
				m_axi_wdata_int <= M_AXI_WDATA;
				m_axi_wstrb_int <= M_AXI_WSTRB;
				m_axi_wlast_int <= M_AXI_WLAST;
				m_axi_wvalid_int <= 1;
			end else begin
				m_axi_wvalid_int <= 0;
			end
			if (M_AXI_BREADY && m_axi_bvalid_int) begin
				m_axi_bready_int <= 1;
			end else begin
				m_axi_bready_int <= 0;
			end
			if (M_AXI_ARVALID && m_axi_arready_int) begin
				m_axi_arid_int <= M_AXI_ARID;
				m_axi_araddr_int <= M_AXI_ARADDR;
				m_axi_arlen_int <= M_AXI_ARLEN;
				m_axi_arsize_int <= M_AXI_ARSIZE;
				m_axi_arburst_int <= M_AXI_ARBURST;
				m_axi_arlock_int <= M_AXI_ARLOCK;
				m_axi_arcache_int <= M_AXI_ARCACHE;
				m_axi_arprot_int <= M_AXI_ARPROT;
				m_axi_arqos_int <= M_AXI_ARQOS;
				m_axi_arvalid_int <= 1;
			end else begin
				m_axi_arvalid_int <= 0;
			end
			if (M_AXI_RREADY && m_axi_rvalid_int) begin
				m_axi_rready_int <= 1;
			end else begin
				m_axi_rready_int <= 0;
			end
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the Unit Under Test (UUT)
    top_module uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        data_in = 8'h00;

        // Wait 100 ns for global reset to finish
        #100 reset = 0;

        // Add stimulus here
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 data_in = 8'h10;
        #10 data_in = 8'h11;
        #10 data_in = 8'h12;
        #10 data_in = 8'h13;
        #10 data_in = 8'h14;
        #10 data_in = 8'h15;
        #10 data_in = 8'h16;
        #10 data_in = 8'h17;
        #10 data_in = 8'h18;
        #10 data_in = 8'h19;
        #10 data_in = 8'h1a;
        #10 data_in = 8'h1b;
        #10 data_in = 8'h1c;
        #10 data_in = 8'h1d;
        #10 data_in = 8'h1e;
        #10 data_in = 8'h1f;
        #10 data_in = 8'h20;
        #10 data_in = 8'h21;
        #10 data_in = 8'h22;
        #10 data_in = 8'h23;
        #10 data_in = 8'h24;
        #10 data_in = 8'h25;
        #10 data_in = 8'h26;
        #10 data_in = 8'h27;
        #10 data_in = 8'h28;
        #10 data_in = 8'