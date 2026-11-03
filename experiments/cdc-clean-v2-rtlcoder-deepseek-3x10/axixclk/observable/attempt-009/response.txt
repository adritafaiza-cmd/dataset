The AXI4 clock-domain bridge is a complex design that involves synchronization between two clock domains. It also requires careful handling of data and control signals. Here is a simplified implementation of the AXI4 clock-domain bridge in Verilog-2001:

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

	// Synchronization FIFOs
	reg [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID_sync;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR_sync;
	reg [7 : 0]			S_AXI_AWLEN_sync;
	reg [2 : 0]			S_AXI_AWSIZE_sync;
	reg [1 : 0]			S_AXI_AWBURST_sync;
	reg				S_AXI_AWLOCK_sync;
	reg [3 : 0]			S_AXI_AWCACHE_sync;
	reg [2 : 0]			S_AXI_AWPROT_sync;
	reg [3 : 0]			S_AXI_AWQOS_sync;
	reg				S_AXI_AWVALID_sync;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA_sync;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB_sync;
	reg				S_AXI_WLAST_sync;
	reg				S_AXI_WVALID_sync;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID_sync;
	reg [1 : 0]			S_AXI_BRESP_sync;
	reg				S_AXI_BVALID_sync;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID_sync;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR_sync;
	reg [7 : 0]			S_AXI_ARLEN_sync;
	reg [2 : 0]			S_AXI_ARSIZE_sync;
	reg [1 : 0]			S_AXI_ARBURST_sync;
	reg				S_AXI_ARLOCK_sync;
	reg [3 : 0]			S_AXI_ARCACHE_sync;
	reg [2 : 0]			S_AXI_ARPROT_sync;
	reg [3 : 0]			S_AXI_ARQOS_sync;
	reg				S_AXI_ARVALID_sync;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID_sync;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA_sync;
	reg [1 : 0]			S_AXI_RRESP_sync;
	reg				S_AXI_RLAST_sync;
	reg				S_AXI_RVALID_sync;

	// Master FIFOs
	reg [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID_sync;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR_sync;
	reg [7 : 0]			M_AXI_AWLEN_sync;
	reg [2 : 0]			M_AXI_AWSIZE_sync;
	reg [1 : 0]			M_AXI_AWBURST_sync;
	reg				M_AXI_AWLOCK_sync;
	reg [3 : 0]			M_AXI_AWCACHE_sync;
	reg [2 : 0]			M_AXI_AWPROT_sync;
	reg [3 : 0]			M_AXI_AWQOS_sync;
	reg				M_AXI_AWVALID_sync;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA_sync;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB_sync;
	reg				M_AXI_WLAST_sync;
	reg				M_AXI_WVALID_sync;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID_sync;
	reg [1 : 0]			M_AXI_BRESP_sync;
	reg				M_AXI_BVALID_sync;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID_sync;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR_sync;
	reg [7 : 0]			M_AXI_ARLEN_sync;
	reg [2 : 0]			M_AXI_ARSIZE_sync;
	reg [1 : 0]			M_AXI_ARBURST_sync;
	reg				M_AXI_ARLOCK_sync;
	reg [3 : 0]			M_AXI_ARCACHE_sync;
	reg [2 : 0]			M_AXI_ARPROT_sync;
	reg [3 : 0]			M_AXI_ARQOS_sync;
	reg				M_AXI_ARVALID_sync;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID_sync;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA_sync;
	reg [1 : 0]			M_AXI_RRESP_sync;
	reg				M_AXI_RLAST_sync;
	reg				M_AXI_RVALID_sync;

	// Synchronization FIFOs
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_AWID_sync <= 0;
			S_AXI_AWADDR_sync <= 0;
			S_AXI_AWLEN_sync <= 0;
			S_AXI_AWSIZE_sync <= 0;
			S_AXI_AWBURST_sync <= 0;
			S_AXI_AWLOCK_sync <= 0;
			S_AXI_AWCACHE_sync <= 0;
			S_AXI_AWPROT_sync <= 0;
			S_AXI_AWQOS_sync <= 0;
			S_AXI_AWVALID_sync <= 0;
			S_AXI_WDATA_sync <= 0;
			S_AXI_WSTRB_sync <= 0;
			S_AXI_WLAST_sync <= 0;
			S_AXI_WVALID_sync <= 0;
			S_AXI_BID_sync <= 0;
			S_AXI_BRESP_sync <= 0;
			S_AXI_BVALID_sync <= 0;
			S_AXI_ARID_sync <= 0;
			S_AXI_ARADDR_sync <= 0;
			S_AXI_ARLEN_sync <= 0;
			S_AXI_ARSIZE_sync <= 0;
			S_AXI_ARBURST_sync <= 0;
			S_AXI_ARLOCK_sync <= 0;
			S_AXI_ARCACHE_sync <= 0;
			S_AXI_ARPROT_sync <= 0;
			S_AXI_ARQOS_sync <= 0;
			S_AXI_ARVALID_sync <= 0;
			S_AXI_RID_sync <= 0;
			S_AXI_RDATA_sync <= 0;
			S_AXI_RRESP_sync <= 0;
			S_AXI_RLAST_sync <= 0;
			S_AXI_RVALID_sync <= 0;
		end else begin
			S_AXI_AWID_sync <= S_AXI_AWID;
			S_AXI_AWADDR_sync <= S_AXI_AWADDR;
			S_AXI_AWLEN_sync <= S_AXI_AWLEN;
			S_AXI_AWSIZE_sync <= S_AXI_AWSIZE;
			S_AXI_AWBURST_sync <= S_AXI_AWBURST;
			S_AXI_AWLOCK_sync <= S_AXI_AWLOCK;
			S_AXI_AWCACHE_sync <= S_AXI_AWCACHE;
			S_AXI_AWPROT_sync <= S_AXI_AWPROT;
			S_AXI_AWQOS_sync <= S_AXI_AWQOS;
			S_AXI_AWVALID_sync <= S_AXI_AWVALID;
			S_AXI_WDATA_sync <= S_AXI_WDATA;
			S_AXI_WSTRB_sync <= S_AXI_WSTRB;
			S_AXI_WLAST_sync <= S_AXI_WLAST;
			S_AXI_WVALID_sync <= S_AXI_WVALID;
			S_AXI_BID_sync <= S_AXI_BID;
			S_AXI_BRESP_sync <= S_AXI_BRESP;
			S_AXI_BVALID_sync <= S_AXI_BVALID;
			S_AXI_ARID_sync <= S_AXI_ARID;
			S_AXI_ARADDR_sync <= S_AXI_ARADDR;
			S_AXI_ARLEN_sync <= S_AXI_ARLEN;
			S_AXI_ARSIZE_sync <= S_AXI_ARSIZE;
			S_AXI_ARBURST_sync <= S_AXI_ARBURST;
			S_AXI_ARLOCK_sync <= S_AXI_ARLOCK;
			S_AXI_ARCACHE_sync <= S_AXI_ARCACHE;
			S_AXI_ARPROT_sync <= S_AXI_ARPROT;
			S_AXI_ARQOS_sync <= S_AXI_ARQOS;
			S_AXI_ARVALID_sync <= S_AXI_ARVALID;
			S_AXI_RID_sync <= S_AXI_RID;
			S_AXI_RDATA_sync <= S_AXI_RDATA;
			S_AXI_RRESP_sync <= S_AXI_RRESP;
			S_AXI_RLAST_sync <= S_AXI_RLAST;
			S_AXI_RVALID_sync <= S_AXI_RVALID;
		end
	end

	// Master FIFOs
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_AWID_sync <= 0;
			M_AXI_AWADDR_sync <= 0;
			M_AXI_AWLEN_sync <= 0;
			M_AXI_AWSIZE_sync <= 0;
			M_AXI_AWBURST_sync <= 0;
			M_AXI_AWLOCK_sync <= 0;
			M_AXI_AWCACHE_sync <= 0;
			M_AXI_AWPROT_sync <= 0;
			M_AXI_AWQOS_sync <= 0;
			M_AXI_AWVALID_sync <= 0;
			M_AXI_WDATA_sync <= 0;
			M_AXI_WSTRB_sync <= 0;
			M_AXI_WLAST_sync <= 0;
			M_AXI_WVALID_sync <= 0;
			M_AXI_BID_sync <= 0;
			M_AXI_BRESP_sync <= 0;
			M_AXI_BVALID_sync <= 0;
			M_AXI_ARID_sync <= 0;
			M_AXI_ARADDR_sync <= 0;
			M_AXI_ARLEN_sync <= 0;
			M_AXI_ARSIZE_sync <= 0;
			M_AXI_ARBURST_sync <= 0;
			M_AXI_ARLOCK_sync <= 0;
			M_AXI_ARCACHE_sync <= 0;
			M_AXI_ARPROT_sync <= 0;
			M_AXI_ARQOS_sync <= 0;
			M_AXI_ARVALID_sync <= 0;
			M_AXI_RID_sync <= 0;
			M_AXI_RDATA_sync <= 0;
			M_AXI_RRESP_sync <= 0;
			M_AXI_RLAST_sync <= 0;
			M_AXI_RVALID_sync <= 0;
		end else begin
			M_AXI_AWID_sync <= M_AXI_AWID;
			M_AXI_AWADDR_sync <= M_AXI_AWADDR;
			M_AXI_AWLEN_sync <= M_AXI_AWLEN;
			M_AXI_AWSIZE_sync <= M_AXI_AWSIZE;
			M_AXI_AWBURST_sync <= M_AXI_AWBURST;
			M_AXI_AWLOCK_sync <= M_AXI_AWLOCK;
			M_AXI_AWCACHE_sync <= M_AXI_AWCACHE;
			M_AXI_AWPROT_sync <= M_AXI_AWPROT;
			M_AXI_AWQOS_sync <= M_AXI_AWQOS;
			M_AXI_AWVALID_sync <= M_AXI_AWVALID;
			M_AXI_WDATA_sync <= M_AXI_WDATA;
			M_AXI_WSTRB_sync <= M_AXI_WSTRB;
			M_AXI_WLAST_sync <= M_AXI_WLAST;
			M_AXI_WVALID_sync <= M_AXI_WVALID;
			M_AXI_BID_sync <= M_AXI_BID;
			M_AXI_BRESP_sync <= M_AXI_BRESP;
			M_AXI_BVALID_sync <= M_AXI_BVALID;
			M_AXI_ARID_sync <= M_AXI_ARID;
			M_AXI_ARADDR_sync <= M_AXI_ARADDR;
			M_AXI_ARLEN_sync <= M_AXI_ARLEN;
			M_AXI_ARSIZE_sync <= M_AXI_ARSIZE;
			M_AXI_ARBURST_sync <= M_AXI_ARBURST;
			M_AXI_ARLOCK_sync <= M_AXI_ARLOCK;
			M_AXI_ARCACHE_sync <= M_AXI_ARCACHE;
			M_AXI_ARPROT_sync <= M_AXI_ARPROT;
			M_AXI_ARQOS_sync <= M_AXI_ARQOS;
			M_AXI_ARVALID_sync <= M_AXI_ARVALID;
			M_AXI_RID_sync <= M_AXI_RID;
			M_AXI_RDATA_sync <= M_AXI_RDATA;
			M_AXI_RRESP_sync <= M_AXI_RRESP;
			M_AXI_RLAST_sync <= M_AXI_RLAST;
			M_AXI_RVALID_sync <= M_AXI_RVALID;
		end
	end

	// Output assignments
	assign S_AXI_AWREADY = M_AXI_AWREADY;
	assign S_AXI_WREADY = M_AXI_WREADY;
	assign S_AXI_BID = M_AXI_BID_sync;
	assign S_AXI_BRESP = M_AXI_BRESP_sync;
	assign S_AXI_BVALID = M_AXI_BVALID_sync;
	assign S_AXI_ARID = M_AXI_ARID_sync;
	assign S_AXI_ARADDR = M_AXI_ARADDR_sync;
	assign S_AXI_ARLEN = M_AXI_ARLEN_sync;
	assign S_AXI_ARSIZE = M_AXI_ARSIZE_sync;
	assign S_AXI_ARBURST = M_AXI_ARBURST_sync;
	assign S_AXI_ARLOCK = M_AXI_ARLOCK_sync;
	assign S_AXI_ARCACHE = M_AXI_ARCACHE_sync;
	assign S_AXI_ARPROT = M_AXI_ARPROT_sync;
	assign S_AXI_ARQOS = M_AXI_ARQOS_sync;
	assign S_AXI_ARVALID = M_AXI_ARVALID_sync;
	assign S_AXI_RID = M_AXI_RID_sync;
	assign S_AXI_RDATA = M_AXI_RDATA_sync;
	assign S_AXI_RRESP = M_AXI_RRESP_sync;
	assign S_AXI_RLAST = M_AXI_RLAST_sync;
	assign S_AXI_RVALID = M_AXI_RVALID_sync;

	// Master FIFOs
	assign M_AXI_AWID = M_AXI_AWID_sync;
	assign M_AXI_AWADDR = M_AXI_AWADDR_sync;
	assign M_AXI_AWLEN = M_AXI_AWLEN_sync;
	assign M_AXI_AWSIZE = M_AXI_AWSIZE_sync;
	assign M_AXI_AWBURST = M_AXI_AWBURST_sync;
	assign M_AXI_AWLOCK = M_AXI_AWLOCK_sync;
	assign M_AXI_AWCACHE = M_AXI_AWCACHE_sync;
	assign M_AXI_AWPROT = M_AXI_AWPROT_sync;
	assign M_AXI_AWQOS = M_AXI_AWQOS_sync;
	assign M_AXI_AWVALID = M_AXI_AWVALID_sync;
	assign M_AXI_WDATA = M_AXI_WDATA_sync;
	assign M_AXI_WSTRB = M_AXI_WSTRB_sync;
	assign M_AXI_WLAST = M_AXI_WLAST_sync;
	assign M_AXI_WVALID = M_AXI_WVALID_sync;
	assign M_AXI_BID = S_AXI_BID_sync;
	assign M_AXI_BRESP = S_AXI_BRESP_sync;
	assign M_AXI_BVALID = S_AXI_BVALID_sync;
	assign M_AXI_ARID = M_AXI_ARID_sync;
	assign M_AXI_ARADDR = M_AXI_ARADDR_sync;
	assign M_AXI_ARLEN = M_AXI_ARLEN_sync;
	assign M_AXI_ARSIZE = M_AXI_ARSIZE_sync;
	assign M_AXI_ARBURST = M_AXI_ARBURST_sync;
	assign M_AXI_ARLOCK = M_AXI_ARLOCK_sync;
	assign M_AXI_ARCACHE = M_AXI_ARCACHE_sync;
	assign M_AXI_ARPROT = M_AXI_ARPROT_sync;
	assign M_AXI_ARQOS = M_AXI_ARQOS_sync;
	assign M_AXI_ARVALID = M_AXI_ARVALID_sync;
	assign M_AXI_RID = S_AXI_RID_sync;
	assign M_AXI_RDATA = S_AXI_RDATA_sync;
	assign M_AXI_RRESP = S_AXI_RRESP_sync;
	assign M_AXI_RLAST = S_AXI_RLAST_sync;
	assign M_AXI_RVALID = S_AXI_RVALID_sync;

	// Reset assignments
	assign M_AXI_ARESETN = S_AXI_ARESETN;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in