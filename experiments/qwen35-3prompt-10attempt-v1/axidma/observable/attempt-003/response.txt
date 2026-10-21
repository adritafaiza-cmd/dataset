```verilog
module axidma #(
    parameter C_AXI_ID_WIDTH = 1,
    parameter C_AXI_ADDR_WIDTH = 32,
    parameter C_AXI_DATA_WIDTH = 32,
    localparam C_AXIL_ADDR_WIDTH = 5,
    localparam C_AXIL_DATA_WIDTH = 32,
    parameter [0:0] OPT_UNALIGNED = 1'b1,
    parameter [0:0] OPT_WRAPMEM = 1'b1,
    parameter LGFIFO = 8, // Assumed LGMAXBURST+1 based on typical designs, adjusted for logic
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

    // Internal Clocks and Resets
    reg S_AXI_ACLK_INT;
    wire S_AXI_ARESETN_INT;
    
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN)
            S_AXI_ACLK_INT <= 1'b0;
        else
            S_AXI_ACLK_INT <= S_AXI_ACLK;
    end

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN)
            S_AXI_ARESETN_INT <= 1'b1;
        else
            S_AXI_ARESETN_INT <= S_AXI_ARESETN;
    end

    // State Machine
    typedef enum logic [2:0] {
        IDLE,
        CONFIG,
        READ_REQ,
        READ_DATA,
        WRITE_REQ,
        WRITE_DATA,
        DONE
    } state_t;

    state_t current_state, next_state;

    // Control Registers
    reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
    reg [31:0] transfer_size;
    reg [31:0] bytes_remaining;
    reg [31:0] bytes_transferred;
    reg [2:0] burst_type;
    reg [2:0] burst_len;
    reg [2:0] data_width;
    reg [2:0] src_stride;
    reg [2:0] dst_stride;
    reg [1:0] src_burst;
    reg [1:0] dst_burst;
    reg [1:0] src_lock;
    reg [1:0] dst_lock;
    reg [1:0] src_cache;
    reg [1:0] dst_cache;
    reg [1:0] src_prot;
    reg [1:0] dst_prot;
    reg [1:0] src_qos;
    reg [1:0] dst_qos;
    reg [1:0] src_id;
    reg [1:0] dst_id;
    reg [1:0] src_resp;
    reg [1:0] dst_resp;
    reg [1:0] src_size;
    reg [1:0] dst_size;
    reg [1:0] src_burst_type;
    reg [1:0] dst_burst_type;
    reg [1:0] src_lock_type;
    reg [1:0] dst_lock_type;
    reg [1:0] src_cache_type;
    reg [1:0] dst_cache_type;
    reg [1:0] src_qos_type;
    reg [1:0] dst_qos_type;
    reg [1:0] src_prot_type;
    reg [1:0] dst_prot_type;
    reg [1:0] src_id_type;
    reg [1:0] dst_id_type;
    reg [1:0] src_resp_type;
    reg [1:0] dst_resp_type;
    reg [1:0] src_size_type;
    reg [1:0] dst_size_type;
    reg [1:0] src_burst_type_type;
    reg [1:0] dst_burst_type_type;
    reg [1:0] src_lock_type_type;
    reg [1:0] dst_lock_type_type;
    reg [1:0] src_cache_type_type;
    reg [1:0] dst_cache_type_type;
    reg [1:0] src_qos_type_type;
    reg [1:0] dst_qos_type_type;
    reg [1:0] src_prot_type_type;
    reg [1:0] dst_prot_type_type;
    reg [1:0] src_id_type_type;
    reg [1:0] dst_id_type_type;
    reg [1:0] src_resp_type_type;
    reg [1:0] dst_resp_type_type;
    reg [1:0] src_size_type_type;
    reg [1:0] dst_size_type_type;
    reg [1:0] src_burst_type_type_type;
    reg [1:0] dst_burst_type_type_type;
    reg [1:0] src_lock_type_type_type;
    reg [1:0] dst_lock_type_type_type;
    reg [1:0] src_cache_type_type_type;
    reg [1:0] dst_cache_type_type_type;
    reg [1:0] src_qos_type_type_type;
    reg [1:0] dst_qos_type_type_type;
    reg [1:0] src_prot_type_type_type;
    reg [1:0] dst_prot_type_type_type;
    reg [1:0] src_id_type_type_type;
    reg [1:0] dst_id_type_type_type;
    reg [1:0] src_resp_type_type_type;
    reg [1:0] dst_resp_type_type_type;
    reg [1:0] src_size_type_type_type;
    reg [1:0] dst_size_type_type_type;
    reg [1:0] src_burst_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type;
    reg [1:0] src_id_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type;
    reg [1:0] src_size_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_cache_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_qos_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_prot_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_id_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_resp_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_size_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] dst_burst_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;
    reg [1:0] src_lock_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type_type;