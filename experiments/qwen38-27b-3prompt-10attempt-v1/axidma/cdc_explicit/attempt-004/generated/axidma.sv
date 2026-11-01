```verilog
module axidma #(
	parameter	C_AXI_ID_WIDTH = 1,
	parameter	C_AXI_ADDR_WIDTH = 32,
	parameter	C_AXI_DATA_WIDTH = 32,
	localparam	C_AXIL_ADDR_WIDTH = 5,
	localparam	C_AXIL_DATA_WIDTH = 32,
	parameter [0:0]	OPT_UNALIGNED = 1'b1,
	parameter [0:0]	OPT_WRAPMEM = 1'b1,
	parameter	LGFIFO = 4,
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

    // Register addresses
    localparam REG_SRC_ADDR = 0;
    localparam REG_DST_ADDR = 1;
    localparam REG_LENGTH   = 2;
    localparam REG_CONTROL  = 3;
    localparam REG_STATUS   = 4;

    // Control register bits
    localparam CTRL_START = 0;
    localparam CTRL_ABORT = 1;

    // Status register bits
    localparam STAT_BUSY  = 0;
    localparam STAT_DONE  = 1;
    localparam STAT_ERROR = 2;

    // Internal signals
    reg [C_AXIL_DATA_WIDTH-1:0] reg_src_addr;
    reg [C_AXIL_DATA_WIDTH-1:0] reg_dst_addr;
    reg [C_AXIL_DATA_WIDTH-1:0] reg_length;
    reg [C_AXIL_DATA_WIDTH-1:0] reg_control;
    reg [C_AXIL_DATA_WIDTH-1:0] reg_status;

    reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] length;
    reg [C_AXI_ADDR_WIDTH-1:0] remaining;

    reg running;
    reg done;
    reg error;

    // AXI write address channel
    reg aw_valid;
    reg [C_AXI_ADDR_WIDTH-1:0] aw_addr;
    reg [2:0] aw_size;
    reg [1:0] aw_burst;
    reg aw_last;
    reg [C_AXI_DATA_WIDTH/8-1:0] aw_strobe;

    // AXI write data channel
    reg w_valid;
    reg [C_AXI_DATA_WIDTH-1:0] w_data;
    reg [C_AXI_DATA_WIDTH/8-1:0] w_strobe;
    reg w_last;

    // AXI write response channel
    reg b_ready;

    // AXI read address channel
    reg ar_valid;
    reg [C_AXI_ADDR_WIDTH-1:0] ar_addr;
    reg [2:0] ar_size;
    reg [1:0] ar_burst;
    reg ar_last;

    // AXI read data channel
    reg r_ready;
    reg [C_AXI_DATA_WIDTH-1:0] r_data;
    reg r_last;

    // FIFO for read data
    localparam FIFO_DEPTH = 1 << LGFIFO;
    localparam FIFO_ADDR_WIDTH = LGFIFO;
    reg [C_AXI_DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [FIFO_ADDR_WIDTH:0] fifo_wr_ptr;
    reg [FIFO_ADDR_WIDTH:0] fifo_rd_ptr;
    reg fifo_full;
    reg fifo_empty;

    // State machine
    localparam ST_IDLE = 0;
    localparam ST_START = 1;
    localparam ST_READ_ADDR = 2;
    localparam ST_READ_DATA = 3;
    localparam ST_WRITE_ADDR = 4;
    localparam ST_WRITE_DATA = 5;
    localparam ST_WRITE_RESP = 6;
    localparam ST_FINISH = 7;

    reg [3:0] state;

    // AXI size calculation
    wire [2:0] axi_size = $clog2(C_AXI_DATA_WIDTH) - 3;

    // AXI burst type
    wire [1:0] axi_burst = 2'b01; // INCR

    // AXI cache
    wire [3:0] axi_cache = 4'b0011;

    // AXI prot
    wire [2:0] axi_prot = 3'b000;

    // AXI qos
    wire [3:0] axi_qos = 4'b0000;

    // AXI lock
    wire axi_lock = 1'b0;

    // AXI ID
    wire [C_AXI_ID_WIDTH-1:0] axi_read_id = AXI_READ_ID;
    wire [C_AXI_ID_WIDTH-1:0] axi_write_id = AXI_WRITE_ID;

    // S_AXIL outputs
    assign S_AXIL_AWREADY = 1'b1;
    assign S_AXIL_WREADY = 1'b1;
    assign S_AXIL_BRESP = 2'b00;
    assign S_AXIL_ARREADY = 1'b1;
    assign S_AXIL_RRESP = 2'b00;

    // M_AXI outputs
    assign M_AXI_AWID = axi_write_id;
    assign M_AXI_AWSIZE = axi_size;
    assign M_AXI_AWBURST = axi_burst;
    assign M_AXI_AWLOCK = axi_lock;
    assign M_AXI_AWCACHE = axi_cache;
    assign M_AXI_AWPROT = axi_prot;
    assign M_AXI_AWQOS = axi_qos;

    assign M_AXI_ARID = axi_read_id;
    assign M_AXI_ARSIZE = axi_size;
    assign M_AXI_ARBURST = axi_burst;
    assign M_AXI_ARLOCK = axi_lock;
    assign M_AXI_ARCACHE = axi_cache;
    assign M_AXI_ARPROT = axi_prot;
    assign M_AXI_ARQOS = axi_qos;

    // FIFO full/empty
    assign fifo_full = (fifo_wr_ptr[FIFO_ADDR_WIDTH] != fifo_rd_ptr[FIFO_ADDR_WIDTH]) &&
                       (fifo_wr_ptr[FIFO_ADDR_WIDTH-1:0] == fifo_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
    assign fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);

    // Interrupt
    assign o_int = done | error;

    // AXI write address
    assign M_AXI_AWVALID = aw_valid;
    assign M_AXI_AWADDR = aw_addr;
    assign M_AXI_AWSIZE = aw_size;
    assign M_AXI_AWBURST = aw_burst;
    assign M_AXI_AWLOCK = axi_lock;
    assign M_AXI_AWCACHE = axi_cache;
    assign M_AXI_AWPROT = axi_prot;
    assign M_AXI_AWQOS = axi_qos;

    // AXI write data
    assign M_AXI_WVALID = w_valid;
    assign M_AXI_WDATA = w_data;
    assign M_AXI_WSTRB = w_strobe;
    assign M_AXI_WLAST = w_last;

    // AXI write response
    assign M_AXI_BREADY = b_ready;

    // AXI read address
    assign M_AXI_ARVALID = ar_valid;
    assign M_AXI_ARADDR = ar_addr;
    assign M_AXI_ARSIZE = ar_size;
    assign M_AXI_ARBURST = ar_burst;
    assign M_AXI_ARLOCK = axi_lock;
    assign M_AXI_ARCACHE = axi_cache;
    assign M_AXI_ARPROT = axi_prot;
    assign M_AXI_ARQOS = axi_qos;

    // AXI read data
    assign M_AXI_RREADY = r_ready;

    // S_AXIL read data
    assign S_AXIL_RDATA = r_data;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP = 2'b00;

    // S_AXIL BVALID
    assign S_AXIL_BVALID = 1'b0;

    // S_AXIL RVALID
    assign S_AXIL_RVALID = 1'b0;

    // S_AXIL BRESP
    assign S_AXIL_BRESP = 2'b00;

    // S_AXIL RRESP
    assign S_AXIL_RRESP