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
    reg [DATA_WIDTH-1:0]        src_wdata;
    reg [DATA_WIDTH/8-1:0]      src_wstrb;
    reg [2:0]                   src_wprot;
    reg                         src_wlast;
    reg [ADDR_WIDTH-1:0]        src_waddr;
    reg                         src_wvalid;
    wire                        src_wready;
    reg                         src_rvalid;
    wire [DATA_WIDTH-1:0]        src_rdata;
    wire                        src_rslverr;

    reg [DATA_WIDTH-1:0]        dst_rdata;
    reg                         dst_rslverr;
    reg                         dst_rvalid;
    wire                        dst_rready;
    reg                         dst_wvalid;
    wire                        dst_wready;
    reg [DATA_WIDTH-1:0]        dst_wdata;
    reg [DATA_WIDTH/8-1:0]      dst_wstrb;
    reg [2:0]                   dst_wprot;
    reg                         dst_wlast;
    reg [ADDR_WIDTH-1:0]        dst_waddr;

    // FIFO for APB transactions
    fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .wvalid_i(src_psel_i),
        .wready_i(src_wready),
        .wlast_i(src_pwrite_i),
        .wdata_i(src_pwdata_i),
        .wstrb_i(src_pstrb_i),
        .wprot_i(src_pprot_i),
        .wready_o(src_wready),
        .clk_o(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .rready_i(dst_rready),
        .rdata_o(dst_rdata),
        .rserr_o(dst_rslverr),
        .rvalid_o(dst_rvalid),
        .rready_o(dst_rready),
        .rlast_o(dst_rlast),
        .raddr_o(dst_waddr)
    );

    // Handshake logic for source to destination
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_wvalid <= 0;
            src_rvalid <= 0;
        end else begin
            src_wvalid <= src_psel_i && src_penable_i;
            src_rvalid <= dst_rvalid;
        end
    end

    // Handshake logic for destination to source
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_wvalid <= 0;
            src_pready_o <= 0;
        end else begin
            dst_wvalid <= src_wvalid && src_wready;
            src_pready_o <= dst_rready;
        end
    end

    // Connect internal signals to FIFO outputs
    assign src_wdata = src_pwdata_i;
    assign src_wstrb = src_pstrb_i;
    assign src_wprot = src_pprot_i;
    assign src_wlast = src_pwrite_i;
    assign src_waddr = src_paddr_i;

    // Connect internal signals to FIFO inputs
    assign src_pready_o = src_wready;
    assign src_prdata_o = src_rdata;
    assign src_pslverr_o = src_rslverr;

    // Connect internal signals to FIFO outputs
    assign dst_psel_o = src_wvalid;
    assign dst_penable_o = src_wready;
    assign dst_pwrite_o = src_wlast;
    assign dst_paddr_o = src_waddr;
    assign dst_pwdata_o = src_wdata;
    assign dst_pstrb_o = src_wstrb;
    assign dst_pprot_o = src_wprot;

endmodule
