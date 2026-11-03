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
    reg                      src_pready_out;
    reg  [DATA_WIDTH-1:0]    src_prdata_out;
    reg                      src_pslverr_out;
    reg                      dst_psel_out;
    reg                      dst_penable_out;
    reg                      dst_pwrite_out;
    reg  [ADDR_WIDTH-1:0]    dst_paddr_out;
    reg  [DATA_WIDTH-1:0]    dst_pwdata_out;
    reg  [DATA_WIDTH/8-1:0]  dst_pstrb_out;
    reg  [2:0]               dst_pprot_out;

    // Instantiate APB slave interface
    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_slave (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .psel_i(src_psel_i),
        .penable_i(src_penable_i),
        .pwrite_i(src_pwrite_i),
        .paddr_i(src_paddr_i),
        .pwdata_i(src_pwdata_i),
        .pstrb_i(src_pstrb_i),
        .pprot_i(src_pprot_i),
        .pready_o(src_pready_out),
        .prdata_o(src_prdata_out),
        .pslverr_o(src_pslverr_out)
    );

    // Instantiate APB master interface
    apb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_master (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .psel_o(dst_psel_out),
        .penable_o(dst_penable_out),
        .pwrite_o(dst_pwrite_out),
        .paddr_o(dst_paddr_out),
        .pwdata_o(dst_pwdata_out),
        .pstrb_o(dst_pstrb_out),
        .pprot_o(dst_pprot_out),
        .pready_i(dst_pready_i),
        .prdata_i(dst_prdata_i),
        .pslverr_i(dst_pslverr_i)
    );

    // Instantiate clock-domain crossing bridge
    cdc_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) bridge (
        .src_pready_i(src_pready_out),
        .src_prdata_i(src_prdata_out),
        .src_pslverr_i(src_pslverr_out),
        .dst_pready_o(dst_pready_out),
        .dst_prdata_o(dst_prdata_out),
        .dst_pslverr_o(dst_pslverr_out)
    );

    // Output connections
    assign src_pready_o = src_pready_out;
    assign src_prdata_o = src_prdata_out;
    assign src_pslverr_o = src_pslverr_out;
    assign dst_psel_o = dst_psel_out;
    assign dst_penable_o = dst_penable_out;
    assign dst_pwrite_o = dst_pwrite_out;
    assign dst_paddr_o = dst_paddr_out;
    assign dst_pwdata_o = dst_pwdata_out;
    assign dst_pstrb_o = dst_pstrb_out;
    assign dst_pprot_o = dst_pprot_out;

endmodule
