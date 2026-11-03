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

    wire [DATA_WIDTH-1:0] src_to_dst_fifo_din;
    wire                  src_to_dst_fifo_wr_en;
    wire                  src_to_dst_fifo_rd_en;
    wire [DATA_WIDTH-1:0] src_to_dst_fifo_dout;
    wire                  src_to_dst_fifo_empty;
    wire                  src_to_dst_fifo_full;

    wire                  src_to_dst_handshake_sel;
    wire                  src_to_dst_handshake_en;
    wire                  src_to_dst_handshake_write;
    wire [ADDR_WIDTH-1:0] src_to_dst_handshake_addr;
    wire [DATA_WIDTH/8-1:0] src_to_dst_handshake_strb;
    wire [2:0]              src_to_dst_handshake_prot;
    wire                  src_to_dst_handshake_dsel;
    wire                  src_to_dst_handshake_den;
    wire                  src_to_dst_handshake_dwrite;
    wire [ADDR_WIDTH-1:0] src_to_dst_handshake_daddr;
    wire [DATA_WIDTH/8-1:0] src_to_dst_handshake_dstrb;
    wire [2:0]              src_to_dst_handshake_dprot;
    wire                  src_to_dst_handshake_dready;
    wire [DATA_WIDTH-1:0] src_to_dst_handshake_dprdata;
    wire                  src_to_dst_handshake_dpslverr;
    wire                  src_to_dst_handshake_sready;
    wire [DATA_WIDTH-1:0] src_to_dst_handshake_sprdata;
    wire                  src_to_dst_handshake_spslverr;

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .din(src_to_dst_fifo_din),
        .wr_en(src_to_dst_fifo_wr_en),
        .rd_en(src_to_dst_fifo_rd_en),
        .dout(src_to_dst_fifo_dout),
        .empty(src_to_dst_fifo_empty),
        .full(src_to_dst_fifo_full)
    );

    handshake #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_WIDTH_STRB(DATA_WIDTH/8)
    ) src_to_dst_handshake (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dclk(dst_pclk_i),
        .drst_n(dst_preset_ni),
        .sel(src_to_dst_handshake_sel),
        .en(src_to_dst_handshake_en),
        .write(src_to_dst_handshake_write),
        .addr(src_to_dst_handshake_addr),
        .strb(src_to_dst_handshake_strb),
        .prot(src_to_dst_handshake_prot),
        .dsel(src_to_dst_handshake_dsel),
        .den(src_to_dst_handshake_den),
        .dwrite(src_to_dst_handshake_dwrite),
        .daddr(src_to_dst_handshake_daddr),
        .dstrb(src_to_dst_handshake_dstrb),
        .dprot(src_to_dst_handshake_dprot),
        .dready(src_to_dst_handshake_dready),
        .dprdata(src_to_dst_handshake_dprdata),
        .dpslverr(src_to_dst_handshake_dpslverr),
        .sready(src_to_dst_handshake_sready),
        .sprdata(src_to_dst_handshake_sprdata),
        .spslverr(src_to_dst_handshake_spslverr)
    );

    assign src_to_dst_fifo_din = src_pwdata_i;
    assign src_to_dst_fifo_wr_en = src_pready_o & src_penable_i & src_psel_i;
    assign src_to_dst_fifo_rd_en = src_to_dst_handshake_sready;

    assign dst_psel_o = src_to_dst_handshake_dsel;
    assign dst_penable_o = src_to_dst_handshake_den;
    assign dst_pwrite_o = src_to_dst_handshake_dwrite;
    assign dst_paddr_o = src_to_dst_handshake_daddr;
    assign dst_pwdata_o = src_to_dst_handshake_dprdata;
    assign dst_pstrb_o = src_to_dst_handshake_dstrb;
    assign dst_pprot_o = src_to_dst_handshake_dprot;

    assign src_pready_o = src_to_dst_handshake_sready;
    assign src_prdata_o = src_to_dst_handshake_sprdata;
    assign src_pslverr_o = src_to_dst_handshake_spslverr;

endmodule
