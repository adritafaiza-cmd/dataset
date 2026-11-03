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
    wire                      src_to_dst_ready;
    wire [DATA_WIDTH-1:0]     src_to_dst_rdata;
    wire                      src_to_dst_slverr;
    wire                      dst_to_src_ready;
    wire [DATA_WIDTH-1:0]     dst_to_src_rdata;
    wire                      dst_to_src_slverr;

    // APB crossing from source to destination
    apb_crossing #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) apb_crossing_src_to_dst (
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
        .rdata_o(src_to_dst_rdata),
        .slverr_o(src_to_dst_slverr)
    );

    // APB crossing from destination to source
    apb_crossing #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) apb_crossing_dst_to_src (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .ready_i(dst_pready_i),
        .rdata_i(dst_prdata_i),
        .slverr_i(dst_pslverr_i),
        .sel_o(dst_psel_o),
        .enable_o(dst_penable_o),
        .write_o(dst_pwrite_o),
        .addr_o(dst_paddr_o),
        .wdata_o(dst_pwdata_o),
        .strb_o(dst_pstrb_o),
        .prot_o(dst_pprot_o)
    );

    // Connect internal signals to outputs
    assign src_pready_o = src_to_dst_ready;
    assign src_prdata_o = src_to_dst_rdata;
    assign src_pslverr_o = src_to_dst_slverr;

endmodule

module apb_crossing #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_i,
    input                      rst_ni,
    input                      sel_i,
    input                      enable_i,
    input                      write_i,
    input  [ADDR_WIDTH-1:0]    addr_i,
    input  [DATA_WIDTH-1:0]    wdata_i,
    input  [DATA_WIDTH/8-1:0]  strb_i,
    input  [2:0]               prot_i,
    output                     ready_o,
    output [DATA_WIDTH-1:0]    rdata_o,
    output                     slverr_o
);

    // Internal signals
    reg                      ready;
    reg [DATA_WIDTH-1:0]       rdata;
    reg                      slverr;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ready <= 0;
            rdata <= 0;
            slverr <= 0;
        end else begin
            ready <= enable_i && write_i;
            rdata <= wdata_i;
            slverr <= 0;
        end
    end

    assign ready_o = ready;
    assign rdata_o = rdata;
    assign slverr_o = slverr;

endmodule
