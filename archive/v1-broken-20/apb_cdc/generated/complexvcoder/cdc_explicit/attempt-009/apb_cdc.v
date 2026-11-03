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

    // Internal signals for AXI interface
    wire [ADDR_WIDTH-1:0] src_cdc_paddr;
    wire [DATA_WIDTH-1:0] src_cdc_pwdata;
    wire [DATA_WIDTH/8-1:0] src_cdc_pstrb;
    wire [2:0] src_cdc_pprot;
    wire src_cdc_psel;
    wire src_cdc_penable;
    wire src_cdc_pwrite;
    wire src_cdc_pready;
    wire [DATA_WIDTH-1:0] src_cdc_prdata;
    wire src_cdc_pslverr;

    wire dst_cdc_psel;
    wire dst_cdc_penable;
    wire dst_cdc_pwrite;
    wire [ADDR_WIDTH-1:0] dst_cdc_paddr;
    wire [DATA_WIDTH-1:0] dst_cdc_pwdata;
    wire [DATA_WIDTH/8-1:0] dst_cdc_pstrb;
    wire [2:0] dst_cdc_pprot;
    wire dst_cdc_pready;
    wire [DATA_WIDTH-1:0] dst_cdc_prdata;
    wire dst_cdc_pslverr;

    // AXI to APB bridge
    apb_cdc_src #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_cdc (
        .src_clk(src_pclk_i),
        .src_reset_n(src_preset_ni),
        .src_psel(src_cdc_psel),
        .src_penable(src_cdc_penable),
        .src_pwrite(src_cdc_pwrite),
        .src_paddr(src_cdc_paddr),
        .src_pwdata(src_cdc_pwdata),
        .src_pstrb(src_cdc_pstrb),
        .src_pprot(src_cdc_pprot),
        .src_pready(src_cdc_pready),
        .src_prdata(src_cdc_prdata),
        .src_pslverr(src_cdc_pslverr),
        .dst_clk(dst_pclk_i),
        .dst_reset_n(dst_preset_ni),
        .dst_ready(dst_pready_i),
        .dst_rdata(dst_prdata_i),
        .dst_serror(dst_pslverr_i)
    );

    // APB to AXI bridge
    apb_cdc_dst #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_cdc (
        .src_clk(src_pclk_i),
        .src_reset_n(src_preset_ni),
        .src_psel(dst_cdc_psel),
        .src_penable(dst_cdc_penable),
        .src_pwrite(dst_cdc_pwrite),
        .src_paddr(dst_cdc_paddr),
        .src_pwdata(dst_cdc_pwdata),
        .src_pstrb(dst_cdc_pstrb),
        .src_pprot(dst_cdc_pprot),
        .src_pready(src_pready_o),
        .src_prdata(src_prdata_o),
        .src_pslverr(src_pslverr_o),
        .dst_clk(dst_pclk_i),
        .dst_reset_n(dst_preset_ni),
        .dst_ready(dst_pready_i),
        .dst_rdata(dst_prdata_i),
        .dst_serror(dst_pslverr_i)
    );

endmodule
