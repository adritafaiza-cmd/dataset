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

	localparam LGMAXBURST = 4; // Assumed for LGFIFO calculation context
	localparam MAXBURST = 1 << LGMAXBURST;
	localparam FIFO_DEPTH = 1 << LGFIFO;

	// Internal State Machine
	localparam IDLE = 0;
	localparam CONFIG = 1;
	localparam WRITE_IDLE = 2;
	localparam WRITE_BURST = 3;
	localparam WRITE_DONE = 4;
	localparam READ_IDLE = 5;
	localparam READ_BURST = 6;
	localparam READ_DONE = 7;
	localparam ABORT = 8;

	// State Registers
	reg [2:0] state;
	reg [31:0] src_addr;
	reg [31:0] dst_addr;
	reg [31:0] len;
	reg [31:0] remaining_len;
	reg [31:0] current_addr;
	reg [31:0] current_dst;
	reg [31:0] burst_count;
	reg [31:0] burst_len;
	reg [31:0] burst_size;
	reg [31:0] burst_stride;
	reg [31:0] burst_mask;
	reg [31:0] burst_offset;
	reg [31:0] write_fifo_ptr;
	reg [31:0] read_fifo_ptr;
	reg [31:0] write_fifo_data;
	reg [31:0] read_fifo_data;
	reg [31:0] write_fifo_strb;
	reg [31:0] read_fifo_strb;
	reg [31:0] write_fifo_valid;
	reg [31:0] read_fifo_valid;
	reg [31:0] write_fifo_full;
	reg [31:0] read_fifo_empty;
	reg [31:0] write_fifo_count;
	reg [31:0] read_fifo_count;
	reg [31:0] write_fifo_ready;
	reg [31:0] read_fifo_ready;
	reg [31:0] write_fifo_push;
	reg [31:0] read_fifo_pop;
	reg [31:0] write_fifo_data_in;
	reg [31:0] read_fifo_data_in;
	reg [31:0] write_fifo_strb_in;
	reg [31:0] read_fifo_strb_in;
	reg [31:0] write_fifo_valid_in;
	reg [31:0] read_fifo_valid_in;
	reg [31:0] write_fifo_full_in;
	reg [31:0] read_fifo_empty_in;
	reg [31:0] write_fifo_count_in;
	reg [31:0] read_fifo_count_in;
	reg [31:0] write_fifo_ready_in;
	reg [31:0] read_fifo_ready_in;
	reg [31:0] write_fifo_push_in;
	reg [31:0] read_fifo_pop_in;
	reg [31:0] write_fifo_data_in_reg;
	reg [31:0] read_fifo_data_in_reg;
	reg [31:0] write_fifo_strb_in_reg;
	reg [31:0] read_fifo_strb_in_reg;
	reg [31:0] write_fifo_valid_in_reg;
	reg [31:0] read_fifo_valid_in_reg;
	reg [31:0] write_fifo_full_in_reg;
	reg [31:0] read_fifo_empty_in_reg;
	reg [31:0] write_fifo_count_in_reg;
	reg [31:0] read_fifo_count_in_reg;
	reg [31:0] write_fifo_ready_in_reg;
	reg [31:0] read_fifo_ready_in_reg;
	reg [31:0] write_fifo_push_in_reg;
	reg [31:0] read_fifo_pop_in_reg;
	reg [31:0] write_fifo_data_in_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_full_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_empty_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_count_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_ready_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_push_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_pop_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_strb_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] write_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0] read_fifo_valid_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
	reg [31:0]