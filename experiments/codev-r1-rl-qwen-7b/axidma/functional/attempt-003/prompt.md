Please act as a professional Verilog designer.

Implement a single-clock AXI DMA with an AXI4-Lite control port.

Module name:
    axidma

Language:
    Verilog-2001

Clocks:
    S_AXI_ACLK: Single clock.

Resets:
    S_AXI_ARESETN: active-low.

Input ports:
    S_AXI_ACLK: Clock.
    S_AXI_ARESETN: Active-low reset.
    S_AXIL_AWVALID: Handshake valid.
    S_AXIL_AWADDR: Address.
    S_AXIL_AWPROT: Protection bits.
    S_AXIL_WVALID: Handshake valid.
    S_AXIL_WDATA: Data payload.
    S_AXIL_WSTRB: Write strobes.
    S_AXIL_BREADY: Handshake ready.
    S_AXIL_ARVALID: Handshake valid.
    S_AXIL_ARADDR: Address.
    S_AXIL_ARPROT: Protection bits.
    S_AXIL_RREADY: Handshake ready.
    M_AXI_AWREADY: Handshake ready.
    M_AXI_WREADY: Handshake ready.
    M_AXI_BVALID: Handshake valid.
    M_AXI_BID: See Behavior.
    M_AXI_BRESP: Response status.
    M_AXI_ARREADY: Handshake ready.
    M_AXI_RVALID: Handshake valid.
    M_AXI_RID: See Behavior.
    M_AXI_RDATA: Data payload.
    M_AXI_RLAST: See Behavior.
    M_AXI_RRESP: Response status.

Output ports:
    S_AXIL_AWREADY: Handshake ready.
    S_AXIL_WREADY: Handshake ready.
    S_AXIL_BVALID: Handshake valid.
    S_AXIL_BRESP: Response status.
    S_AXIL_ARREADY: Handshake ready.
    S_AXIL_RVALID: Handshake valid.
    S_AXIL_RDATA: Data payload.
    S_AXIL_RRESP: Response status.
    M_AXI_AWVALID: Handshake valid.
    M_AXI_AWID: See Behavior.
    M_AXI_AWADDR: Address.
    M_AXI_AWSIZE: See Behavior.
    M_AXI_AWBURST: Reset reset.
    M_AXI_AWLOCK: See Behavior.
    M_AXI_AWCACHE: See Behavior.
    M_AXI_AWPROT: Protection bits.
    M_AXI_AWQOS: See Behavior.
    M_AXI_WVALID: Handshake valid.
    M_AXI_WDATA: Data payload.
    M_AXI_WSTRB: Write strobes.
    M_AXI_WLAST: See Behavior.
    M_AXI_BREADY: Handshake ready.
    M_AXI_ARVALID: Handshake valid.
    M_AXI_ARID: See Behavior.
    M_AXI_ARADDR: Address.
    M_AXI_ARSIZE: See Behavior.
    M_AXI_ARBURST: Reset reset.
    M_AXI_ARLOCK: See Behavior.
    M_AXI_ARCACHE: See Behavior.
    M_AXI_ARPROT: Protection bits.
    M_AXI_ARQOS: See Behavior.
    M_AXI_RREADY: Handshake ready.
    o_int: See Behavior.

Parameters:
    C_AXI_ID_WIDTH: See Behavior.
    C_AXI_ADDR_WIDTH: See Behavior.
    C_AXI_DATA_WIDTH: See Behavior.
    OPT_UNALIGNED: See Behavior.
    OPT_WRAPMEM: See Behavior.
    LGFIFO: Log2 of the number of FIFO entries.
    LGLEN: See Behavior.
    OPT_LOWPOWER: See Behavior.
    OPT_CLKGATE: See Behavior.
    AXI_READ_ID: See Behavior.
    AXI_WRITE_ID: See Behavior.
    ABORT_KEY: See Behavior.

Behavior:
    - Software programs source, destination, and length through the 32-bit Lite registers.
    - The core then copies memory using AXI4.
    - OPT_UNALIGNED and OPT_WRAPMEM change address handling as named.
    - After reset the engine is stopped and must not issue AXI transfers.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module	axidma #(
		parameter	C_AXI_ID_WIDTH = 1,
		parameter	C_AXI_ADDR_WIDTH = 32,
		parameter	C_AXI_DATA_WIDTH = 32,
		localparam	C_AXIL_ADDR_WIDTH = 5,
		localparam	C_AXIL_DATA_WIDTH = 32,
		parameter [0:0]	OPT_UNALIGNED = 1'b1,
		parameter [0:0]	OPT_WRAPMEM = 1'b1,
		parameter	LGFIFO = LGMAXBURST+1,
		parameter	LGLEN = C_AXI_ADDR_WIDTH,
		parameter [0:0]	OPT_LOWPOWER = 1'b0,
		parameter [0:0]	OPT_CLKGATE = OPT_LOWPOWER,
		parameter	[C_AXI_ID_WIDTH-1:0]	AXI_READ_ID = 0,
		parameter	[C_AXI_ID_WIDTH-1:0]	AXI_WRITE_ID = 0,
		parameter	[7:0]			ABORT_KEY  = 8'h6d,
		localparam	ADDRLSB= $clog2(C_AXI_DATA_WIDTH)-3,
		localparam	AXILLSB= $clog2(C_AXIL_DATA_WIDTH)-3,
		localparam	LGLENW= LGLEN-ADDRLSB
	) (
		input	wire	S_AXI_ACLK,
		input	wire	S_AXI_ARESETN,
		input	wire				S_AXIL_AWVALID,
		output	wire				S_AXIL_AWREADY,
		input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_AWADDR,
		input	wire 	[2:0]			S_AXIL_AWPROT,
		input	wire				S_AXIL_WVALID,
		output	wire				S_AXIL_WREADY,
		input	wire [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_WDATA,
		input	wire [C_AXIL_DATA_WIDTH/8-1:0]	S_AXIL_WSTRB,
		output	reg				S_AXIL_BVALID,
		input	wire				S_AXIL_BREADY,
		output	wire	[1:0]			S_AXIL_BRESP,
		input	wire				S_AXIL_ARVALID,
		output	wire				S_AXIL_ARREADY,
		input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_ARADDR,
		input	wire 	[2:0]			S_AXIL_ARPROT,
		output	reg				S_AXIL_RVALID,
		input	wire				S_AXIL_RREADY,
		output	reg [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_RDATA,
		output	wire	[1:0]			S_AXIL_RRESP,
		output	reg				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	reg	[C_AXI_ID_WIDTH-1:0]	M_AXI_AWID,
		output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR,
		output	reg	[2:0]			M_AXI_AWSIZE,
		output	reg	[1:0]			M_AXI_AWBURST,
		output	reg				M_AXI_AWLOCK,
		output	reg	[3:0]			M_AXI_AWCACHE,
		output	reg	[2:0]			M_AXI_AWPROT,
		output	reg	[3:0]			M_AXI_AWQOS,
		output	reg				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		output	reg	[C_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA,
		output	reg [C_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
		output	reg				M_AXI_WLAST,
		input	wire				M_AXI_BVALID,
		output	reg				M_AXI_BREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_BID,
		input	wire	[1:0]			M_AXI_BRESP,
		output	reg				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		output	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_ARID,
		output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR,
		output	wire	[2:0]			M_AXI_ARSIZE,
		output	wire	[1:0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire	[3:0]			M_AXI_ARCACHE,
		output	wire	[2:0]			M_AXI_ARPROT,
		output	wire	[3:0]			M_AXI_ARQOS,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_RID,
		input	wire	[C_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA,
		input	wire				M_AXI_RLAST,
		input	wire	[1:0]			M_AXI_RRESP,
		output	reg				o_int
	);
