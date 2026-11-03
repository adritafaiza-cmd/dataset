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

    wire [ADDR_WIDTH-1:0] src_addr_reg;
    wire [DATA_WIDTH-1:0] src_wdata_reg;
    wire [DATA_WIDTH/8-1:0] src_strb_reg;
    wire [2:0] src_prot_reg;
    wire src_pready_reg;
    wire [DATA_WIDTH-1:0] src_prdata_reg;
    wire src_pslverr_reg;

    wire [ADDR_WIDTH-1:0] dst_addr_reg;
    wire [DATA_WIDTH-1:0] dst_wdata_reg;
    wire [DATA_WIDTH/8-1:0] dst_strb_reg;
    wire [2:0] dst_prot_reg;
    wire dst_pready_reg;
    wire [DATA_WIDTH-1:0] dst_prdata_reg;
    wire dst_pslverr_reg;

    wire src_to_dst_valid;
    wire src_to_dst_ready;
    wire [ADDR_WIDTH-1:0] src_to_dst_addr;
    wire [DATA_WIDTH-1:0] src_to_dst_wdata;
    wire [DATA_WIDTH/8-1:0] src_to_dst_strb;
    wire [2:0] src_to_dst_prot;
    wire src_to_dst_write;

    wire dst_to_src_valid;
    wire dst_to_src_ready;
    wire [ADDR_WIDTH-1:0] dst_to_src_addr;
    wire [DATA_WIDTH-1:0] dst_to_src_rdata;
    wire [DATA_WIDTH/8-1:0] dst_to_src_strb;
    wire [2:0] dst_to_src_prot;
    wire dst_to_src_write;

    sync_reg #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_sync (
        .clk(src_pclk_i),
        .preset_ni(src_preset_ni),
        .sel(src_psel_i),
        .enable(src_penable_i),
        .write(src_pwrite_i),
        .addr(src_paddr_i),
        .wdata(src_pwdata_i),
        .strb(src_pstrb_i),
        .prot(src_pprot_i),
        .ready(src_pready_reg),
        .rdata(src_prdata_reg),
        .slverr(src_pslverr_reg),
        .valid(src_to_dst_valid),
        .ready(src_to_dst_ready),
        .addr(src_to_dst_addr),
        .wdata(src_to_dst_wdata),
        .strb(src_to_dst_strb),
        .prot(src_to_dst_prot),
        .write(src_to_dst_write)
    );

    sync_reg #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_to_src_sync (
        .clk(dst_pclk_i),
        .preset_ni(dst_preset_ni),
        .sel(dst_psel_o),
        .enable(dst_penable_o),
        .write(dst_pwrite_o),
        .addr(dst_paddr_o),
        .wdata(dst_pwdata_o),
        .strb(dst_pstrb_o),
        .prot(dst_pprot_o),
        .ready(dst_pready_i),
        .rdata(dst_prdata_i),
        .slverr(dst_pslverr_i),
        .valid(dst_to_src_valid),
        .ready(dst_to_src_ready),
        .addr(dst_to_src_addr),
        .wdata(dst_to_src_rdata),
        .strb(dst_to_src_strb),
        .prot(dst_to_src_prot),
        .write(dst_to_src_write)
    );

    assign src_psel_o = src_to_dst_ready;
    assign src_penable_o = src_to_dst_ready;
    assign src_pwrite_o = src_to_dst_write;
    assign src_paddr_o = src_to_dst_addr;
    assign src_pwdata_o = src_to_dst_wdata;
    assign src_pstrb_o = src_to_dst_strb;
    assign src_pprot_o = src_to_dst_prot;
    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = src_prdata_reg;
    assign src_pslverr_o = src_pslverr_reg;

    assign dst_psel_o = dst_to_src_valid;
    assign dst_penable_o = dst_to_src_valid;
    assign dst_pwrite_o = dst_to_src_write;
    assign dst_paddr_o = dst_to_src_addr;
    assign dst_pwdata_o = dst_to_src_rdata;
    assign dst_pstrb_o = dst_to_src_strb;
    assign dst_pprot_o = dst_to_src_prot;

endmodule
