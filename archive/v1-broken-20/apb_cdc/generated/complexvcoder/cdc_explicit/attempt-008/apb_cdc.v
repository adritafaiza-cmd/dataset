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

    wire                      src_to_dst_valid;
    wire                      src_to_dst_ready;
    wire [DATA_WIDTH-1:0]     src_to_dst_data;
    wire                      dst_to_src_valid;
    wire                      dst_to_src_ready;
    wire [DATA_WIDTH-1:0]     dst_to_src_data;

    apb_fifos #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .sel_i(src_psel_i),
        .enable_i(src_penable_i),
        .write_i(src_pwrite_i),
        .addr_i(src_paddr_i),
        .wdata_i(src_pwdata_i),
        .strb_i(src_pstrb_i),
        .prot_i(src_pprot_i),
        .ready_o(src_to_dst_ready),
        .rdata_o(src_to_dst_data),
        .slverr_o(src_to_dst_valid)
    );

    apb_fifos #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_to_src_fifo (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .sel_i(dst_to_src_valid),
        .enable_i(dst_to_src_ready),
        .write_i(dst_pwrite_o),
        .addr_i(dst_paddr_o),
        .wdata_i(dst_pwdata_o),
        .strb_i(dst_pstrb_o),
        .prot_i(dst_pprot_o),
        .ready_o(src_pready_o),
        .rdata_o(src_prdata_o),
        .slverr_o(src_pslverr_o)
    );

    assign dst_psel_o = src_to_dst_valid;
    assign dst_penable_o = src_to_dst_valid;
    assign dst_pwdata_o = src_to_dst_data;
    assign dst_paddr_o = src_paddr_i;
    assign dst_pstrb_o = src_pstrb_i;
    assign dst_pprot_o = src_pprot_i;

endmodule
