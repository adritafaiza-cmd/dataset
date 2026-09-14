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
    reg [DATA_WIDTH-1:0] src_to_dst_fifo_wr_data;
    reg [DATA_WIDTH-1:0] src_to_dst_fifo_rd_data;
    reg src_to_dst_fifo_wr_en;
    reg src_to_dst_fifo_rd_en;
    reg src_to_dst_fifo_wr_full;
    reg src_to_dst_fifo_rd_empty;
    reg [DATA_WIDTH-1:0] src_to_dst_fifo_wr_valid;
    reg [DATA_WIDTH-1:0] src_to_dst_fifo_rd_ready;
    reg src_to_dst_handshake_sel;
    reg src_to_dst_handshake_enable;
    reg src_to_dst_handshake_write;
    reg [ADDR_WIDTH-1:0] src_to_dst_handshake_addr;
    reg [DATA_WIDTH-1:0] src_to_dst_handshake_wdata;
    reg [DATA_WIDTH/8-1:0] src_to_dst_handshake_strb;
    reg [2:0] src_to_dst_handshake_prot;
    reg src_to_dst_handshake_ready;
    reg [DATA_WIDTH-1:0] src_to_dst_handshake_rdata;
    reg src_to_dst_handshake_slverr;

    // FIFO for transferring data from src to dst
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .wr_en_i(src_to_dst_fifo_wr_en),
        .wr_data_i(src_to_dst_fifo_wr_data),
        .rd_clk_i(dst_pclk_i),
        .rd_rst_ni(dst_preset_ni),
        .rd_en_i(src_to_dst_fifo_rd_en),
        .rd_data_o(src_to_dst_fifo_rd_data),
        .wr_full(src_to_dst_fifo_wr_full),
        .rd_empty(src_to_dst_fifo_rd_empty),
        .wr_valid(src_to_dst_fifo_wr_valid),
        .rd_ready(src_to_dst_fifo_rd_ready)
    );

    // Handshake logic for transferring data from src to dst
    handshake #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) src_to_dst_handshake (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .sel_i(src_psel_i),
        .enable_i(src_penable_i),
        .write_i(src_pwrite_i),
        .addr_i(src_paddr_i),
        .wdata_i(src_pwdata_i),
        .strb_i(src_pstrb_i),
        .prot_i(src_pprot_i),
        .full_i(src_to_dst_fifo_wr_full),
        .empty_i(src_to_dst_fifo_rd_empty),
        .wdata_o(src_to_dst_fifo_wr_data),
        .rdata_i(src_to_dst_fifo_rd_data),
        .valid_o(src_to_dst_fifo_wr_valid),
        .ready_o(src_to_dst_fifo_rd_ready),
        .ready_o_o(src_pready_o),
        .rdata_o_o(src_prdata_o),
        .slverr_o_o(src_pslverr_o)
    );

    // Drive outputs for destination interface
    assign dst_psel_o = src_to_dst_handshake_sel;
    assign dst_penable_o = src_to_dst_handshake_enable;
    assign dst_pwrite_o = src_to_dst_handshake_write;
    assign dst_paddr_o = src_to_dst_handshake_addr;
    assign dst_pwdata_o = src_to_dst_handshake_wdata;
    assign dst_pstrb_o = src_to_dst_handshake_strb;
    assign dst_pprot_o = src_to_dst_handshake_prot;

endmodule
