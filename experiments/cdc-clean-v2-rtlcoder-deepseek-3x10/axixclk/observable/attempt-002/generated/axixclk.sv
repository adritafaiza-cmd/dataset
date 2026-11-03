The Verilog-2001 code for the AXI4 clock-domain bridge is as follows:

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
	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID_int;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR_int;
	wire [7 : 0]			S_AXI_AWLEN_int;
	wire [2 : 0]			S_AXI_AWSIZE_int;
	wire [1 : 0]			S_AXI_AWBURST_int;
	wire				S_AXI_AWLOCK_int;
	wire [3 : 0]			S_AXI_AWCACHE_int;
	wire [2 : 0]			S_AXI_AWPROT_int;
	wire [3 : 0]			S_AXI_AWQOS_int;
	wire				S_AXI_AWVALID_int;
	wire				S_AXI_AWREADY_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA_int;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB_int;
	wire				S_AXI_WLAST_int;
	wire				S_AXI_WVALID_int;
	wire				S_AXI_WREADY_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID_int;
	wire [1 : 0]			S_AXI_BRESP_int;
	wire				S_AXI_BVALID_int;
	wire				S_AXI_BREADY_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID_int;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR_int;
	wire [7 : 0]			S_AXI_ARLEN_int;
	wire [2 : 0]			S_AXI_ARSIZE_int;
	wire [1 : 0]			S_AXI_ARBURST_int;
	wire				S_AXI_ARLOCK_int;
	wire [3 : 0]			S_AXI_ARCACHE_int;
	wire [2 : 0]			S_AXI_ARPROT_int;
	wire [3 : 0]			S_AXI_ARQOS_int;
	wire				S_AXI_ARVALID_int;
	wire				S_AXI_ARREADY_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA_int;
	wire [1 : 0]			S_AXI_RRESP_int;
	wire				S_AXI_RLAST_int;
	wire				S_AXI_RVALID_int;
	wire				S_AXI_RREADY_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID_int;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR_int;
	wire [7 : 0]			M_AXI_AWLEN_int;
	wire [2 : 0]			M_AXI_AWSIZE_int;
	wire [1 : 0]			M_AXI_AWBURST_int;
	wire				M_AXI_AWLOCK_int;
	wire [3 : 0]			M_AXI_AWCACHE_int;
	wire [2 : 0]			M_AXI_AWPROT_int;
	wire [3 : 0]			M_AXI_AWQOS_int;
	wire				M_AXI_AWVALID_int;
	wire				M_AXI_AWREADY_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA_int;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB_int;
	wire				M_AXI_WLAST_int;
	wire				M_AXI_WVALID_int;
	wire				M_AXI_WREADY_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID_int;
	wire [1 : 0]			M_AXI_BRESP_int;
	wire				M_AXI_BVALID_int;
	wire				M_AXI_BREADY_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID_int;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR_int;
	wire [7 : 0]			M_AXI_ARLEN_int;
	wire [2 : 0]			M_AXI_ARSIZE_int;
	wire [1 : 0]			M_AXI_ARBURST_int;
	wire				M_AXI_ARLOCK_int;
	wire [3 : 0]			M_AXI_ARCACHE_int;
	wire [2 : 0]			M_AXI_ARPROT_int;
	wire [3 : 0]			M_AXI_ARQOS_int;
	wire				M_AXI_ARVALID_int;
	wire				M_AXI_ARREADY_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA_int;
	wire [1 : 0]			M_AXI_RRESP_int;
	wire				M_AXI_RLAST_int;
	wire				M_AXI_RVALID_int;
	wire				M_AXI_RREADY_int;

	// Clock domain crossing FIFOs
	axi_cdc_fifo #(
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_XCLOCK_FFS(XCLOCK_FFS),
		.C_LGFIFO(LGFIFO)
	) axi_cdc_fifo_inst (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_AWID(S_AXI_AWID_int),
		.S_AXI_AWADDR(S_AXI_AWADDR_int),
		.S_AXI_AWLEN(S_AXI_AWLEN_int),
		.S_AXI_AWSIZE(S_AXI_AWSIZE_int),
		.S_AXI_AWBURST(S_AXI_AWBURST_int),
		.S_AXI_AWLOCK(S_AXI_AWLOCK_int),
		.S_AXI_AWCACHE(S_AXI_AWCACHE_int),
		.S_AXI_AWPROT(S_AXI_AWPROT_int),
		.S_AXI_AWQOS(S_AXI_AWQOS_int),
		.S_AXI_AWVALID(S_AXI_AWVALID_int),
		.S_AXI_AWREADY(S_AXI_AWREADY_int),
		.S_AXI_WDATA(S_AXI_WDATA_int),
		.S_AXI_WSTRB(S_AXI_WSTRB_int),
		.S_AXI_WLAST(S_AXI_WLAST_int),
		.S_AXI_WVALID(S_AXI_WVALID_int),
		.S_AXI_WREADY(S_AXI_WREADY_int),
		.S_AXI_BID(S_AXI_BID_int),
		.S_AXI_BRESP(S_AXI_BRESP_int),
		.S_AXI_BVALID(S_AXI_BVALID_int),
		.S_AXI_BREADY(S_AXI_BREADY_int),
		.S_AXI_ARID(S_AXI_ARID_int),
		.S_AXI_ARADDR(S_AXI_ARADDR_int),
		.S_AXI_ARLEN(S_AXI_ARLEN_int),
		.S_AXI_ARSIZE(S_AXI_ARSIZE_int),
		.S_AXI_ARBURST(S_AXI_ARBURST_int),
		.S_AXI_ARLOCK(S_AXI_ARLOCK_int),
		.S_AXI_ARCACHE(S_AXI_ARCACHE_int),
		.S_AXI_ARPROT(S_AXI_ARPROT_int),
		.S_AXI_ARQOS(S_AXI_ARQOS_int),
		.S_AXI_ARVALID(S_AXI_ARVALID_int),
		.S_AXI_ARREADY(S_AXI_ARREADY_int),
		.S_AXI_RID(S_AXI_RID_int),
		.S_AXI_RDATA(S_AXI_RDATA_int),
		.S_AXI_RRESP(S_AXI_RRESP_int),
		.S_AXI_RLAST(S_AXI_RLAST_int),
		.S_AXI_RVALID(S_AXI_RVALID_int),
		.S_AXI_RREADY(S_AXI_RREADY_int),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_AWID(M_AXI_AWID_int),
		.M_AXI_AWADDR(M_AXI_AWADDR_int),
		.M_AXI_AWLEN(M_AXI_AWLEN_int),
		.M_AXI_AWSIZE(M_AXI_AWSIZE_int),
		.M_AXI_AWBURST(M_AXI_AWBURST_int),
		.M_AXI_AWLOCK(M_AXI_AWLOCK_int),
		.M_AXI_AWCACHE(M_AXI_AWCACHE_int),
		.M_AXI_AWPROT(M_AXI_AWPROT_int),
		.M_AXI_AWQOS(M_AXI_AWQOS_int),
		.M_AXI_AWVALID(M_AXI_AWVALID_int),
		.M_AXI_AWREADY(M_AXI_AWREADY_int),
		.M_AXI_WDATA(M_AXI_WDATA_int),
		.M_AXI_WSTRB(M_AXI_WSTRB_int),
		.M_AXI_WLAST(M_AXI_WLAST_int),
		.M_AXI_WVALID(M_AXI_WVALID_int),
		.M_AXI_WREADY(M_AXI_WREADY_int),
		.M_AXI_BID(M_AXI_BID_int),
		.M_AXI_BRESP(M_AXI_BRESP_int),
		.M_AXI_BVALID(M_AXI_BVALID_int),
		.M_AXI_BREADY(M_AXI_BREADY_int),
		.M_AXI_ARID(M_AXI_ARID_int),
		.M_AXI_ARADDR(M_AXI_ARADDR_int),
		.M_AXI_ARLEN(M_AXI_ARLEN_int),
		.M_AXI_ARSIZE(M_AXI_ARSIZE_int),
		.M_AXI_ARBURST(M_AXI_ARBURST_int),
		.M_AXI_ARLOCK(M_AXI_ARLOCK_int),
		.M_AXI_ARCACHE(M_AXI_ARCACHE_int),
		.M_AXI_ARPROT(M_AXI_ARPROT_int),
		.M_AXI_ARQOS(M_AXI_ARQOS_int),
		.M_AXI_ARVALID(M_AXI_ARVALID_int),
		.M_AXI_ARREADY(M_AXI_ARREADY_int),
		.M_AXI_RID(M_AXI_RID_int),
		.M_AXI_RDATA(M_AXI_RDATA_int),
		.M_AXI_RRESP(M_AXI_RRESP_int),
		.M_AXI_RLAST(M_AXI_RLAST_int),
		.M_AXI_RVALID(M_AXI_RVALID_int),
		.M_AXI_RREADY(M_AXI_RREADY_int)
	);

	// Output assignments
	assign S_AXI_AWID = S_AXI_AWID_int;
	assign S_AXI_AWADDR = S_AXI_AWADDR_int;
	assign S_AXI_AWLEN = S_AXI_AWLEN_int;
	assign S_AXI_AWSIZE = S_AXI_AWSIZE_int;
	assign S_AXI_AWBURST = S_AXI_AWBURST_int;
	assign S_AXI_AWLOCK = S_AXI_AWLOCK_int;
	assign S_AXI_AWCACHE = S_AXI_AWCACHE_int;
	assign S_AXI_AWPROT = S_AXI_AWPROT_int;
	assign S_AXI_AWQOS = S_AXI_AWQOS_int;
	assign S_AXI_AWVALID = S_AXI_AWVALID_int;
	assign S_AXI_AWREADY = S_AXI_AWREADY_int;
	assign S_AXI_WDATA = S_AXI_WDATA_int;
	assign S_AXI_WSTRB = S_AXI_WSTRB_int;
	assign S_AXI_WLAST = S_AXI_WLAST_int;
	assign S_AXI_WVALID = S_AXI_WVALID_int;
	assign S_AXI_WREADY = S_AXI_WREADY_int;
	assign S_AXI_BID = S_AXI_BID_int;
	assign S_AXI_BRESP = S_AXI_BRESP_int;
	assign S_AXI_BVALID = S_AXI_BVALID_int;
	assign S_AXI_BREADY = S_AXI_BREADY_int;
	assign S_AXI_ARID = S_AXI_ARID_int;
	assign S_AXI_ARADDR = S_AXI_ARADDR_int;
	assign S_AXI_ARLEN = S_AXI_ARLEN_int;
	assign S_AXI_ARSIZE = S_AXI_ARSIZE_int;
	assign S_AXI_ARBURST = S_AXI_ARBURST_int;
	assign S_AXI_ARLOCK = S_AXI_ARLOCK_int;
	assign S_AXI_ARCACHE = S_AXI_ARCACHE_int;
	assign S_AXI_ARPROT = S_AXI_ARPROT_int;
	assign S_AXI_ARQOS = S_AXI_ARQOS_int;
	assign S_AXI_ARVALID = S_AXI_ARVALID_int;
	assign S_AXI_ARREADY = S_AXI_ARREADY_int;
	assign S_AXI_RID = S_AXI_RID_int;
	assign S_AXI_RDATA = S_AXI_RDATA_int;
	assign S_AXI_RRESP = S_AXI_RRESP_int;
	assign S_AXI_RLAST = S_AXI_RLAST_int;
	assign S_AXI_RVALID = S_AXI_RVALID_int;
	assign S_AXI_RREADY = S_AXI_RREADY_int;
	assign M_AXI_AWID = M_AXI_AWID_int;
	assign M_AXI_AWADDR = M_AXI_AWADDR_int;
	assign M_AXI_AWLEN = M_AXI_AWLEN_int;
	assign M_AXI_AWSIZE = M_AXI_AWSIZE_int;
	assign M_AXI_AWBURST = M_AXI_AWBURST_int;
	assign M_AXI_AWLOCK = M_AXI_AWLOCK_int;
	assign M_AXI_AWCACHE = M_AXI_AWCACHE_int;
	assign M_AXI_AWPROT = M_AXI_AWPROT_int;
	assign M_AXI_AWQOS = M_AXI_AWQOS_int;
	assign M_AXI_AWVALID = M_AXI_AWVALID_int;
	assign M_AXI_AWREADY = M_AXI_AWREADY_int;
	assign M_AXI_WDATA = M_AXI_WDATA_int;
	assign M_AXI_WSTRB = M_AXI_WSTRB_int;
	assign M_AXI_WLAST = M_AXI_WLAST_int;
	assign M_AXI_WVALID = M_AXI_WVALID_int;
	assign M_AXI_WREADY = M_AXI_WREADY_int;
	assign M_AXI_BID = M_AXI_BID_int;
	assign M_AXI_BRESP = M_AXI_BRESP_int;
	assign M_AXI_BVALID = M_AXI_BVALID_int;
	assign M_AXI_BREADY = M_AXI_BREADY_int;
	assign M_AXI_ARID = M_AXI_ARID_int;
	assign M_AXI_ARADDR = M_AXI_ARADDR_int;
	assign M_AXI_ARLEN = M_AXI_ARLEN_int;
	assign M_AXI_ARSIZE = M_AXI_ARSIZE_int;
	assign M_AXI_ARBURST = M_AXI_ARBURST_int;
	assign M_AXI_ARLOCK = M_AXI_ARLOCK_int;
	assign M_AXI_ARCACHE = M_AXI_ARCACHE_int;
	assign M_AXI_ARPROT = M_AXI_ARPROT_int;
	assign M_AXI_ARQOS = M_AXI_ARQOS_int;
	assign M_AXI_ARVALID = M_AXI_ARVALID_int;
	assign M_AXI_ARREADY = M_AXI_ARREADY_int;
	assign M_AXI_RID = M_AXI_RID_int;
	assign M_AXI_RDATA = M_AXI_RDATA_int;
	assign M_AXI_RRESP = M_AXI_RRESP_int;
	assign M_AXI_RLAST = M_AXI_RLAST_int;
	assign M_AXI_RVALID = M_AXI_RVALID_int;
	assign M_AXI_RREADY = M_AXI_RREADY_int;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);
