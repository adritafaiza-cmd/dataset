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

    wire                      src_master_ready;
    wire [DATA_WIDTH-1:0]       src_master_rdata;
    wire                      src_master_slverr;
    wire                      control_fifo_out;
    wire [DATA_WIDTH-1:0]       data_fifo_out;

    apb_master src_master (
        .clk(src_pclk_i),
        .reset_n(src_preset_ni),
        .sel(src_psel_i),
        .enable(src_penable_i),
        .write(src_pwrite_i),
        .addr(src_paddr_i),
        .wdata(src_pwdata_i),
        .strb(src_pstrb_i),
        .prot(src_pprot_i),
        .ready(src_master_ready),
        .rdata(src_master_rdata),
        .slverr(src_master_slverr)
    );

    apb_slave dst_slave (
        .clk(dst_pclk_i),
        .reset_n(dst_preset_ni),
        .sel(dst_psel_o),
        .enable(dst_penable_o),
        .write(dst_pwrite_o),
        .addr(dst_paddr_o),
        .wdata(dst_pwdata_o),
        .strb(dst_pstrb_o),
        .prot(dst_pprot_o),
        .ready(dst_pready_i),
        .rdata(dst_prdata_i),
        .slverr(dst_pslverr_i)
    );

    fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(1 << LOG_DEPTH)
    ) data_fifo (
        .clk(src_pclk_i),
        .reset_n(src_preset_ni),
        .in(src_master_rdata),
        .out(data_fifo_out),
        .enable(control_fifo_out)
    );

    fifo #(
        .WIDTH(1 + ADDR_WIDTH + 1 + 1 + (DATA_WIDTH/8) + 3),
        .DEPTH(1 << LOG_DEPTH)
    ) control_fifo (
        .clk(src_pclk_i),
        .reset_n(src_preset_ni),
        .in({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pstrb_i, src_pprot_i}),
        .out(control_fifo_out),
        .enable(src_master_ready)
    );

    assign dst_psel_o = control_fifo_out[0];
    assign dst_penable_o = control_fifo_out[1];
    assign dst_pwrite_o = control_fifo_out[2];
    assign dst_paddr_o = control_fifo_out[3 + ADDR_WIDTH - 1 : 3];
    assign dst_pwdata_o = control_fifo_out[3 + ADDR_WIDTH + (DATA_WIDTH/8) - 1 : 3 + ADDR_WIDTH];
    assign dst_pstrb_o = control_fifo_out[3 + ADDR_WIDTH + (DATA_WIDTH/8) + (DATA_WIDTH/8) - 1 : 3 + ADDR_WIDTH + (DATA_WIDTH/8)];
    assign dst_pprot_o = control_fifo_out[3 + ADDR_WIDTH + (DATA_WIDTH/8) + (DATA_WIDTH/8) + (DATA_WIDTH/8) - 1 : 3 + ADDR_WIDTH + (DATA_WIDTH/8) + (DATA_WIDTH/8)];

    assign src_pready_o = control_fifo_out;

endmodule
