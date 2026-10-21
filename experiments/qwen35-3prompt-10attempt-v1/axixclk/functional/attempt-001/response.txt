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

	// Cross Clock FIFO Parameters
	localparam INTEGER FIFO_DEPTH = 2 ** LGFIFO;
	localparam INTEGER DATA_WIDTH = C_S_AXI_DATA_WIDTH;
	localparam INTEGER ADDR_WIDTH = C_S_AXI_ADDR_WIDTH;
	localparam INTEGER ID_WIDTH = C_S_AXI_ID_WIDTH;
	localparam INTEGER LEN_WIDTH = 8;
	localparam INTEGER SIZE_WIDTH = 3;
	localparam INTEGER BURST_WIDTH = 2;
	localparam INTEGER LOCK_WIDTH = 1;
	localparam INTEGER CACHE_WIDTH = 4;
	localparam INTEGER PROT_WIDTH = 3;
	localparam INTEGER QOS_WIDTH = 4;
	localparam INTEGER WSTRB_WIDTH = (DATA_WIDTH / 8);

	// Cross Clock FIFO Instance Parameters
	localparam INTEGER FIFO_ADDR_WIDTH = LGFIFO + 1; // Address + Valid
	localparam INTEGER FIFO_DATA_WIDTH = DATA_WIDTH + WSTRB_WIDTH + 1; // Data + Strb + Last

	// Cross Clock FIFO Parameters for Address/Control
	localparam INTEGER FIFO_CTRL_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_CTRL_DATA_WIDTH = ADDR_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_WIDTH + LOCK_WIDTH + CACHE_WIDTH + PROT_WIDTH + QOS_WIDTH + 1; // +1 for Valid

	// Cross Clock FIFO Parameters for ID
	localparam INTEGER FIFO_ID_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_ID_DATA_WIDTH = ID_WIDTH + 1; // +1 for Valid

	// Cross Clock FIFO Parameters for Response
	localparam INTEGER FIFO_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RESP_DATA_WIDTH = ID_WIDTH + 1 + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Data
	localparam INTEGER FIFO_WR_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_DATA_WIDTH = DATA_WIDTH + WSTRB_WIDTH + 1; // Data + Strb + Last + Valid

	// Cross Clock FIFO Parameters for Read Data
	localparam INTEGER FIFO_RD_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_DATA_WIDTH = DATA_WIDTH + 1; // Data + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read Response
	localparam INTEGER FIFO_RD_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_RD_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Last + Valid

	// Cross Clock FIFO Parameters for Write Response
	localparam INTEGER FIFO_WR_RESP_ADDR_WIDTH = LGFIFO + 1;
	localparam INTEGER FIFO_WR_RESP_DATA_WIDTH = ID_WIDTH + 2 + 1; // ID + Resp + Valid

	// Cross Clock FIFO Parameters for Read