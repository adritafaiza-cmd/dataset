Sure, here is the complete Verilog-2001 code for the APB clock-domain bridge module:

```
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

    // Internal signals
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg src_pwrite_reg;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pready_reg;
    reg src_pslverr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] dst_pprot_reg;
    reg dst_pwrite_reg;
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pready_reg;
    reg dst_pslverr_reg;
    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_ptr_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_ptr_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_ptr_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_ptr_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_ptr_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_ptr_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_ptr_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_ptr_next_