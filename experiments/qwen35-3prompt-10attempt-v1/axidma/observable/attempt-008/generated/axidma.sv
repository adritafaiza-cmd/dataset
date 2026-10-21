```verilog
module axidma #(
    parameter C_AXI_ID_WIDTH = 1,
    parameter C_AXI_ADDR_WIDTH = 32,
    parameter C_AXI_DATA_WIDTH = 32,
    localparam C_AXIL_ADDR_WIDTH = 5,
    localparam C_AXIL_DATA_WIDTH = 32,
    parameter [0:0] OPT_UNALIGNED = 1'b1,
    parameter [0:0] OPT_WRAPMEM = 1'b1,
    parameter LGFIFO = 8,
    parameter LGLEN = C_AXI_ADDR_WIDTH,
    parameter [0:0] OPT_LOWPOWER = 1'b0,
    parameter [0:0] OPT_CLKGATE = OPT_LOWPOWER,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_READ_ID = 0,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_WRITE_ID = 0,
    parameter [7:0] ABORT_KEY = 8'h6d,
    localparam ADDRLSB = $clog2(C_AXI_DATA_WIDTH)-3,
    localparam AXILLSB = $clog2(C_AXIL_DATA_WIDTH)-3,
    localparam LGLENW = LGLEN-ADDRLSB
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    input wire S_AXIL_AWVALID,
    output wire S_AXIL_AWREADY,
    input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
    input wire [2:0] S_AXIL_AWPROT,
    input wire S_AXIL_WVALID,
    output wire S_AXIL_WREADY,
    input wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
    input wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,
    output reg S_AXIL_BVALID,
    input wire S_AXIL_BREADY,
    output wire [1:0] S_AXIL_BRESP,
    input wire S_AXIL_ARVALID,
    output wire S_AXIL_ARREADY,
    input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
    input wire [2:0] S_AXIL_ARPROT,
    output reg S_AXIL_RVALID,
    input wire S_AXIL_RREADY,
    output reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
    output wire [1:0] S_AXIL_RRESP,
    output reg M_AXI_AWVALID,
    input wire M_AXI_AWREADY,
    output reg [C_AXI_ID_WIDTH-1:0] M_AXI_AWID,
    output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
    output reg [2:0] M_AXI_AWSIZE,
    output reg [1:0] M_AXI_AWBURST,
    output reg M_AXI_AWLOCK,
    output reg [3:0] M_AXI_AWCACHE,
    output reg [2:0] M_AXI_AWPROT,
    output reg [3:0] M_AXI_AWQOS,
    output reg M_AXI_WVALID,
    input wire M_AXI_WREADY,
    output reg [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
    output reg [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output reg M_AXI_WLAST,
    input wire M_AXI_BVALID,
    output reg M_AXI_BREADY,
    input wire [C_AXI_ID_WIDTH-1:0] M_AXI_BID,
    input wire [1:0] M_AXI_BRESP,
    output reg M_AXI_ARVALID,
    input wire M_AXI_ARREADY,
    output wire [C_AXI_ID_WIDTH-1:0] M_AXI_ARID,
    output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output wire [2:0] M_AXI_ARSIZE,
    output wire [1:0] M_AXI_ARBURST,
    output wire M_AXI_ARLOCK,
    output wire [3:0] M_AXI_ARCACHE,
    output wire [2:0] M_AXI_ARPROT,
    output wire [3:0] M_AXI_ARQOS,
    input wire M_AXI_RVALID,
    output wire M_AXI_RREADY,
    input wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
    input wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
    input wire M_AXI_RLAST,
    input wire [1:0] M_AXI_RRESP,
    output reg o_int
);

    localparam LGMAXBURST = LGFIFO-1;
    localparam LGLENW = LGLEN-ADDRLSB;

    // State Machine
    typedef enum logic [1:0] {
        IDLE,
        AW_WAIT_B,
        AR_WAIT_R,
        WAIT_INT
    } state_t;

    state_t state, next_state;
    logic [2:0] ctrl_state; // 0: Idle, 1: AW, 2: AR
    logic [31:0] src_addr, dst_addr;
    logic [31:0] src_stride, dst_stride;
    logic [31:0] src_count, dst_count;
    logic [31:0] src_offset, dst_offset;
    logic [31:0] src_ptr, dst_ptr;
    logic [31:0] src_stride_reg, dst_stride_reg;
    logic [31:0] src_count_reg, dst_count_reg;
    logic [31:0] src_offset_reg, dst_offset_reg;
    logic [31:0] src_ptr_reg, dst_ptr_reg;
    logic [31:0] src_stride_tmp, dst_stride_tmp;
    logic [31:0] src_count_tmp, dst_count_tmp;
    logic [31:0] src_offset_tmp, dst_offset_tmp;
    logic [31:0] src_ptr_tmp, dst_ptr_tmp;
    logic [31:0] src_stride_reg_tmp, dst_stride_reg_tmp;
    logic [31:0] src_count_reg_tmp, dst_count_reg_tmp;
    logic [31:0] src_offset_reg_tmp, dst_offset_reg_tmp;
    logic [31:0] src_ptr_reg_tmp, dst_ptr_reg_tmp;
    logic [31:0] src_stride_tmp_reg, dst_stride_tmp_reg;
    logic [31:0] src_count_tmp_reg, dst_count_tmp_reg;
    logic [31:0] src_offset_tmp_reg, dst_offset_tmp_reg;
    logic [31:0] src_ptr_tmp_reg, dst_ptr_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg, dst_stride_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg, dst_count_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg, dst_offset_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg, dst_ptr_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp, dst_stride_tmp_reg_tmp;
    logic [31:0] src_count_tmp_reg_tmp, dst_count_tmp_reg_tmp;
    logic [31:0] src_offset_tmp_reg_tmp, dst_offset_tmp_reg_tmp;
    logic [31:0] src_ptr_tmp_reg_tmp, dst_ptr_tmp_reg_tmp;
    logic [31:0] src_stride_reg_tmp_reg_tmp, dst_stride_reg_tmp_reg_tmp;
    logic [31:0] src_count_reg_tmp_reg_tmp, dst_count_reg_tmp_reg_tmp;
    logic [31:0] src_offset_reg_tmp_reg_tmp, dst_offset_reg_tmp_reg_tmp;
    logic [31:0] src_ptr_reg_tmp_reg_tmp, dst_ptr_reg_tmp_reg_tmp;
    logic [31:0] src_stride_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_tmp_reg_tmp_reg, dst_ptr_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp, dst_stride_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp, dst_count_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp, dst_offset_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_ptr_tmp_reg_tmp_reg_tmp, dst_ptr_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp, dst_stride_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp, dst_count_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp, dst_offset_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp, dst_ptr_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp, dst_ptr_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_ptr_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_stride_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_count_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg;
    logic [31:0] src_offset_tmp_reg_tmp_reg_tmp_reg_tmp_reg_tmp_reg, dst_offset_tmp_reg_tmp_reg_tmp