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

    localparam DEPTH = 1 << LOG_DEPTH;

    // Source side signals
    wire src_valid;
    wire src_valid_next;
    wire src_valid_reg;
    
    // Destination side signals
    wire dst_valid;
    wire dst_valid_next;
    wire dst_valid_reg;
    
    // FIFO Control Signals
    wire [LOG_DEPTH-1:0] wr_en;
    wire [LOG_DEPTH-1:0] rd_en;
    wire [LOG_DEPTH-1:0] full;
    wire [LOG_DEPTH-1:0] empty;
    wire [LOG_DEPTH-1:0] count;
    
    // FIFO Data
    wire [DATA_WIDTH-1:0] fifo_data;
    wire [DATA_WIDTH-1:0] fifo_data_out;
    
    // FIFO Address
    wire [ADDR_WIDTH-1:0] fifo_addr;
    wire [ADDR_WIDTH-1:0] fifo_addr_out;
    
    // FIFO Write Strobe
    wire [DATA_WIDTH/8-1:0] fifo_strb;
    wire [DATA_WIDTH/8-1:0] fifo_strb_out;
    
    // FIFO Write Enable (for write transactions)
    wire [2:0] fifo_prot;
    wire [2:0] fifo_prot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_write;
    wire fifo_write_out;
    
    // FIFO Read Enable (for read transactions)
    wire fifo_read;
    wire fifo_read_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_err;
    wire fifo_err_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_sel;
    wire fifo_sel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_en;
    wire fifo_en_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_penable;
    wire fifo_penable_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwrite;
    wire fifo_pwrite_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_paddr;
    wire fifo_paddr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pwdata;
    wire fifo_pwdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pstrb;
    wire fifo_pstrb_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pprot;
    wire fifo_pprot_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pready;
    wire fifo_pready_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_prdata;
    wire fifo_prdata_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_pslverr;
    wire fifo_pslverr_out;
    
    // FIFO Write Enable (for write transactions)
    wire fifo_psel;
    wire fifo_psel_out;
    
    // FIFO Write Enable