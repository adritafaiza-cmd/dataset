```verilog
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    localparam INT_DEPTH = 1 << LOG_DEPTH;

    // Source Side Signals (Clock Domain: src_pclk_i)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Destination Side Signals (Clock Domain: dst_pclk_i)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Clock Domain: dst_pclk_i -> src_pclk_i)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Internal State Registers (Source Domain)
    reg [LOG_DEPTH-1:0] src_fifo_full;
    reg [LOG_DEPTH-1:0] src_fifo_empty;
    reg [LOG_DEPTH-1:0] src_fifo_count;
    reg [LOG_DEPTH-1:0] src_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_fifo_tail;
    reg [LOG_DEPTH-1:0] src_fifo_data;
    reg [LOG_DEPTH-1:0] src_fifo_strb;
    reg [LOG_DEPTH-1:0] src_fifo_prot;
    reg [LOG_DEPTH-1:0] src_fifo_addr;
    reg [LOG_DEPTH-1:0] src_fifo_write;
    reg [LOG_DEPTH-1:0] src_fifo_sel;
    reg [LOG_DEPTH-1:0] src_fifo_enable;
    reg [LOG_DEPTH-1:0] src_fifo_err;

    // Internal State Registers (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_fifo_full;
    reg [LOG_DEPTH-1:0] dst_fifo_empty;
    reg [LOG_DEPTH-1:0] dst_fifo_count;
    reg [LOG_DEPTH-1:0] dst_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_fifo_tail;
    reg [LOG_DEPTH-1:0] dst_fifo_data;
    reg [LOG_DEPTH-1:0] dst_fifo_strb;
    reg [LOG_DEPTH-1:0] dst_fifo_prot;
    reg [LOG_DEPTH-1:0] dst_fifo_addr;
    reg [LOG_DEPTH-1:0] dst_fifo_write;
    reg [LOG_DEPTH-1:0] dst_fifo_sel;
    reg [LOG_DEPTH-1:0] dst_fifo_enable;
    reg [LOG_DEPTH-1:0] dst_fifo_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready;
    reg [LOG_DEPTH-1:0] dst_req_data;
    reg [LOG_DEPTH-1:0] dst_req_strb;
    reg [LOG_DEPTH-1:0] dst_req_prot;
    reg [LOG_DEPTH-1:0] dst_req_addr;
    reg [LOG_DEPTH-1:0] dst_req_write;
    reg [LOG_DEPTH-1:0] dst_req_sel;
    reg [LOG_DEPTH-1:0] dst_req_enable;
    reg [LOG_DEPTH-1:0] dst_req_err;

    // Response FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_resp_valid;
    reg [LOG_DEPTH-1:0] src_resp_ready;
    reg [LOG_DEPTH-1:0] src_resp_data;
    reg [LOG_DEPTH-1:0] src_resp_strb;
    reg [LOG_DEPTH-1:0] src_resp_prot;
    reg [LOG_DEPTH-1:0] src_resp_addr;
    reg [LOG_DEPTH-1:0] src_resp_write;
    reg [LOG_DEPTH-1:0] src_resp_sel;
    reg [LOG_DEPTH-1:0] src_resp_enable;
    reg [LOG_DEPTH-1:0] src_resp_err;

    // Response FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_resp_valid;
    reg [LOG_DEPTH-1:0] dst_resp_ready;
    reg [LOG_DEPTH-1:0] dst_resp_data;
    reg [LOG_DEPTH-1:0] dst_resp_strb;
    reg [LOG_DEPTH-1:0] dst_resp_prot;
    reg [LOG_DEPTH-1:0] dst_resp_addr;
    reg [LOG_DEPTH-1:0] dst_resp_write;
    reg [LOG_DEPTH-1:0] dst_resp_sel;
    reg [LOG_DEPTH-1:0] dst_resp_enable;
    reg [LOG_DEPTH-1:0] dst_resp_err;

    // Request FIFO (Source Domain)
    reg [LOG_DEPTH-1:0] src_req_valid;
    reg [LOG_DEPTH-1:0] src_req_ready;
    reg [LOG_DEPTH-1:0] src_req_data;
    reg [LOG_DEPTH-1:0] src_req_strb;
    reg [LOG_DEPTH-1:0] src_req_prot;
    reg [LOG_DEPTH-1:0] src_req_addr;
    reg [LOG_DEPTH-1:0] src_req_write;
    reg [LOG_DEPTH-1:0] src_req_sel;
    reg [LOG_DEPTH-1:0] src_req_enable;
    reg [LOG_DEPTH-1:0] src_req_err;

    // Request FIFO (Destination Domain)
    reg [LOG_DEPTH-1:0] dst_req_valid;
    reg [LOG_DEPTH-1:0] dst_req_ready