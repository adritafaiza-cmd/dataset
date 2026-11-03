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
	wire				awready_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_ff;
	wire				wlast_ff;
	wire				wvalid_ff;
	wire				wready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bvalid_ff;
	wire				bready_ff;
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
	wire				arready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rvalid_ff;
	wire				rready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_sync;
	wire [7 : 0]			awlen_sync;
	wire [2 : 0]			awsize_sync;
	wire [1 : 0]			awburst_sync;
	wire				awlock_sync;
	wire [3 : 0]			awcache_sync;
	wire [2 : 0]			awprot_sync;
	wire [3 : 0]			awqos_sync;
	wire				awvalid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_sync;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_sync;
	wire				wlast_sync;
	wire				wvalid_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync;
	wire [1 : 0]			bresp_sync;
	wire				bvalid_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_sync;
	wire [7 : 0]			arlen_sync;
	wire [2 : 0]			arsize_sync;
	wire [1 : 0]			arburst_sync;
	wire				arlock_sync;
	wire [3 : 0]			arcache_sync;
	wire [2 : 0]			arprot_sync;
	wire [3 : 0]			arqos_sync;
	wire				arvalid_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync;
	wire [1 : 0]			rresp_sync;
	wire				rlast_sync;
	wire				rvalid_sync;

	wire				awvalid_sync_ff;
	wire				wvalid_sync_ff;
	wire				arvalid_sync_ff;
	wire				rvalid_sync_ff;

	wire				awready_sync_ff;
	wire				wready_sync_ff;
	wire				arready_sync_ff;
	wire				rready_sync_ff;

	wire				awvalid_sync_ff2;
	wire				wvalid_sync_ff2;
	wire				arvalid_sync_ff2;
	wire				rvalid_sync_ff2;

	wire				awready_sync_ff2;
	wire				wready_sync_ff2;
	wire				arready_sync_ff2;
	wire				rready_sync_ff2;

	wire				awvalid_sync_ff3;
	wire				wvalid_sync_ff3;
	wire				arvalid_sync_ff3;
	wire				rvalid_sync_ff3;

	wire				awready_sync_ff3;
	wire				wready_sync_ff3;
	wire				arready_sync_ff3;
	wire				rready_sync_ff3;

	wire				awvalid_sync_ff4;
	wire				wvalid_sync_ff4;
	wire				arvalid_sync_ff4;
	wire				rvalid_sync_ff4;

	wire				awready_sync_ff4;
	wire				wready_sync_ff4;
	wire				arready_sync_ff4;
	wire				rready_sync_ff4;

	wire				awvalid_sync_ff5;
	wire				wvalid_sync_ff5;
	wire				arvalid_sync_ff5;
	wire				rvalid_sync_ff5;

	wire				awready_sync_ff5;
	wire				wready_sync_ff5;
	wire				arready_sync_ff5;
	wire				rready_sync_ff5;

	wire				awvalid_sync_ff6;
	wire				wvalid_sync_ff6;
	wire				arvalid_sync_ff6;
	wire				rvalid_sync_ff6;

	wire				awready_sync_ff6;
	wire				wready_sync_ff6;
	wire				arready_sync_ff6;
	wire				rready_sync_ff6;

	wire				awvalid_sync_ff7;
	wire				wvalid_sync_ff7;
	wire				arvalid_sync_ff7;
	wire				rvalid_sync_ff7;

	wire				awready_sync_ff7;
	wire				wready_sync_ff7;
	wire				arready_sync_ff7;
	wire				rready_sync_ff7;

	wire				awvalid_sync_ff8;
	wire				wvalid_sync_ff8;
	wire				arvalid_sync_ff8;
	wire				rvalid_sync_ff8;

	wire				awready_sync_ff8;
	wire				wready_sync_ff8;
	wire				arready_sync_ff8;
	wire				rready_sync_ff8;

	wire				awvalid_sync_ff9;
	wire				wvalid_sync_ff9;
	wire				arvalid_sync_ff9;
	wire				rvalid_sync_ff9;

	wire				awready_sync_ff9;
	wire				wready_sync_ff9;
	wire				arready_sync_ff9;
	wire				rready_sync_ff9;

	wire				awvalid_sync_ff10;
	wire				wvalid_sync_ff10;
	wire				arvalid_sync_ff10;
	wire				rvalid_sync_ff10;

	wire				awready_sync_ff10;
	wire				wready_sync_ff10;
	wire				arready_sync_ff10;
	wire				rready_sync_ff10;

	wire				awvalid_sync_ff11;
	wire				wvalid_sync_ff11;
	wire				arvalid_sync_ff11;
	wire				rvalid_sync_ff11;

	wire				awready_sync_ff11;
	wire				wready_sync_ff11;
	wire				arready_sync_ff11;
	wire				rready_sync_ff11;

	wire				awvalid_sync_ff12;
	wire				wvalid_sync_ff12;
	wire				arvalid_sync_ff12;
	wire				rvalid_sync_ff12;

	wire				awready_sync_ff12;
	wire				wready_sync_ff12;
	wire				arready_sync_ff12;
	wire				rready_sync_ff12;

	wire				awvalid_sync_ff13;
	wire				wvalid_sync_ff13;
	wire				arvalid_sync_ff13;
	wire				rvalid_sync_ff13;

	wire				awready_sync_ff13;
	wire				wready_sync_ff13;
	wire				arready_sync_ff13;
	wire				rready_sync_ff13;

	wire				awvalid_sync_ff14;
	wire				wvalid_sync_ff14;
	wire				arvalid_sync_ff14;
	wire				rvalid_sync_ff14;

	wire				awready_sync_ff14;
	wire				wready_sync_ff14;
	wire				arready_sync_ff14;
	wire				rready_sync_ff14;

	wire				awvalid_sync_ff15;
	wire				wvalid_sync_ff15;
	wire				arvalid_sync_ff15;
	wire				rvalid_sync_ff15;

	wire				awready_sync_ff15;
	wire				wready_sync_ff15;
	wire				arready_sync_ff15;
	wire				rready_sync_ff15;

	wire				awvalid_sync_ff16;
	wire				wvalid_sync_ff16;
	wire				arvalid_sync_ff16;
	wire				rvalid_sync_ff16;

	wire				awready_sync_ff16;
	wire				wready_sync_ff16;
	wire				arready_sync_ff16;
	wire				rready_sync_ff16;

	wire				awvalid_sync_ff17;
	wire				wvalid_sync_ff17;
	wire				arvalid_sync_ff17;
	wire				rvalid_sync_ff17;

	wire				awready_sync_ff17;
	wire				wready_sync_ff17;
	wire				arready_sync_ff17;
	wire				rready_sync_ff17;

	wire				awvalid_sync_ff18;
	wire				wvalid_sync_ff18;
	wire				arvalid_sync_ff18;
	wire				rvalid_sync_ff18;

	wire				awready_sync_ff18;
	wire				wready_sync_ff18;
	wire				arready_sync_ff18;
	wire				rready_sync_ff18;

	wire				awvalid_sync_ff19;
	wire				wvalid_sync_ff19;
	wire				arvalid_sync_ff19;
	wire				rvalid_sync_ff19;

	wire				awready_sync_ff19;
	wire				wready_sync_ff19;
	wire				arready_sync_ff19;
	wire				rready_sync_ff19;

	wire				awvalid_sync_ff20;
	wire				wvalid_sync_ff20;
	wire				arvalid_sync_ff20;
	wire				rvalid_sync_ff20;

	wire				awready_sync_ff20;
	wire				wready_sync_ff20;
	wire				arready_sync_ff20;
	wire				rready_sync_ff20;

	wire				awvalid_sync_ff21;
	wire				wvalid_sync_ff21;
	wire				arvalid_sync_ff21;
	wire				rvalid_sync_ff21;

	wire				awready_sync_ff21;
	wire				wready_sync_ff21;
	wire				arready_sync_ff21;
	wire				rready_sync_ff21;

	wire				awvalid_sync_ff22;
	wire				wvalid_sync_ff22;
	wire				arvalid_sync_ff22;
	wire				rvalid_sync_ff22;

	wire				awready_sync_ff22;
	wire				wready_sync_ff22;
	wire				arready_sync_ff22;
	wire				rready_sync_ff22;

	wire				awvalid_sync_ff23;
	wire				wvalid_sync_ff23;
	wire				arvalid_sync_ff23;
	wire				rvalid_sync_ff23;

	wire				awready_sync_ff23;
	wire				wready_sync_ff23;
	wire				arready_sync_ff23;
	wire				rready_sync_ff23;

	wire				awvalid_sync_ff24;
	wire				wvalid_sync_ff24;
	wire				arvalid_sync_ff24;
	wire				rvalid_sync_ff24;

	wire				awready_sync_ff24;
	wire				wready_sync_ff24;
	wire				arready_sync_ff24;
	wire				rready_sync_ff24;

	wire				awvalid_sync_ff25;
	wire				wvalid_sync_ff25;
	wire				arvalid_sync_ff25;
	wire				rvalid_sync_ff25;

	wire				awready_sync_ff25;
	wire				wready_sync_ff25;
	wire				arready_sync_ff25;
	wire				rready_sync_ff25;

	wire				awvalid_sync_ff26;
	wire				wvalid_sync_ff26;
	wire				arvalid_sync_ff26;
	wire				rvalid_sync_ff26;

	wire				awready_sync_ff26;
	wire				wready_sync_ff26;
	wire				arready_sync_ff26;
	wire				rready_sync_ff26;

	wire				awvalid_sync_ff27;
	wire				wvalid_sync_ff27;
	wire				arvalid_sync_ff27;
	wire				rvalid_sync_ff27;

	wire				awready_sync_ff27;
	wire				wready_sync_ff27;
	wire				arready_sync_ff27;
	wire				rready_sync_ff27;

	wire				awvalid_sync_ff28;
	wire				wvalid_sync_ff28;
	wire				arvalid_sync_ff28;
	wire				rvalid_sync_ff28;

	wire				awready_sync_ff28;
	wire				wready_sync_ff28;
	wire				arready_sync_ff28;
	wire				rready_sync_ff28;

	wire				awvalid_sync_ff29;
	wire				wvalid_sync_ff29;
	wire				arvalid_sync_ff29;
	wire				rvalid_sync_ff29;

	wire				awready_sync_ff29;
	wire				wready_sync_ff29;
	wire				arready_sync_ff29;
	wire				rready_sync_ff29;

	wire				awvalid_sync_ff30;
	wire				wvalid_sync_ff30;
	wire				arvalid_sync_ff30;
	wire				rvalid_sync_ff30;

	wire				awready_sync_ff30;
	wire				wready_sync_ff30;
	wire				arready_sync_ff30;
	wire				rready_sync_ff30;

	wire				awvalid_sync_ff31;
	wire				wvalid_sync_ff31;
	wire				arvalid_sync_ff31;
	wire				rvalid_sync_ff31;

	wire				awready_sync_ff31;
	wire				wready_sync_ff31;
	wire				arready_sync_ff31;
	wire				rready_sync_ff31;

	wire				awvalid_sync_ff32;
	wire				wvalid_sync_ff32;
	wire				arvalid_sync_ff32;
	wire				rvalid_sync_ff32;

	wire				awready_sync_ff32;
	wire				wready_sync_ff32;
	wire				arready_sync_ff32;
	wire				rready_sync_ff32;

	wire				awvalid_sync_ff33;
	wire				wvalid_sync_ff33;
	wire				arvalid_sync_ff33;
	wire				rvalid_sync_ff33;

	wire				awready_sync_ff33;
	wire				wready_sync_ff33;
	wire				arready_sync_ff33;
	wire				rready_sync_ff33;

	wire				awvalid_sync_ff34;
	wire				wvalid_sync_ff34;
	wire				arvalid_sync_ff34;
	wire				rvalid_sync_ff34;

	wire				awready_sync_ff34;
	wire				wready_sync_ff34;
	wire				arready_sync_ff34;
	wire				rready_sync_ff34;

	wire				awvalid_sync_ff35;
	wire				wvalid_sync_ff35;
	wire				arvalid_sync_ff35;
	wire				rvalid_sync_ff35;

	wire				awready_sync_ff35;
	wire				wready_sync_ff35;
	wire				arready_sync_ff35;
	wire				rready_sync_ff35;

	wire				awvalid_sync_ff36;
	wire				wvalid_sync_ff36;
	wire				arvalid_sync_ff36;
	wire				rvalid_sync_ff36;

	wire				awready_sync_ff36;
	wire				wready_sync_ff36;
	wire				arready_sync_ff36;
	wire				rready_sync_ff36;

	wire				awvalid_sync_ff37;
	wire				wvalid_sync_ff37;
	wire				arvalid_sync_ff37;
	wire				rvalid_sync_ff37;

	wire				awready_sync_ff37;
	wire				wready_sync_ff37;
	wire				arready_sync_ff37;
	wire				rready_sync_ff37;

	wire				awvalid_sync_ff38;
	wire				wvalid_sync_ff38;
	wire				arvalid_sync_ff38;
	wire				rvalid_sync_ff38;

	wire				awready_sync_ff38;
	wire				wready_sync_ff38;
	wire				arready_sync_ff38;
	wire				rready_sync_ff38;

	wire				awvalid_sync_ff39;
	wire				wvalid_sync_ff39;
	wire				arvalid_sync_ff39;
	wire				rvalid_sync_ff39;

	wire				awready_sync_ff39;
	wire				wready_sync_ff39;
	wire				arready_sync_ff39;
	wire				rready_sync_ff39;

	wire				awvalid_sync_ff40;
	wire				wvalid_sync_ff40;
	wire				arvalid_sync_ff40;
	wire				rvalid_sync_ff40;

	wire				awready_sync_ff40;
	wire				wready_sync_ff40;
	wire				arready_sync_ff40;
	wire				rready_sync_ff40;

	wire				awvalid_sync_ff41;
	wire				wvalid_sync_ff41;
	wire				arvalid_sync_ff41;
	wire				rvalid_sync_ff41;

	wire				awready_sync_ff41;
	wire				wready_sync_ff41;
	wire				arready_sync_ff41;
	wire				rready_sync_ff41;

	wire				awvalid_sync_ff42;
	wire				wvalid_sync_ff42;
	wire				arvalid_sync_ff42;
	wire				rvalid_sync_ff42;

	wire				awready_sync_ff42;
	wire				wready_sync_ff42;
	wire				arready_sync_ff42;
	wire				rready_sync_ff42;

	wire				awvalid_sync_ff43;
	wire				wvalid_sync_ff43;
	wire				arvalid_sync_ff43;
	wire				rvalid_sync_ff43;

	wire				awready_sync_ff43;
	wire				wready_sync_ff43;
	wire				arready_sync_ff43;
	wire				rready_sync_ff43;

	wire				awvalid_sync_ff44;
	wire				wvalid_sync_ff44;
	wire				arvalid_sync_ff44;
	wire				rvalid_sync_ff44;

	wire				awready_sync_ff44;
	wire				wready_sync_ff44;
	wire				arready_sync_ff44;
	wire				rready_sync_ff44;

	wire				awvalid_sync_ff45;
	wire				wvalid_sync_ff45;
	wire				arvalid_sync_ff45;
	wire				rvalid_sync_ff45;

	wire				awready_sync_ff45;
	wire				wready_sync_ff45;
	wire				arready_sync_ff45;
	wire				rready_sync_ff45;

	wire				awvalid_sync_ff46;
	wire				wvalid_sync_ff46;
	wire				arvalid_sync_ff46;
	wire				rvalid_sync_ff46;

	wire				awready_sync_ff46;
	wire				wready_sync_ff46;
	wire				arready_sync_ff46;
	wire				rready_sync_ff46;

	wire				awvalid_sync_ff47;
	wire				wvalid_sync_ff47;
	wire				arvalid_sync_ff47;
	wire				rvalid_sync_ff47;

	wire				awready_sync_ff47;
	wire				wready_sync_ff47;
	wire				arready_sync_ff47;
	wire				rready_sync_ff47;

	wire				awvalid_sync_ff48;
	wire				wvalid_sync_ff48;
	wire				arvalid_sync_ff48;
	wire				rvalid_sync_ff48;

	wire				awready_sync_ff48;
	wire				wready_sync_ff48;
	wire				arready_sync_ff48;
	wire				rready_sync_ff48;

	wire				awvalid_sync_ff49;
	wire				wvalid_sync_ff49;
	wire				arvalid_sync_ff49;
	wire				rvalid_sync_ff49;

	wire				awready_sync_ff49;
	wire				wready_sync_ff49;
	wire				arready_sync_ff49;
	wire				rready_sync_ff49;

	wire				awvalid_sync_ff50;
	wire				wvalid_sync_ff50;
	wire				arvalid_sync_ff50;
	wire				rvalid_sync_ff50;

	wire				awready_sync_ff50;
	wire				wready_sync_ff50;
	wire				arready_sync_ff50;
	wire				rready_sync_ff50;

	wire				awvalid_sync_ff51;
	wire				wvalid_sync_ff51;
	wire				arvalid_sync_ff51;
	wire				rvalid_sync_ff51;

	wire				awready_sync_ff51;
	wire				wready_sync_ff51;
	wire				arready_sync_ff51;
	wire				rready_sync_ff51;

	wire				awvalid_sync_ff52;
	wire				wvalid_sync_ff52;
	wire				arvalid_sync_ff52;
	wire				rvalid_sync_ff52;

	wire				awready_sync_ff52;
	wire				wready_sync_ff52;
	wire				arready_sync_ff52;
	wire				rready_sync_ff52;

	wire				awvalid_sync_ff53;
	wire				wvalid_sync_ff53;
	wire				arvalid_sync_ff53;
	wire				rvalid_sync_ff53;

	wire				awready_sync_ff53;
	wire				wready_sync_ff53;
	wire				arready_sync_ff53;
	wire				rready_sync_ff53;

	wire				awvalid_sync_ff54;
	wire				wvalid_sync_ff54;
	wire				arvalid_sync_ff54;
	wire				rvalid_sync_ff54;

	wire				awready_sync_ff54;
	wire				wready_sync_ff54;
	wire				arready_sync_ff54;
	wire				rready_sync_ff54;

	wire				awvalid_sync_ff55;
	wire				wvalid_sync_ff55;
	wire				arvalid_sync_ff55;
	wire				rvalid_sync_ff55;

	wire				awready_sync_ff55;
	wire				wready_sync_ff55;
	wire				arready_sync_ff55;
	wire				rready_sync_ff55;

	wire				awvalid_sync_ff56;
	wire				wvalid_sync_ff56;
	wire				arvalid_sync_ff56;
	wire				rvalid_sync_ff56;

	wire				awready_sync_ff56;
	wire				wready_sync_ff56;
	wire				arready_sync_ff56;
	wire				rready_sync_ff56;

	wire				awvalid_sync_ff57;
	wire				wvalid_sync_ff57;
	wire				arvalid_sync_ff57;
	wire				rvalid_sync_ff57;

	wire				awready_sync_ff57;
	wire				wready_sync_ff57;
	wire				arready_sync_ff57;
	wire				rready_sync_ff57;

	wire				awvalid_sync_ff58;
	wire				wvalid_sync_ff58;
	wire				arvalid_sync_ff58;
	wire				rvalid_sync_ff58;

	wire				awready_sync_ff58;
	wire				wready_sync_ff58;
	wire				arready_sync_ff58;
	wire				rready_sync_ff58;

	wire				awvalid_sync_ff59;
	wire				wvalid_sync_ff59;
	wire				arvalid_sync_ff59;
	wire				rvalid_sync_ff59;

	wire				awready_sync_ff59;
	wire				wready_sync_ff59;
	wire				arready_sync_ff59;
	wire				rready_sync_ff59;

	wire				awvalid_sync_ff60;
	wire				wvalid_sync_ff60;
	wire				arvalid_sync_ff60;
	wire				rvalid_sync_ff60;

	wire				awready_sync_ff60;
	wire				wready_sync_ff60;
	wire				arready_sync_ff60;
	wire				rready_sync_ff60;

	wire				awvalid_sync_ff61;
	wire				wvalid_sync_ff61;
	wire				arvalid_sync_ff61;
	wire				rvalid_sync_ff61;

	wire				awready_sync_ff61;
	wire				wready_sync_ff61;
	wire				arready_sync_ff61;
	wire				rready_sync_ff61;

	wire				awvalid_sync_ff62;
	wire				wvalid_sync_ff62;
	wire				arvalid_sync_ff62;
	wire				rvalid_sync_ff62;

	wire				awready_sync_ff62;
	wire				wready_sync_ff62;
	wire				arready_sync_ff62;
	wire				rready_sync_ff62;

	wire				awvalid_sync_ff63;
	wire				wvalid_sync_ff63;
	wire				arvalid_sync_ff63;
	wire				rvalid_sync_ff63;

	wire				awready_sync_ff63;
	wire				wready_sync_ff63;
	wire				arready_sync_ff63;
	wire				rready_sync_ff63;

	wire				awvalid_sync_ff64;
	wire				wvalid_sync_ff64;
	wire				arvalid_sync_ff64;
	wire				rvalid_sync_ff64;

	wire				awready_sync_ff64;
	wire				wready_sync_ff64;
	wire				arready_sync_ff64;
	wire				rready_sync_ff64;

	wire				awvalid_sync_ff65;
	wire				wvalid_sync_ff65;
	wire				arvalid_sync_ff65;
	wire				rvalid_sync_ff65;

	wire				awready_sync_ff65;
	wire				wready_sync_ff65;
	wire				arready_sync_ff65;
	wire				rready_sync_ff65;

	wire				awvalid_sync_ff66;
	wire				wvalid_sync_ff66;
	wire				arvalid_sync_ff66;
	wire				rvalid_sync_ff66;

	wire				awready_sync_ff66;
	wire				wready_sync_ff66;
	wire				arready_sync_ff66;
	wire				rready_sync_ff66;

	wire				awvalid_sync_ff67;
	wire				wvalid_sync_ff67;
	wire				arvalid_sync_ff67;
	wire				rvalid_sync_ff67;

	wire				awready_sync_ff67;
	wire				wready_sync_ff67;
	wire				arready_sync_ff67;
	wire				rready_sync_ff67;

	wire				awvalid_sync_ff68;
	wire				wvalid_sync_ff68;
	wire				arvalid_sync_ff68;
	wire				rvalid_sync_ff68;

	wire				awready_sync_ff68;
	wire				wready_sync_ff68;
	wire				arready_sync_ff68;
	wire				rready_sync_ff68;

	wire				awvalid_sync_ff69;
	wire				wvalid_sync_ff69;
	wire				arvalid_sync_ff69;
	wire				rvalid_sync_ff69;

	wire				awready_sync_ff69;
	wire				wready_sync_ff69;
	wire				arready_sync_ff69;
	wire				rready_sync_ff69;

	wire				awvalid_sync_ff70;
	wire				wvalid_sync_ff70;
	wire				arvalid_sync_ff70;
	wire				rvalid_sync_ff70;

	wire				awready_sync_ff70;
	wire				wready_sync_ff70;
	wire				arready_sync_ff70;
	wire				rready_sync_ff70;

	wire				awvalid_sync_ff71;
	wire				wvalid_sync_ff71;
	wire				arvalid_sync_ff71;
	wire				rvalid_sync_ff71;

	wire				awready_sync_ff71;
	wire				wready_sync_ff71;
	wire				arready_sync_ff71;
	wire				rready_sync_ff71;

	wire				awvalid_sync_ff72;
	wire				wvalid_sync_ff72;
	wire				arvalid_sync_ff72;
	wire				rvalid_sync_ff72;

	wire				awready_sync_ff72;
	wire				wready_sync_ff72;
	wire				arready_sync_ff72;
	wire				rready_sync_ff72;

	wire				awvalid_sync_ff73;
	wire				wvalid_sync_ff73;
	wire				arvalid_sync_ff73;
	wire				rvalid_sync_ff73;

	wire				awready_sync_ff73;
	wire				wready_sync_ff73;
	wire				arready_sync_ff73;
	wire				rready_sync_ff73;

	wire				awvalid_sync_ff74;
	wire				wvalid_sync_ff74;
	wire				arvalid_sync_ff74;
	wire				rvalid_sync_ff74;

	wire				awready_sync_ff74;
	wire				wready_sync_ff74;
	wire				arready_sync_ff74;
	wire				rready_sync_ff74;

	wire				awvalid_sync_ff75;
	wire				wvalid_sync_ff75;
	wire				arvalid_sync_ff75;
	wire				rvalid_sync_ff75;

	wire				awready_sync_ff75;
	wire				wready_sync_ff75;
	wire				arready_sync_ff75;
	wire				rready_sync_ff75;

	wire				awvalid_sync_ff76;
	wire				wvalid_sync_ff76;
	wire				arvalid_sync_ff76;
	wire				rvalid_sync_ff76;

	wire				awready_sync_ff76;
	wire				wready_sync_ff76;
	wire				arready_sync_ff76;
	wire				rready_sync_ff76;

	wire				awvalid_sync_ff77;
	wire				wvalid_sync_ff77;
	wire				arvalid_sync_ff77;
	wire				rvalid_sync_ff77;

	wire				awready_sync_ff77;
	wire				wready_sync_ff77;
	wire				arready_sync_ff77;
	wire				rready_sync_ff77;

	wire				awvalid_sync_ff78;
	wire				wvalid_sync_ff78;
	wire				arvalid_sync_ff78;
	wire				rvalid_sync_ff78;

	wire				awready_sync_ff78;
	wire				wready_sync_ff78;
	wire				arready_sync_ff78;
	wire				rready_sync_ff78;

	wire				awvalid_sync_ff79;
	wire				wvalid_sync_ff79;
	wire				arvalid_sync_ff79;
	wire				rvalid_sync_ff79;

	wire				awready_sync_ff79;
	wire				wready_sync_ff79;
	wire				arready_sync_ff79;
	wire				rready_sync_ff79;

	wire				awvalid_sync_ff80;
	wire				wvalid_sync_ff80;
	wire				arvalid_sync_ff80;
	wire				rvalid_sync_ff80;

	wire				awready_sync_ff80
