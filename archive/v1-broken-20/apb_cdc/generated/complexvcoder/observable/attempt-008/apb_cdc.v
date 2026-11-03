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
    reg                      src_pready_r;
    reg [DATA_WIDTH-1:0]       src_prdata_r;
    reg                      src_pslverr_r;
    wire                     dst_pready_r;
    wire [DATA_WIDTH-1:0]      dst_prdata_r;
    wire                     dst_pslverr_r;

    // APB master bridge
    apb_master_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) src_bridge (
        .clk_i(src_pclk_i),
        .reset_ni(src_preset_ni),
        .psel_i(src_psel_i),
        .penable_i(src_penable_i),
        .pwrite_i(src_pwrite_i),
        .paddr_i(src_paddr_i),
        .pwdata_i(src_pwdata_i),
        .pstrb_i(src_pstrb_i),
        .pprot_i(src_pprot_i),
        .pready_o(src_pready_r),
        .prdata_o(src_prdata_r),
        .pslverr_o(src_pslverr_r),
        .pready_i(dst_pready_i),
        .prdata_i(dst_prdata_i),
        .pslverr_i(dst_pslverr_i)
    );

    // APB slave bridge
    apb_slave_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dst_bridge (
        .clk_i(dst_pclk_i),
        .reset_ni(dst_preset_ni),
        .psel_o(dst_psel_o),
        .penable_o(dst_penable_o),
        .pwrite_o(dst_pwrite_o),
        .paddr_o(dst_paddr_o),
        .pwdata_o(dst_pwdata_o),
        .pstrb_o(dst_pstrb_o),
        .pprot_o(dst_pprot_o),
        .pready_i(src_pready_r),
        .prdata_i(src_prdata_r),
        .pslverr_i(src_pslverr_r)
    );

    // Output the internal signals to the interface
    assign src_pready_o = src_pready_r;
    assign src_prdata_o = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;

endmodule
