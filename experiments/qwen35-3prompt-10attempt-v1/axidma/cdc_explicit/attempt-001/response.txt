```verilog
module axidma #(
	parameter	C_AXI_ID_WIDTH = 1,
	parameter	C_AXI_ADDR_WIDTH = 32,
	parameter	C_AXI_DATA_WIDTH = 32,
	localparam	C_AXIL_ADDR_WIDTH = 5,
	localparam	C_AXIL_DATA_WIDTH = 32,
	parameter [0:0]	OPT_UNALIGNED = 1'b1,
	parameter [0:0]	OPT_WRAPMEM = 1'b1,
	parameter	LGFIFO = 8,
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

// ============================================================================
// Internal Parameters and Constants
// ============================================================================
localparam C_AXI_ADDR_WIDTH_INT = C_AXI_ADDR_WIDTH;
localparam C_AXI_DATA_WIDTH_INT = C_AXI_DATA_WIDTH;
localparam C_AXI_ID_WIDTH_INT   = C_AXI_ID_WIDTH;
localparam C_AXIL_ADDR_WIDTH_INT = C_AXIL_ADDR_WIDTH;
localparam C_AXIL_DATA_WIDTH_INT = C_AXIL_DATA_WIDTH;

localparam LG_FIFO = LGFIFO;
localparam LG_LEN  = LGLEN;

localparam ADDRLSB_INT = ADDRLSB;
localparam AXILLSB_INT = AXILLSB;
localparam LGLENW_INT  = LGLENW;

localparam MAX_BURST_LEN = (1 << LG_FIFO) - 1;

// State Machine States
localparam STATE_IDLE = 2'b00;
localparam STATE_CONFIG = 2'b01;
localparam STATE_READ = 2'b10;
localparam STATE_WRITE = 2'b11;
localparam STATE_ABORT = 2'b100;

// ============================================================================
// Internal Signals
// ============================================================================
reg [1:0] state;
reg [LG_FIFO-1:0] read_fifo_addr;
reg [LG_FIFO-1:0] write_fifo_addr;
reg [LG_FIFO-1:0] read_fifo_count;
reg [LG_FIFO-1:0] write_fifo_count;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_addr_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_addr_reg;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb;
reg [LG_LEN-1:0] read_fifo_len;
reg [LG_LEN-1:0] write_fifo_len;
reg [LG_LEN-1:0] read_fifo_offset;
reg [LG_LEN-1:0] write_fifo_offset;
reg [LG_LEN-1:0] read_fifo_remaining;
reg [LG_LEN-1:0] write_fifo_remaining;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in;
reg [LG_LEN-1:0] read_fifo_len_in;
reg [LG_LEN-1:0] write_fifo_len_in;
reg [LG_LEN-1:0] read_fifo_offset_in;
reg [LG_LEN-1:0] write_fifo_offset_in;
reg [LG_LEN-1:0] read_fifo_remaining_in;
reg [LG_LEN-1:0] write_fifo_remaining_in;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_reg;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_reg;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_reg;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_reg;
reg [LG_LEN-1:0] read_fifo_len_reg;
reg [LG_LEN-1:0] write_fifo_len_reg;
reg [LG_LEN-1:0] read_fifo_offset_reg;
reg [LG_LEN-1:0] write_fifo_offset_reg;
reg [LG_LEN-1:0] read_fifo_remaining_reg;
reg [LG_LEN-1:0] write_fifo_remaining_reg;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_reg;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_reg;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out;
reg [LG_LEN-1:0] read_fifo_len_out;
reg [LG_LEN-1:0] write_fifo_len_out;
reg [LG_LEN-1:0] read_fifo_offset_out;
reg [LG_LEN-1:0] write_fifo_offset_out;
reg [LG_LEN-1:0] read_fifo_remaining_out;
reg [LG_LEN-1:0] write_fifo_remaining_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_reg;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_reg;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_reg;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_reg;
reg [LG_LEN-1:0] read_fifo_len_in_reg;
reg [LG_LEN-1:0] write_fifo_len_in_reg;
reg [LG_LEN-1:0] read_fifo_offset_in_reg;
reg [LG_LEN-1:0] write_fifo_offset_in_reg;
reg [LG_LEN-1:0] read_fifo_remaining_in_reg;
reg [LG_LEN-1:0] write_fifo_remaining_in_reg;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_reg;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_reg;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_reg;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_reg;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_reg;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_reg;
reg [LG_LEN-1:0] read_fifo_len_out_reg;
reg [LG_LEN-1:0] write_fifo_len_out_reg;
reg [LG_LEN-1:0] read_fifo_offset_out_reg;
reg [LG_LEN-1:0] write_fifo_offset_out_reg;
reg [LG_LEN-1:0] read_fifo_remaining_out_reg;
reg [LG_LEN-1:0] write_fifo_remaining_out_reg;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_reg;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out_reg;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out_reg;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_out;
reg [LG_LEN-1:0] read_fifo_len_in_out;
reg [LG_LEN-1:0] write_fifo_len_in_out;
reg [LG_LEN-1:0] read_fifo_offset_in_out;
reg [LG_LEN-1:0] write_fifo_offset_in_out;
reg [LG_LEN-1:0] read_fifo_remaining_in_out;
reg [LG_LEN-1:0] write_fifo_remaining_in_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_out;
reg [LG_LEN-1:0] read_fifo_len_out_out;
reg [LG_LEN-1:0] write_fifo_len_out_out;
reg [LG_LEN-1:0] read_fifo_offset_out_out;
reg [LG_LEN-1:0] write_fifo_offset_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_out_out;
reg [LG_LEN-1:0] read_fifo_len_in_out_out;
reg [LG_LEN-1:0] write_fifo_len_in_out_out;
reg [LG_LEN-1:0] read_fifo_offset_in_out_out;
reg [LG_LEN-1:0] write_fifo_offset_in_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_in_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_in_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_in_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_in_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_in_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_in_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_in_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_in_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_in_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_in_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_in_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_in_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_in_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_in_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_in_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_in_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_in_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_in_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_in_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_in_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_in_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_in_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_in_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_in_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_in_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_in_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_out_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_in_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_in_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_in_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_in_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_in_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_in_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_in_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_in_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_in_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_in_out_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_in_out_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_in_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_in_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_in_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_in_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_dst_addr_in_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] read_fifo_data_out_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT-1:0] write_fifo_data_out_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] read_fifo_strb_out_out_out_out_out_out_out_out;
reg [C_AXI_DATA_WIDTH_INT/8-1:0] write_fifo_strb_out_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_len_out_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_len_out_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_offset_out_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_offset_out_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] read_fifo_remaining_out_out_out_out_out_out_out_out;
reg [LG_LEN-1:0] write_fifo_remaining_out_out_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] read_fifo_id_out_out_out_out_out_out_out_out;
reg [C_AXI_ID_WIDTH_INT-1:0] write_fifo_id_out_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_src_addr_out_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] read_fifo_dst_addr_out_out_out_out_out_out_out_out;
reg [C_AXI_ADDR_WIDTH_INT-1:0] write_fifo_src_addr_out