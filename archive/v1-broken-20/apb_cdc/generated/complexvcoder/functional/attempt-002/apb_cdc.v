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
    reg [DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 1:0] src_to_dst_fifo_wdata;
    reg [DATA_WIDTH + 1:0] dst_to_src_fifo_wdata;
    reg src_to_dst_fifo_wvalid;
    reg src_to_dst_fifo_wstrb;
    wire src_to_dst_fifo_wready;
    reg src_to_dst_fifo_rvalid;
    wire src_to_dst_fifo_rdata;
    reg dst_to_src_fifo_rvalid;
    wire dst_to_src_fifo_rdata;
    wire src_to_dst_fifo_wfull;
    wire dst_to_src_fifo_wfull;
    reg [DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 1:0] src_to_dst_fifo_rdata_i;
    reg [DATA_WIDTH + 1:0] dst_to_src_fifo_rdata_i;

    // FIFOs
    apb_fifof #(
        .DATA_WIDTH(DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .wvalid_i(src_to_dst_fifo_wvalid),
        .wready_i(src_to_dst_fifo_wready),
        .wdata_i(src_to_dst_fifo_wdata),
        .wstrb_i(src_to_dst_fifo_wstrb),
        .rvalid_o(src_to_dst_fifo_rvalid),
        .rdata_o(src_to_dst_fifo_rdata)
    );

    apb_fifof #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_to_src_fifo (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .wvalid_i(dst_to_src_fifo_wvalid),
        .wready_i(dst_to_src_fifo_wready),
        .wdata_i(dst_to_src_fifo_wdata),
        .wstrb_i(1'b1),
        .rvalid_o(dst_to_src_fifo_rvalid),
        .rdata_o(dst_to_src_fifo_rdata)
    );

    // Source to Destination FIFO connections
    assign src_to_dst_fifo_wvalid = src_psel_i & src_penable_i;
    assign src_to_dst_fifo_wdata = {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};
    assign src_to_dst_fifo_wstrb = src_pstrb_i;
    assign src_pready_o = src_to_dst_fifo_wready;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_to_dst_fifo_rvalid <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
        end else begin
            if (src_to_dst_fifo_rvalid) begin
                src_prdata_o <= src_to_dst_fifo_rdata_i;
                src_pslverr_o <= src_to_dst_fifo_rdata_i[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8];
            end
        end
    end

    always @(posedge src_to_dst_fifo_rdata) begin
        src_to_dst_fifo_rdata_i <= src_to_dst_fifo_rdata;
    end

    // Destination to Source FIFO connections
    assign dst_to_src_fifo_wvalid = dst_pready_i;
    assign dst_to_src_fifo_wdata = {dst_prdata_i, dst_pslverr_i};

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o <= {3{1'b0}};
        end else begin
            if (dst_to_src_fifo_rvalid) begin
                dst_psel_o <= 1'b1;
                dst_penable_o <= 1'b1;
                dst_pwrite_o <= dst_to_src_fifo_rdata[DATA_WIDTH];
                dst_paddr_o <= dst_to_src_fifo_rdata[DATA_WIDTH + ADDR_WIDTH - 1:DATA_WIDTH];
                dst_pwdata_o <= dst_to_src_fifo_rdata[DATA_WIDTH - 1:0];
                dst_pstrb_o <= {DATA_WIDTH/8{1'b1}};
                dst_pprot_o <= {3{1'b0}};
            end else begin
                dst_psel_o <= 1'b0;
                dst_penable_o <= 1'b0;
                dst_pwrite_o <= 1'b0;
                dst_paddr_o <= {ADDR_WIDTH{1'b0}};
                dst_pwdata_o <= {DATA_WIDTH{1'b0}};
                dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
                dst_pprot_o <= {3{1'b0}};
            end
        end
    end

endmodule
