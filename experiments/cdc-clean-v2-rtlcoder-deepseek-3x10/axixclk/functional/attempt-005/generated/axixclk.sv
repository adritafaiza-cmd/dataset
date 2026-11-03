The complete Verilog code for the AXI4 clock-domain bridge is as follows:

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

	reg [C_S_AXI_ID_WIDTH-1:0] awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_reg;
	reg [7:0] awlen_reg;
	reg [2:0] awsize_reg;
	reg [1:0] awburst_reg;
	reg awlock_reg;
	reg [3:0] awcache_reg;
	reg [2:0] awprot_reg;
	reg [3:0] awqos_reg;
	reg awvalid_reg;
	reg wlast_reg;
	reg wvalid_reg;
	reg bready_reg;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_reg;
	reg [7:0] arlen_reg;
	reg [2:0] arsize_reg;
	reg [1:0] arburst_reg;
	reg arlock_reg;
	reg [3:0] arcache_reg;
	reg [2:0] arprot_reg;
	reg [3:0] arqos_reg;
	reg arvalid_reg;
	reg rready_reg;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_reg;
	reg [1:0] bresp_reg;
	reg bvalid_reg;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_reg;
	reg [1:0] rresp_reg;
	reg rlast_reg;
	reg rvalid_reg;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_reg;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next;
	reg [7:0] awlen_next;
	reg [2:0] awsize_next;
	reg [1:0] awburst_next;
	reg awlock_next;
	reg [3:0] awcache_next;
	reg [2:0] awprot_next;
	reg [3:0] awqos_next;
	reg awvalid_next;
	reg wlast_next;
	reg wvalid_next;
	reg bready_next;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_next;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next;
	reg [7:0] arlen_next;
	reg [2:0] arsize_next;
	reg [1:0] arburst_next;
	reg arlock_next;
	reg [3:0] arcache_next;
	reg [2:0] arprot_next;
	reg [3:0] arqos_next;
	reg arvalid_next;
	reg rready_next;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_next;
	reg [1:0] bresp_next;
	reg bvalid_next;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_next;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_next;
	reg [1:0] rresp_next;
	reg rlast_next;
	reg rvalid_next;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_next;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_next;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_ff;
	reg [7:0] awlen_ff;
	reg [2:0] awsize_ff;
	reg [1:0] awburst_ff;
	reg awlock_ff;
	reg [3:0] awcache_ff;
	reg [2:0] awprot_ff;
	reg [3:0] awqos_ff;
	reg awvalid_ff;
	reg wlast_ff;
	reg wvalid_ff;
	reg bready_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_ff;
	reg [7:0] arlen_ff;
	reg [2:0] arsize_ff;
	reg [1:0] arburst_ff;
	reg arlock_ff;
	reg [3:0] arcache_ff;
	reg [2:0] arprot_ff;
	reg [3:0] arqos_ff;
	reg arvalid_ff;
	reg rready_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_ff;
	reg [1:0] bresp_ff;
	reg bvalid_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_ff;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_ff;
	reg [1:0] rresp_ff;
	reg rlast_ff;
	reg rvalid_ff;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next_ff;
	reg [7:0] awlen_next_ff;
	reg [2:0] awsize_next_ff;
	reg [1:0] awburst_next_ff;
	reg awlock_next_ff;
	reg [3:0] awcache_next_ff;
	reg [2:0] awprot_next_ff;
	reg [3:0] awqos_next_ff;
	reg awvalid_next_ff;
	reg wlast_next_ff;
	reg wvalid_next_ff;
	reg bready_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next_ff;
	reg [7:0] arlen_next_ff;
	reg [2:0] arsize_next_ff;
	reg [1:0] arburst_next_ff;
	reg arlock_next_ff;
	reg [3:0] arcache_next_ff;
	reg [2:0] arprot_next_ff;
	reg [3:0] arqos_next_ff;
	reg arvalid_next_ff;
	reg rready_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_next_ff;
	reg [1:0] bresp_next_ff;
	reg bvalid_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_next_ff;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_next_ff;
	reg [1:0] rresp_next_ff;
	reg rlast_next_ff;
	reg rvalid_next_ff;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_next_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next_next_ff;
	reg [7:0] awlen_next_next_ff;
	reg [2:0] awsize_next_next_ff;
	reg [1:0] awburst_next_next_ff;
	reg awlock_next_next_ff;
	reg [3:0] awcache_next_next_ff;
	reg [2:0] awprot_next_next_ff;
	reg [3:0] awqos_next_next_ff;
	reg awvalid_next_next_ff;
	reg wlast_next_next_ff;
	reg wvalid_next_next_ff;
	reg bready_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next_next_ff;
	reg [7:0] arlen_next_next_ff;
	reg [2:0] arsize_next_next_ff;
	reg [1:0] arburst_next_next_ff;
	reg arlock_next_next_ff;
	reg [3:0] arcache_next_next_ff;
	reg [2:0] arprot_next_next_ff;
	reg [3:0] arqos_next_next_ff;
	reg arvalid_next_next_ff;
	reg rready_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_next_next_ff;
	reg [1:0] bresp_next_next_ff;
	reg bvalid_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_next_next_ff;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_next_next_ff;
	reg [1:0] rresp_next_next_ff;
	reg rlast_next_next_ff;
	reg rvalid_next_next_ff;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_next_next_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next_next_next_ff;
	reg [7:0] awlen_next_next_next_ff;
	reg [2:0] awsize_next_next_next_ff;
	reg [1:0] awburst_next_next_next_ff;
	reg awlock_next_next_next_ff;
	reg [3:0] awcache_next_next_next_ff;
	reg [2:0] awprot_next_next_next_ff;
	reg [3:0] awqos_next_next_next_ff;
	reg awvalid_next_next_next_ff;
	reg wlast_next_next_next_ff;
	reg wvalid_next_next_next_ff;
	reg bready_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next_next_next_ff;
	reg [7:0] arlen_next_next_next_ff;
	reg [2:0] arsize_next_next_next_ff;
	reg [1:0] arburst_next_next_next_ff;
	reg arlock_next_next_next_ff;
	reg [3:0] arcache_next_next_next_ff;
	reg [2:0] arprot_next_next_next_ff;
	reg [3:0] arqos_next_next_next_ff;
	reg arvalid_next_next_next_ff;
	reg rready_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_next_next_next_ff;
	reg [1:0] bresp_next_next_next_ff;
	reg bvalid_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_next_next_next_ff;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_next_next_next_ff;
	reg [1:0] rresp_next_next_next_ff;
	reg rlast_next_next_next_ff;
	reg rvalid_next_next_next_ff;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_next_next_next_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next_next_next_next_ff;
	reg [7:0] awlen_next_next_next_next_ff;
	reg [2:0] awsize_next_next_next_next_ff;
	reg [1:0] awburst_next_next_next_next_ff;
	reg awlock_next_next_next_next_ff;
	reg [3:0] awcache_next_next_next_next_ff;
	reg [2:0] awprot_next_next_next_next_ff;
	reg [3:0] awqos_next_next_next_next_ff;
	reg awvalid_next_next_next_next_ff;
	reg wlast_next_next_next_next_ff;
	reg wvalid_next_next_next_next_ff;
	reg bready_next_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_next_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next_next_next_next_ff;
	reg [7:0] arlen_next_next_next_next_ff;
	reg [2:0] arsize_next_next_next_next_ff;
	reg [1:0] arburst_next_next_next_next_ff;
	reg arlock_next_next_next_next_ff;
	reg [3:0] arcache_next_next_next_next_ff;
	reg [2:0] arprot_next_next_next_next_ff;
	reg [3:0] arqos_next_next_next_next_ff;
	reg arvalid_next_next_next_next_ff;
	reg rready_next_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_next_next_next_next_ff;
	reg [1:0] bresp_next_next_next_next_ff;
	reg bvalid_next_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_next_next_next_next_ff;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_next_next_next_next_ff;
	reg [1:0] rresp_next_next_next_next_ff;
	reg rlast_next_next_next_next_ff;
	reg rvalid_next_next_next_next_ff;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_next_next_next_next_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_next_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next_next_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next_next_next_next_next_ff;
	reg [7:0] awlen_next_next_next_next_next_ff;
	reg [2:0] awsize_next_next_next_next_next_ff;
	reg [1:0] awburst_next_next_next_next_next_ff;
	reg awlock_next_next_next_next_next_ff;
	reg [3:0] awcache_next_next_next_next_next_ff;
	reg [2:0] awprot_next_next_next_next_next_ff;
	reg [3:0] awqos_next_next_next_next_next_ff;
	reg awvalid_next_next_next_next_next_ff;
	reg wlast_next_next_next_next_next_ff;
	reg wvalid_next_next_next_next_next_ff;
	reg bready_next_next_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_next_next_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next_next_next_next_next_ff;
	reg [7:0] arlen_next_next_next_next_next_ff;
	reg [2:0] arsize_next_next_next_next_next_ff;
	reg [1:0] arburst_next_next_next_next_next_ff;
	reg arlock_next_next_next_next_next_ff;
	reg [3:0] arcache_next_next_next_next_next_ff;
	reg [2:0] arprot_next_next_next_next_next_ff;
	reg [3:0] arqos_next_next_next_next_next_ff;
	reg arvalid_next_next_next_next_next_ff;
	reg rready_next_next_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_next_next_next_next_next_ff;
	reg [1:0] bresp_next_next_next_next_next_ff;
	reg bvalid_next_next_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_next_next_next_next_next_ff;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_next_next_next_next_next_ff;
	reg [1:0] rresp_next_next_next_next_next_ff;
	reg rlast_next_next_next_next_next_ff;
	reg rvalid_next_next_next_next_next_ff;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_next_next_next_next_next_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_next_next_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next_next_next_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next_next_next_next_next_next_ff;
	reg [7:0] awlen_next_next_next_next_next_next_ff;
	reg [2:0] awsize_next_next_next_next_next_next_ff;
	reg [1:0] awburst_next_next_next_next_next_next_ff;
	reg awlock_next_next_next_next_next_next_ff;
	reg [3:0] awcache_next_next_next_next_next_next_ff;
	reg [2:0] awprot_next_next_next_next_next_next_ff;
	reg [3:0] awqos_next_next_next_next_next_next_ff;
	reg awvalid_next_next_next_next_next_next_ff;
	reg wlast_next_next_next_next_next_next_ff;
	reg wvalid_next_next_next_next_next_next_ff;
	reg bready_next_next_next_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_next_next_next_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next_next_next_next_next_next_ff;
	reg [7:0] arlen_next_next_next_next_next_next_ff;
	reg [2:0] arsize_next_next_next_next_next_next_ff;
	reg [1:0] arburst_next_next_next_next_next_next_ff;
	reg arlock_next_next_next_next_next_next_ff;
	reg [3:0] arcache_next_next_next_next_next_next_ff;
	reg [2:0] arprot_next_next_next_next_next_next_ff;
	reg [3:0] arqos_next_next_next_next_next_next_ff;
	reg arvalid_next_next_next_next_next_next_ff;
	reg rready_next_next_next_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] bid_next_next_next_next_next_next_ff;
	reg [1:0] bresp_next_next_next_next_next_next_ff;
	reg bvalid_next_next_next_next_next_next_ff;
	reg [C_S_AXI_ID_WIDTH-1:0] rid_next_next_next_next_next_next_ff;
	reg [C_S_AXI_DATA_WIDTH-1:0] rdata_next_next_next_next_next_next_ff;
	reg [1:0] rresp_next_next_next_next_next_next_ff;
	reg rlast_next_next_next_next_next_next_ff;
	reg rvalid_next_next_next_next_next_next_ff;

	reg [C_S_AXI_DATA_WIDTH-1:0] wdata_next_next_next_next_next_next_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_next_next_next_next_next_next_ff;

	reg [C_S_AXI_ID_WIDTH-1:0] awid_next_next_next_next_next_next_next_ff;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next_next_next_next_next_next_next_ff;
	reg [7:0] awlen_next_next_next_next_next_next_next_ff;
	reg [2:0] awsize_next_next_next_next_next_next_next_ff;
	reg [1:0] awburst_next_next_next_next_next_next_next_ff;
	reg awlock_next_next_next_next_next_next_next_ff;
	reg [3:0] awcache_next_next_next_next_next_next_next_ff;
	reg [2:0] awprot_next_next_next_next_next_next_next_ff;
	reg [3:0] awqos_next_next_next_next_next_next_next_ff;
	reg awvalid_next_