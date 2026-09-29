Please act as a professional Verilog designer.

Implement an AXI4 clock-domain bridge.

Module name:
    axixclk

Language:
    Verilog-2001

Clocks:
    S_AXI_ACLK: Independent asynchronous clock (async to M_AXI_ACLK). No fixed frequency or phase relationship.
    M_AXI_ACLK: Independent asynchronous clock (async to S_AXI_ACLK).

Resets:
    S_AXI_ARESETN: active-low.

Input ports:
    S_AXI_ACLK: Clock.
    S_AXI_ARESETN: Active-low reset.
    S_AXI_AWID: See Behavior.
    S_AXI_AWADDR: Address.
    S_AXI_AWLEN: See Behavior.
    S_AXI_AWSIZE: See Behavior.
    S_AXI_AWBURST: Reset reset.
    S_AXI_AWLOCK: See Behavior.
    S_AXI_AWCACHE: See Behavior.
    S_AXI_AWPROT: Protection bits.
    S_AXI_AWQOS: See Behavior.
    S_AXI_AWVALID: Handshake valid.
    S_AXI_WDATA: Data payload.
    S_AXI_WSTRB: Write strobes.
    S_AXI_WLAST: See Behavior.
    S_AXI_WVALID: Handshake valid.
    S_AXI_BREADY: Handshake ready.
    S_AXI_ARID: See Behavior.
    S_AXI_ARADDR: Address.
    S_AXI_ARLEN: See Behavior.
    S_AXI_ARSIZE: See Behavior.
    S_AXI_ARBURST: Reset reset.
    S_AXI_ARLOCK: See Behavior.
    S_AXI_ARCACHE: See Behavior.
    S_AXI_ARPROT: Protection bits.
    S_AXI_ARQOS: See Behavior.
    S_AXI_ARVALID: Handshake valid.
    S_AXI_RREADY: Handshake ready.
    M_AXI_ACLK: Clock.
    M_AXI_AWREADY: Handshake ready.
    M_AXI_WREADY: Handshake ready.
    M_AXI_BID: See Behavior.
    M_AXI_BRESP: Response status.
    M_AXI_BVALID: Handshake valid.
    M_AXI_ARREADY: Handshake ready.
    M_AXI_RID: See Behavior.
    M_AXI_RDATA: Data payload.
    M_AXI_RRESP: Response status.
    M_AXI_RLAST: See Behavior.
    M_AXI_RVALID: Handshake valid.

Output ports:
    S_AXI_AWREADY: Handshake ready.
    S_AXI_WREADY: Handshake ready.
    S_AXI_BID: See Behavior.
    S_AXI_BRESP: Response status.
    S_AXI_BVALID: Handshake valid.
    S_AXI_ARREADY: Handshake ready.
    S_AXI_RID: See Behavior.
    S_AXI_RDATA: Data payload.
    S_AXI_RRESP: Response status.
    S_AXI_RLAST: See Behavior.
    S_AXI_RVALID: Handshake valid.
    M_AXI_ARESETN: Active-low reset.
    M_AXI_AWID: See Behavior.
    M_AXI_AWADDR: Address.
    M_AXI_AWLEN: See Behavior.
    M_AXI_AWSIZE: See Behavior.
    M_AXI_AWBURST: Reset reset.
    M_AXI_AWLOCK: See Behavior.
    M_AXI_AWCACHE: See Behavior.
    M_AXI_AWPROT: Protection bits.
    M_AXI_AWQOS: See Behavior.
    M_AXI_AWVALID: Handshake valid.
    M_AXI_WDATA: Data payload.
    M_AXI_WSTRB: Write strobes.
    M_AXI_WLAST: See Behavior.
    M_AXI_WVALID: Handshake valid.
    M_AXI_BREADY: Handshake ready.
    M_AXI_ARID: See Behavior.
    M_AXI_ARADDR: Address.
    M_AXI_ARLEN: See Behavior.
    M_AXI_ARSIZE: See Behavior.
    M_AXI_ARBURST: Reset reset.
    M_AXI_ARLOCK: See Behavior.
    M_AXI_ARCACHE: See Behavior.
    M_AXI_ARPROT: Protection bits.
    M_AXI_ARQOS: See Behavior.
    M_AXI_ARVALID: Handshake valid.
    M_AXI_RREADY: Handshake ready.

Parameters:
    C_S_AXI_ID_WIDTH: See Behavior.
    C_S_AXI_DATA_WIDTH: See Behavior.
    C_S_AXI_ADDR_WIDTH: See Behavior.
    OPT_WRITE_ONLY: See Behavior.
    OPT_READ_ONLY: See Behavior.
    XCLOCK_FFS: Implementation parameter. Choose a safe crossing yourself.
    LGFIFO: Log2 of the number of FIFO entries.

Behavior:
    - Accept AXI4 on the slave ports and forward each burst exactly once to the master ports.
    - Return write responses and read data without loss or reordering beyond AXI outstanding-transaction rules.
    - Reset must not create a burst.
    - OPT_WRITE_ONLY / OPT_READ_ONLY may omit the unused direction.
    - LGFIFO sizes internal buffering. XCLOCK_FFS is an implementation parameter; choose a safe crossing yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
