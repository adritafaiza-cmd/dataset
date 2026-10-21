```verilog
module axidma #(
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

	localparam LGMAXBURST = LGFIFO-1;
	localparam LGLENW_VAL = LGLENW;
	localparam LGLENW_LOG = $clog2(LGLENW_VAL);

	// State Machine
	localparam STATE_IDLE = 2'b00;
	localparam STATE_CONFIG = 2'b01;
	localparam STATE_READ = 2'b10;
	localparam STATE_WRITE = 2'b11;
	localparam STATE_ABORT = 2'b100;

	reg [1:0] state;
	reg [LGLENW_VAL-1:0] src_addr;
	reg [LGLENW_VAL-1:0] dst_addr;
	reg [31:0] length;
	reg [31:0] count;
	reg [1:0] burst_type; // 0: FIXED, 1: INCR
	reg [2:0] burst_len;
	reg [LGMAXBURST-1:0] fifo_ptr;
	reg [LGMAXBURST-1:0] fifo_tail;
	reg [C_AXI_DATA_WIDTH/8-1:0] fifo_wstrb;
	reg [C_AXI_DATA_WIDTH-1:0] fifo_wdata;
	reg [C_AXI_DATA_WIDTH-1:0] fifo_rdata;
	reg [LGMAXBURST-1:0] fifo_rptr;
	reg [1:0] fifo_state; // 0: empty, 1: full, 2: half
	reg [31:0] abort_key_reg;
	reg [31:0] last_addr;
	reg [31:0] last_data;
	reg [1:0] last_resp;
	reg [C_AXI_DATA_WIDTH-1:0] last_rdata;
	reg [C_AXI_DATA_WIDTH/8-1:0] last_rstrb;
	reg [1:0] last_rlast;
	reg [1:0] last_rburst;
	reg [2:0] last_rsize;
	reg [1:0] last_rlock;
	reg [3:0] last_rcache;
	reg [2:0] last_rprot;
	reg [3:0] last_rqos;
	reg [C_AXI_ID_WIDTH-1:0] last_rid;
	reg [1:0] last_rresp;

	// AXI Lite Registers
	reg [31:0] cfg_src_addr;
	reg [31:0] cfg_dst_addr;
	reg [31:0] cfg_len;
	reg [31:0] cfg_ctrl;
	reg [31:0] cfg_status;

	// Internal Signals
	wire cfg_valid;
	wire cfg_ready;
	wire cfg_done;
	wire cfg_abort;
	wire cfg_start;
	wire cfg_stop;
	wire cfg_clear;
	wire cfg_set;
	wire cfg_read;
	wire cfg_write;
	wire cfg_inc;
	wire cfg_dec;
	wire cfg_inc_addr;
	wire cfg_dec_addr;
	wire cfg_inc_data;
	wire cfg_dec_data;
	wire cfg_inc_ptr;
	wire cfg_dec_ptr;
	wire cfg_inc_tail;
	wire cfg_dec_tail;
	wire cfg_inc_rptr;
	wire cfg_dec_rptr;
	wire cfg_inc_rdata;
	wire cfg_dec_rdata;
	wire cfg_inc_rstrb;
	wire cfg_dec_rstrb;
	wire cfg_inc_rlast;
	wire cfg_dec_rlast;
	wire cfg_inc_rburst;
	wire cfg_dec_rburst;
	wire cfg_inc_rsize;
	wire cfg_dec_rsize;
	wire cfg_inc_rlock;
	wire cfg_dec_rlock;
	wire cfg_inc_rcache;
	wire cfg_dec_rcache;
	wire cfg_inc_rprot;
	wire cfg_dec_rprot;
	wire cfg_inc_rqos;
	wire cfg_dec_rqos;
	wire cfg_inc_rid;
	wire cfg_dec_rid;
	wire cfg_inc_rresp;
	wire cfg_dec_rresp;
	wire cfg_inc_last;
	wire cfg_dec_last;
	wire cfg_inc_addr_reg;
	wire cfg_dec_addr_reg;
	wire cfg_inc_data_reg;
	wire cfg_dec_data_reg;
	wire cfg_inc_ptr_reg;
	wire cfg_dec_ptr_reg;
	wire cfg_inc_tail_reg;
	wire cfg_dec_tail_reg;
	wire cfg_inc_rptr_reg;
	wire cfg_dec_rptr_reg;
	wire cfg_inc_rdata_reg;
	wire cfg_dec_rdata_reg;
	wire cfg_inc_rstrb_reg;
	wire cfg_dec_rstrb_reg;
	wire cfg_inc_rlast_reg;
	wire cfg_dec_rlast_reg;
	wire cfg_inc_rburst_reg;
	wire cfg_dec_rburst_reg;
	wire cfg_inc_rsize_reg;
	wire cfg_dec_rsize_reg;
	wire cfg_inc_rlock_reg;
	wire cfg_dec_rlock_reg;
	wire cfg_inc_rcache_reg;
	wire cfg_dec_rcache_reg;
	wire cfg_inc_rprot_reg;
	wire cfg_dec_rprot_reg;
	wire cfg_inc_rqos_reg;
	wire cfg_dec_rqos_reg;
	wire cfg_inc_rid_reg;
	wire cfg_dec_rid_reg;
	wire cfg_inc_rresp_reg;
	wire cfg_dec_rresp_reg;
	wire cfg_inc_last_reg;
	wire cfg_dec_last_reg;
	wire cfg_inc_addr_reg_reg;
	wire cfg_dec_addr_reg_reg;
	wire cfg_inc_data_reg_reg;
	wire cfg_dec_data_reg_reg;
	wire cfg_inc_ptr_reg_reg;
	wire cfg_dec_ptr_reg_reg;
	wire cfg_inc_tail_reg_reg;
	wire cfg_dec_tail_reg_reg;
	wire cfg_inc_rptr_reg_reg;
	wire cfg_dec_rptr_reg_reg;
	wire cfg_inc_rdata_reg_reg;
	wire cfg_dec_rdata_reg_reg;
	wire cfg_inc_rstrb_reg_reg;
	wire cfg_dec_rstrb_reg_reg;
	wire cfg_inc_rlast_reg_reg;
	wire cfg_dec_rlast_reg_reg;
	wire cfg_inc_rburst_reg_reg;
	wire cfg_dec_rburst_reg_reg;
	wire cfg_inc_rsize_reg_reg;
	wire cfg_dec_rsize_reg_reg;
	wire cfg_inc_rlock_reg_reg;
	wire cfg_dec_rlock_reg_reg;
	wire cfg_inc_rcache_reg_reg;
	wire cfg_dec_rcache_reg_reg;
	wire cfg_inc_rprot_reg_reg;
	wire cfg_dec_rprot_reg_reg;
	wire cfg_inc_rqos_reg_reg;
	wire cfg_dec_rqos_reg_reg;
	wire cfg_inc_rid_reg_reg;
	wire cfg_dec_rid_reg_reg;
	wire cfg_inc_rresp_reg_reg;
	wire cfg_dec_rresp_reg_reg;
	wire cfg_inc_last_reg_reg;
	wire cfg_dec_last_reg_reg;
	wire cfg_inc_addr_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rburst_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rsize_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rlock_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rcache_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rprot_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rqos_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rresp_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_last_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_last_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_ptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_tail_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rptr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_inc_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	wire cfg_dec_rstrb_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
