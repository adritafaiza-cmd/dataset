module apb_ff #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_i,
    input                      rst_ni,
    input                      sel_i,
    input                      en_i,
    input                      write_i,
    input  [ADDR_WIDTH-1:0]    addr_i,
    input  [DATA_WIDTH-1:0]    data_i,
    input  [DATA_WIDTH/8-1:0]  strb_i,
    input  [2:0]               prot_i,
    output                     ready_o,
    output [DATA_WIDTH-1:0]    rdata_o,
    output                     slverr_o
);

    // Internal signals
    reg  [DATA_WIDTH-1:0]    rdata_reg;
    reg  [DATA_WIDTH-1:0]    rdata_next;
    reg  [DATA_WIDTH/8-1:0]  strb_reg;
    reg  [2:0]               prot_reg;
    reg                      ready_reg;
    reg                      ready_next;
    reg                      wr_en;
    reg  [ADDR_WIDTH-1:0]    addr_reg;

    // Write logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_en <= 0;
        end else begin
            wr_en <= write_i;
        end
    end

    // Register update logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rdata_reg <= 0;
            strb_reg <= 0;
            prot_reg <= 0;
            ready_reg <= 0;
            addr_reg <= 0;
        end else if (wr_en) begin
            rdata_reg <= data_i;
            strb_reg <= strb_i;
            prot_reg <= prot_i;
            addr_reg <= addr_i;
            ready_reg <= 1;
        end else if (ready_reg && dst_pready_i) begin
            ready_reg <= 0;
        end
    end

    // Output logic
    assign rdata_o = rdata_reg;
    assign slverr_o = 0; // Assuming no slverr for simplicity
    assign ready_o = ready_reg;

endmodule

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
    wire                     src_ff_selp;
    wire                     src_ff_en;
    wire                     src_ff_write;
    wire  [ADDR_WIDTH-1:0]   src_ff_addr;
    wire  [DATA_WIDTH-1:0]   src_ff_data;
    wire  [DATA_WIDTH/8-1:0] src_ff_strb;
    wire  [2:0]              src_ff_prot;
    wire                     src_ff_ready;
    wire  [DATA_WIDTH-1:0]   src_ff_rdata;
    wire                     src_ff_slverr;

    wire                     dst_ff_selp;
    wire                     dst_ff_en;
    wire                     dst_ff_write;
    wire  [ADDR_WIDTH-1:0]   dst_ff_addr;
    wire  [DATA_WIDTH-1:0]   dst_ff_data;
    wire  [DATA_WIDTH/8-1:0] dst_ff_strb;
    wire  [2:0]              dst_ff_prot;
    wire                     dst_ff_ready;
    wire  [DATA_WIDTH-1:0]   dst_ff_rdata;
    wire                     dst_ff_slverr;

    // Instantiate FIFOs
    apb_ff #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_ff (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .sel_i(src_psel_i),
        .en_i(src_penable_i),
        .write_i(src_pwrite_i),
        .addr_i(src_paddr_i),
        .data_i(src_pwdata_i),
        .strb_i(src_pstrb_i),
        .prot_i(src_pprot_i),
        .ready_o(src_ff_ready),
        .rdata_o(src_ff_rdata),
        .slverr_o(src_ff_slverr)
    );

    apb_ff #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_ff (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .sel_i(dst_psel_o),
        .en_i(dst_penable_o),
        .write_i(dst_pwrite_o),
        .addr_i(dst_paddr_o),
        .data_i(dst_pwdata_o),
        .strb_i(dst_pstrb_o),
        .prot_i(dst_pprot_o),
        .ready_o(dst_ff_ready),
        .rdata_o(dst_ff_rdata),
        .slverr_o(dst_ff_slverr)
    );

    // Handshake logic
    assign dst_psel_o = src_ff_ready;
    assign dst_penable_o = src_ff_ready;
    assign dst_pwrite_o = src_ff_ready;
    assign dst_paddr_o = src_ff_rdata[ADDR_WIDTH-1:0];
    assign dst_pwdata_o = src_ff_rdata;
    assign dst_pstrb_o = src_ff_rdata[DATA_WIDTH/8-1:0];
    assign dst_pprot_o = src_ff_rdata[2:0];

    assign src_pready_o = dst_ff_ready;
    assign src_prdata_o = dst_ff_rdata;
    assign src_pslverr_o = dst_ff_slverr;

endmodule
