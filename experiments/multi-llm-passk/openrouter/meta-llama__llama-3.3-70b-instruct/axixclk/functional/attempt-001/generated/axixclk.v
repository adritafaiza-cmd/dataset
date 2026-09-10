```verilog
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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_ff;
	wire [7 : 0]			awlen_ff;
	wire [2 : 0]			awsize_ff;
	wire [1 : 0]			awburst_ff;
	wire				awlock_ff;
	wire [3 : 0]			awcache_ff;
	wire [2 : 0]			awprot_ff;
	wire [3 : 0]			awqos_ff;
	wire				awvalid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_ff;
	wire				wlast_ff;
	wire				wvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_ff;
	wire [7 : 0]			arlen_ff;
	wire [2 : 0]			arsize_ff;
	wire [1 : 0]			arburst_ff;
	wire				arlock_ff;
	wire [3 : 0]			arcache_ff;
	wire [2 : 0]			arprot_ff;
	wire [3 : 0]			arqos_ff;
	wire				arvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rvalid_ff;

	wire				awready_ff;
	wire				wready_ff;
	wire				arready_ff;
	wire				rready_ff;

	wire				bready_ff;

	wire				awvalid_m;
	wire				wvalid_m;
	wire				arvalid_m;
	wire				rready_m;

	wire				awready_m;
	wire				wready_m;
	wire				arready_m;
	wire				bvalid_m;
	wire				bready_m;
	wire				rvalid_m;

	wire				awvalid_s;
	wire				wvalid_s;
	wire				arvalid_s;
	wire				rready_s;

	wire				awready_s;
	wire				wready_s;
	wire				arready_s;
	wire				bvalid_s;
	wire				bready_s;
	wire				rvalid_s;

	reg				awvalid_ff_reg;
	reg				wvalid_ff_reg;
	reg				arvalid_ff_reg;
	reg				rready_ff_reg;

	reg				awready_ff_reg;
	reg				wready_ff_reg;
	reg				arready_ff_reg;
	reg				bvalid_ff_reg;
	reg				bready_ff_reg;
	reg				rvalid_ff_reg;

	wire				awvalid_ff_sync;
	wire				wvalid_ff_sync;
	wire				arvalid_ff_sync;
	wire				rready_ff_sync;

	wire				awready_ff_sync;
	wire				wready_ff_sync;
	wire				arready_ff_sync;
	wire				bvalid_ff_sync;
	wire				bready_ff_sync;
	wire				rvalid_ff_sync;

	wire				awvalid_m_sync;
	wire				wvalid_m_sync;
	wire				arvalid_m_sync;
	wire				rready_m_sync;

	wire				awready_m_sync;
	wire				wready_m_sync;
	wire				arready_m_sync;
	wire				bvalid_m_sync;
	wire				bready_m_sync;
	wire				rvalid_m_sync;

	wire				awvalid_s_sync;
	wire				wvalid_s_sync;
	wire				arvalid_s_sync;
	wire				rready_s_sync;

	wire				awready_s_sync;
	wire				wready_s_sync;
	wire				arready_s_sync;
	wire				bvalid_s_sync;
	wire				bready_s_sync;
	wire				rvalid_s_sync;

	wire				awvalid_ff_sync2;
	wire				wvalid_ff_sync2;
	wire				arvalid_ff_sync2;
	wire				rready_ff_sync2;

	wire				awready_ff_sync2;
	wire				wready_ff_sync2;
	wire				arready_ff_sync2;
	wire				bvalid_ff_sync2;
	wire				bready_ff_sync2;
	wire				rvalid_ff_sync2;

	wire				awvalid_m_sync2;
	wire				wvalid_m_sync2;
	wire				arvalid_m_sync2;
	wire				rready_m_sync2;

	wire				awready_m_sync2;
	wire				wready_m_sync2;
	wire				arready_m_sync2;
	wire				bvalid_m_sync2;
	wire				bready_m_sync2;
	wire				rvalid_m_sync2;

	wire				awvalid_s_sync2;
	wire				wvalid_s_sync2;
	wire				arvalid_s_sync2;
	wire				rready_s_sync2;

	wire				awready_s_sync2;
	wire				wready_s_sync2;
	wire				arready_s_sync2;
	wire				bvalid_s_sync2;
	wire				bready_s_sync2;
	wire				rvalid_s_sync2;

	wire				awvalid_ff_sync3;
	wire				wvalid_ff_sync3;
	wire				arvalid_ff_sync3;
	wire				rready_ff_sync3;

	wire				awready_ff_sync3;
	wire				wready_ff_sync3;
	wire				arready_ff_sync3;
	wire				bvalid_ff_sync3;
	wire				bready_ff_sync3;
	wire				rvalid_ff_sync3;

	wire				awvalid_m_sync3;
	wire				wvalid_m_sync3;
	wire				arvalid_m_sync3;
	wire				rready_m_sync3;

	wire				awready_m_sync3;
	wire				wready_m_sync3;
	wire				arready_m_sync3;
	wire				bvalid_m_sync3;
	wire				bready_m_sync3;
	wire				rvalid_m_sync3;

	wire				awvalid_s_sync3;
	wire				wvalid_s_sync3;
	wire				arvalid_s_sync3;
	wire				rready_s_sync3;

	wire				awready_s_sync3;
	wire				wready_s_sync3;
	wire				arready_s_sync3;
	wire				bvalid_s_sync3;
	wire				bready_s_sync3;
	wire				rvalid_s_sync3;

	wire				awvalid_ff_sync4;
	wire				wvalid_ff_sync4;
	wire				arvalid_ff_sync4;
	wire				rready_ff_sync4;

	wire				awready_ff_sync4;
	wire				wready_ff_sync4;
	wire				arready_ff_sync4;
	wire				bvalid_ff_sync4;
	wire				bready_ff_sync4;
	wire				rvalid_ff_sync4;

	wire				awvalid_m_sync4;
	wire				wvalid_m_sync4;
	wire				arvalid_m_sync4;
	wire				rready_m_sync4;

	wire				awready_m_sync4;
	wire				wready_m_sync4;
	wire				arready_m_sync4;
	wire				bvalid_m_sync4;
	wire				bready_m_sync4;
	wire				rvalid_m_sync4;

	wire				awvalid_s_sync4;
	wire				wvalid_s_sync4;
	wire				arvalid_s_sync4;
	wire				rready_s_sync4;

	wire				awready_s_sync4;
	wire				wready_s_sync4;
	wire				arready_s_sync4;
	wire				bvalid_s_sync4;
	wire				bready_s_sync4;
	wire				rvalid_s_sync4;

	wire				awvalid_ff_sync5;
	wire				wvalid_ff_sync5;
	wire				arvalid_ff_sync5;
	wire				rready_ff_sync5;

	wire				awready_ff_sync5;
	wire				wready_ff_sync5;
	wire				arready_ff_sync5;
	wire				bvalid_ff_sync5;
	wire				bready_ff_sync5;
	wire				rvalid_ff_sync5;

	wire				awvalid_m_sync5;
	wire				wvalid_m_sync5;
	wire				arvalid_m_sync5;
	wire				rready_m_sync5;

	wire				awready_m_sync5;
	wire				wready_m_sync5;
	wire				arready_m_sync5;
	wire				bvalid_m_sync5;
	wire				bready_m_sync5;
	wire				rvalid_m_sync5;

	wire				awvalid_s_sync5;
	wire				wvalid_s_sync5;
	wire				arvalid_s_sync5;
	wire				rready_s_sync5;

	wire				awready_s_sync5;
	wire				wready_s_sync5;
	wire				arready_s_sync5;
	wire				bvalid_s_sync5;
	wire				bready_s_sync5;
	wire				rvalid_s_sync5;

	wire				awvalid_ff_sync6;
	wire				wvalid_ff_sync6;
	wire				arvalid_ff_sync6;
	wire				rready_ff_sync6;

	wire				awready_ff_sync6;
	wire				wready_ff_sync6;
	wire				arready_ff_sync6;
	wire				bvalid_ff_sync6;
	wire				bready_ff_sync6;
	wire				rvalid_ff_sync6;

	wire				awvalid_m_sync6;
	wire				wvalid_m_sync6;
	wire				arvalid_m_sync6;
	wire				rready_m_sync6;

	wire				awready_m_sync6;
	wire				wready_m_sync6;
	wire				arready_m_sync6;
	wire				bvalid_m_sync6;
	wire				bready_m_sync6;
	wire				rvalid_m_sync6;

	wire				awvalid_s_sync6;
	wire				wvalid_s_sync6;
	wire				arvalid_s_sync6;
	wire				rready_s_sync6;

	wire				awready_s_sync6;
	wire				wready_s_sync6;
	wire				arready_s_sync6;
	wire				bvalid_s_sync6;
	wire				bready_s_sync6;
	wire				rvalid_s_sync6;

	wire				awvalid_ff_sync7;
	wire				wvalid_ff_sync7;
	wire				arvalid_ff_sync7;
	wire				rready_ff_sync7;

	wire				awready_ff_sync7;
	wire				wready_ff_sync7;
	wire				arready_ff_sync7;
	wire				bvalid_ff_sync7;
	wire				bready_ff_sync7;
	wire				rvalid_ff_sync7;

	wire				awvalid_m_sync7;
	wire				wvalid_m_sync7;
	wire				arvalid_m_sync7;
	wire				rready_m_sync7;

	wire				awready_m_sync7;
	wire				wready_m_sync7;
	wire				arready_m_sync7;
	wire				bvalid_m_sync7;
	wire				bready_m_sync7;
	wire				rvalid_m_sync7;

	wire				awvalid_s_sync7;
	wire				wvalid_s_sync7;
	wire				arvalid_s_sync7;
	wire				rready_s_sync7;

	wire				awready_s_sync7;
	wire				wready_s_sync7;
	wire				arready_s_sync7;
	wire				bvalid_s_sync7;
	wire				bready_s_sync7;
	wire				rvalid_s_sync7;

	wire				awvalid_ff_sync8;
	wire				wvalid_ff_sync8;
	wire				arvalid_ff_sync8;
	wire				rready_ff_sync8;

	wire				awready_ff_sync8;
	wire				wready_ff_sync8;
	wire				arready_ff_sync8;
	wire				bvalid_ff_sync8;
	wire				bready_ff_sync8;
	wire				rvalid_ff_sync8;

	wire				awvalid_m_sync8;
	wire				wvalid_m_sync8;
	wire				arvalid_m_sync8;
	wire				rready_m_sync8;

	wire				awready_m_sync8;
	wire				wready_m_sync8;
	wire				arready_m_sync8;
	wire				bvalid_m_sync8;
	wire				bready_m_sync8;
	wire				rvalid_m_sync8;

	wire				awvalid_s_sync8;
	wire				wvalid_s_sync8;
	wire				arvalid_s_sync8;
	wire				rready_s_sync8;

	wire				awready_s_sync8;
	wire				wready_s_sync8;
	wire				arready_s_sync8;
	wire				bvalid_s_sync8;
	wire				bready_s_sync8;
	wire				rvalid_s_sync8;

	wire				awvalid_ff_sync9;
	wire				wvalid_ff_sync9;
	wire				arvalid_ff_sync9;
	wire				rready_ff_sync9;

	wire				awready_ff_sync9;
	wire				wready_ff_sync9;
	wire				arready_ff_sync9;
	wire				bvalid_ff_sync9;
	wire				bready_ff_sync9;
	wire				rvalid_ff_sync9;

	wire				awvalid_m_sync9;
	wire				wvalid_m_sync9;
	wire				arvalid_m_sync9;
	wire				rready_m_sync9;

	wire				awready_m_sync9;
	wire				wready_m_sync9;
	wire				arready_m_sync9;
	wire				bvalid_m_sync9;
	wire				bready_m_sync9;
	wire				rvalid_m_sync9;

	wire				awvalid_s_sync9;
	wire				wvalid_s_sync9;
	wire				arvalid_s_sync9;
	wire				rready_s_sync9;

	wire				awready_s_sync9;
	wire				wready_s_sync9;
	wire				arready_s_sync9;
	wire				bvalid_s_sync9;
	wire				bready_s_sync9;
	wire				rvalid_s_sync9;

	wire				awvalid_ff_sync10;
	wire				wvalid_ff_sync10;
	wire				arvalid_ff_sync10;
	wire				rready_ff_sync10;

	wire				awready_ff_sync10;
	wire				wready_ff_sync10;
	wire				arready_ff_sync10;
	wire				bvalid_ff_sync10;
	wire				bready_ff_sync10;
	wire				rvalid_ff_sync10;

	wire				awvalid_m_sync10;
	wire				wvalid_m_sync10;
	wire				arvalid_m_sync10;
	wire				rready_m_sync10;

	wire				awready_m_sync10;
	wire				wready_m_sync10;
	wire				arready_m_sync10;
	wire				bvalid_m_sync10;
	wire				bready_m_sync10;
	wire				rvalid_m_sync10;

	wire				awvalid_s_sync10;
	wire				wvalid_s_sync10;
	wire				arvalid_s_sync10;
	wire				rready_s_sync10;

	wire				awready_s_sync10;
	wire				wready_s_sync10;
	wire				arready_s_sync10;
	wire				bvalid_s_sync10;
	wire				bready_s_sync10;
	wire				rvalid_s_sync10;

	wire				awvalid_ff_sync11;
	wire				wvalid_ff_sync11;
	wire				arvalid_ff_sync11;
	wire				rready_ff_sync11;

	wire				awready_ff_sync11;
	wire				wready_ff_sync11;
	wire				arready_ff_sync11;
	wire				bvalid_ff_sync11;
	wire				bready_ff_sync11;
	wire				rvalid_ff_sync11;

	wire				awvalid_m_sync11;
	wire				wvalid_m_sync11;
	wire				arvalid_m_sync11;
	wire				rready_m_sync11;

	wire				awready_m_sync11;
	wire				wready_m_sync11;
	wire				arready_m_sync11;
	wire				bvalid_m_sync11;
	wire				bready_m_sync11;
	wire				rvalid_m_sync11;

	wire				awvalid_s_sync11;
	wire				wvalid_s_sync11;
	wire				arvalid_s_sync11;
	wire				rready_s_sync11;

	wire				awready_s_sync11;
	wire				wready_s_sync11;
	wire				arready_s_sync11;
	wire				bvalid_s_sync11;
	wire				bready_s_sync11;
	wire				rvalid_s_sync11;

	wire				awvalid_ff_sync12;
	wire				wvalid_ff_sync12;
	wire				arvalid_ff_sync12;
	wire				rready_ff_sync12;

	wire				awready_ff_sync12;
	wire				wready_ff_sync12;
	wire				arready_ff_sync12;
	wire				bvalid_ff_sync12;
	wire				bready_ff_sync12;
	wire				rvalid_ff_sync12;

	wire				awvalid_m_sync12;
	wire				wvalid_m_sync12;
	wire				arvalid_m_sync12;
	wire				rready_m_sync12;

	wire				awready_m_sync12;
	wire				wready_m_sync12;
	wire				arready_m_sync12;
	wire				bvalid_m_sync12;
	wire				bready_m_sync12;
	wire				rvalid_m_sync12;

	wire				awvalid_s_sync12;
	wire				wvalid_s_sync12;
	wire				arvalid_s_sync12;
	wire				rready_s_sync12;

	wire				awready_s_sync12;
	wire				wready_s_sync12;
	wire				arready_s_sync12;
	wire				bvalid_s_sync12;
	wire				bready_s_sync12;
	wire				rvalid_s_sync12;

	wire				awvalid_ff_sync13;
	wire				wvalid_ff_sync13;
	wire				arvalid_ff_sync13;
	wire				rready_ff_sync13;

	wire				awready_ff_sync13;
	wire				wready_ff_sync13;
	wire				arready_ff_sync13;
	wire				bvalid_ff_sync13;
	wire				bready_ff_sync13;
	wire				rvalid_ff_sync13;

	wire				awvalid_m_sync13;
	wire				wvalid_m_sync13;
	wire				arvalid_m_sync13;
	wire				rready_m_sync13;

	wire				awready_m_sync13;
	wire				wready_m_sync13;
	wire				arready_m_sync13;
	wire				bvalid_m_sync13;
	wire				bready_m_sync13;
	wire				rvalid_m_sync13;

	wire				awvalid_s_sync13;
	wire				wvalid_s_sync13;
	wire				arvalid_s_sync13;
	wire				rready_s_sync13;

	wire				awready_s_sync13;
	wire				wready_s_sync13;
	wire				arready_s_sync13;
	wire				bvalid_s_sync13;
	wire				bready_s_sync13;
	wire				rvalid_s_sync13;

	wire				awvalid_ff_sync14;
	wire				wvalid_ff_sync14;
	wire				arvalid_ff_sync14;
	wire				rready_ff_sync14;

	wire				awready_ff_sync14;
	wire				wready_ff_sync14;
	wire				arready_ff_sync14;
	wire				bvalid_ff_sync14;
	wire				bready_ff_sync14;
	wire				rvalid_ff_sync14;

	wire				awvalid_m_sync14;
	wire				wvalid_m_sync14;
	wire				arvalid_m_sync14;
	wire				rready_m_sync14;

	wire				awready_m_sync14;
	wire				wready_m_sync14;
	wire				arready_m_sync14;
	wire				bvalid_m_sync14;
	wire				bready_m_sync14;
	wire				rvalid_m_sync14;

	wire				awvalid_s_sync14;
	wire				wvalid_s_sync14;
	wire				arvalid_s_sync14;
	wire				rready_s_sync14;

	wire				awready_s_sync14;
	wire				wready_s_sync14;
	wire				arready_s_sync14;
	wire				bvalid_s_sync14;
	wire				bready_s_sync14;
	wire				rvalid_s_sync14;

	wire				awvalid_ff_sync15;
	wire				wvalid_ff_sync15;
	wire				arvalid_ff_sync15;
	wire				rready_ff_sync15;

	wire				awready_ff_sync15;
	wire				wready_ff_sync15;
	wire				arready_ff_sync15;
	wire				bvalid_ff_sync15;
	wire				bready_ff_sync15;
	wire				rvalid_ff_sync15;

	wire				awvalid_m_sync15;
	wire				wvalid_m_sync15;
	wire				arvalid_m_sync15;
	wire				rready_m_sync15;

	wire				awready_m_sync15;
	wire				wready_m_sync15;
	wire				arready_m_sync15;
	wire				bvalid_m_sync15;
	wire				bready_m_sync15;
	wire				rvalid_m_sync15;

	wire				awvalid_s_sync15;
	wire				wvalid_s_sync15;
	wire				arvalid_s_sync15;
	wire				rready_s_sync15;

	wire				awready_s_sync15;
	wire				wready_s_sync15;
	wire				arready_s_sync15;
	wire				bvalid_s_sync15;
	wire				bready_s_sync15;
	wire				rvalid_s_sync15;

	wire				awvalid_ff_sync16;
	wire				wvalid_ff_sync16;
	wire				arvalid_ff_sync16;
	wire				rready_ff_sync16;

	wire				awready_ff_sync16;
	wire				wready_ff_sync16;
	wire				arready_ff_sync16;
	wire				bvalid_ff_sync16;
	wire				bready_ff_sync16;
	wire				rvalid_ff_sync16;

	wire				awvalid_m_sync16;
	wire				wvalid_m_sync16;
	wire				arvalid_m_sync16;
	wire				rready_m_sync16;

	wire				awready_m_sync16;
	wire				wready_m_sync16;
	wire				arready_m_sync16;
	wire				bvalid_m_sync16;
	wire				bready_m_sync16;
	wire				rvalid_m_sync16;

	wire				awvalid_s_sync16;
	wire				wvalid_s_sync16;
	wire				arvalid_s_sync16;
	wire				rready_s_sync16;

	wire				awready_s_sync16;
	wire				wready_s_sync16;
	wire				arready_s_sync16;
	wire				bvalid_s_sync16;
	wire				bready_s_sync16;
	wire				rvalid_s_sync16;

	wire				awvalid_ff_sync17;
	wire				wvalid_ff_sync17;
	wire				arvalid_ff_sync17;
	wire				rready_ff_sync17;

	wire				awready_ff_sync17;
	wire				wready_ff_sync17;
	wire				arready_ff_sync17;
	wire				bvalid_ff_sync17;
	wire				bready_ff_sync17;
	wire				rvalid_ff_sync17;

	wire				awvalid_m_sync17;
	wire				wvalid_m_sync17;
	wire				arvalid_m_sync17;
	wire				rready_m_sync17;

	wire				awready_m_sync17;
	wire				wready_m_sync17;
	wire				arready_m_sync17;
	wire				bvalid_m_sync17;
	wire				bready_m_sync17;
	wire				rvalid_m_sync17;

	wire				awvalid_s_sync17;
	wire				wvalid_s_sync17;
	wire				arvalid_s_sync17;
	wire				rready_s_sync17;

	wire				awready_s_sync17;
	wire				wready_s_sync17;
	wire				arready_s_sync17;
	wire				bvalid_s_sync17;
	wire				bready_s_sync17;
	wire				rvalid_s_sync17;

	wire				awvalid_ff_sync18;
	wire				wvalid_ff_sync18;
	wire				arvalid_ff_sync18;
	wire				rready_ff_sync18;

	wire				awready_ff_sync18;
	wire				wready_ff_sync18;
	wire				arready_ff_sync18;
	wire				bvalid_ff_sync18;
	wire				bready_ff_sync18;
	wire				rvalid_ff_sync18;

	wire				awvalid_m_sync18;
	wire				wvalid_m_sync18;
	wire				arvalid_m_sync18;
	wire				rready_m_sync18;

	wire				awready_m_sync18;
	wire				wready_m_sync18;
	wire				arready_m_sync18;
	wire				bvalid_m_sync18;
	wire				bready_m_sync18;
	wire				rvalid_m_sync18;

	wire				awvalid_s_sync18;
	wire				wvalid_s_sync18;
	wire				arvalid_s_sync18;
	wire				rready_s_sync18;

	wire				awready_s_sync18;
	wire				wready_s_sync18;
	wire				arready_s_sync18;
	wire				bvalid_s_sync18;
	wire				bready_s_sync18;
	wire				rvalid_s_sync18;

	wire				awvalid_ff_sync19;
	wire				wvalid_ff_sync19;
	wire				arvalid_ff_sync19;
	wire				rready_ff_sync19;

	wire				awready_ff_sync19;
	wire				wready_ff_sync19;
	wire				arready_ff_sync19;
	wire				bvalid_ff_sync19;
	wire				bready_ff_sync19;
	wire				rvalid_ff_sync19;

	wire				awvalid_m_sync19;
	wire				wvalid_m_sync19;
	wire				arvalid_m_sync19;
	wire				rready_m_sync19;

	wire				awready_m_sync19;
	wire				wready_m_sync19;
	wire				arready_m_sync19;
	wire				bvalid_m_sync19;
	wire				bready_m_sync19;
	wire				rvalid_m_sync19;

	wire				awvalid_s_sync19;
	wire				wvalid_s_sync19;
	wire				arvalid_s_sync19;
	wire				rready_s_sync19;

	wire				awready_s_sync19;
	wire				wready_s_sync19;
	wire				arready_s_sync19;
	wire				bvalid_s_sync19;
	wire				bready_s_sync19;
	wire				rvalid_s_sync19;

	wire				awvalid_ff_sync20;
	wire				wvalid_ff_sync20;
	wire				arvalid_ff_sync20;
	wire				rready_ff_sync20;

	wire				awready_ff_sync20;
	wire				wready_ff_sync20;
	wire				arready_ff_sync20;
	wire				bvalid_ff_sync20;
	wire				bready_ff_sync20;
	wire				rvalid_ff_sync20;

	wire				awvalid_m_sync20;
	wire				wvalid_m_sync20;
	wire				arvalid_m_sync20;
	wire				rready_m_sync20;

	wire				awready_m_sync20;
	wire				wready_m_sync20;
	wire				arready_m_sync20;
	wire				bvalid_m_sync20;
	wire				bready_m_sync20;
	wire				rvalid_m_sync20;

	wire				awvalid_s_sync20;
	wire				wvalid_s_sync20;
	wire				arvalid_s_sync20;
	wire				rready_s_sync20;

	wire				awready_s_sync20;
	wire				wready_s_sync20;
	wire				arready_s_sync20;
	wire				bvalid_s_sync20;
	wire				bready_s_sync20;
	wire				rvalid_s_sync20;

	wire				awvalid_ff_sync21;
	wire				wvalid_ff_sync21;
	wire				arvalid_ff_sync21;
	wire				rready_ff_sync21;

	wire				awready_ff_sync21;
	wire				wready_ff_sync21;
	wire				arready_ff_sync21;
	wire				bvalid_ff_sync21;
	wire				bready_ff_sync21;
	wire				rvalid_ff_sync21;

	wire				awvalid_m_sync21;
	wire				wvalid_m_sync21;
	wire				arvalid_m_sync21;
	wire				rready_m_sync21;

	wire				awready_m_sync21;
	wire				wready_m_sync21;
	wire				arready_m_sync21;
	wire				bvalid_m_sync21;
	wire				bready_m_sync21;
	wire				rvalid_m_sync21;

	wire				awvalid_s_sync21;
	wire				wvalid_s_sync21;
	wire				arvalid_s_sync21;
	wire				rready_s_sync21;

	wire				awready_s_sync21;
	wire				wready_s_sync21;
	wire				arready_s_sync21;
	wire				bvalid_s_sync21;
	wire				bready_s_sync21;
	wire				rvalid_s_sync21;

	wire				awvalid_ff_sync22;
	wire				wvalid_ff_sync22;
	wire				arvalid_ff_sync22;
	wire				rready_ff_sync22;

	wire				awready_ff_sync22;
	wire				wready_ff_sync22;
	wire				arready_ff_sync22;
	wire				bvalid_ff_sync22;
	wire				bready_ff_sync22;
	wire				rvalid_ff_sync22;

	wire				awvalid_m_sync22;
	wire				wvalid_m_sync22;
	wire				arvalid_m_sync22;
	wire				rready_m_sync22;

	wire				awready_m_sync22;
	wire				wready_m_sync22;
	wire				arready_m_sync22;
	wire				bvalid_m_sync22;
	wire				bready_m_sync22;
	wire				rvalid_m_sync22;

	wire				awvalid_s_sync22;
	wire				wvalid_s_sync22;
	wire				arvalid_s_sync22;
	wire				rready_s_sync22;

	wire				awready_s_sync22;
	wire				wready_s_sync22;
	wire				arready_s_sync22;
	wire				bvalid_s_sync22;
	wire				bready_s_sync22;
	wire				rvalid_s_sync22;

	wire				awvalid_ff_sync23;
	wire				wvalid_ff_sync23;
	wire				arvalid_ff_sync23;
	wire				rready_ff_sync23;

	wire				awready_ff_sync23;
	wire				wready_ff_sync23;
	wire				ar
