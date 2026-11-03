module wbxclk #(
    parameter AW = 32,
    parameter DW = 32,
    parameter LGFIFO = 5
) (
    input wire i_wb_clk, i_reset,
    input wire i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [(AW-1):0] i_wb_addr,
    input wire [(DW-1):0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire o_wb_stall,
    output reg o_wb_ack,
    output reg [(DW-1):0] o_wb_data,
    output reg o_wb_err,
    input wire i_xclk_clk,
    output reg o_xclk_cyc,
    output reg o_xclk_stb,
    output reg o_xclk_we,
    output reg [(AW-1):0] o_xclk_addr,
    output reg [(DW-1):0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire i_xclk_stall,
    input wire i_xclk_ack,
    input wire [(DW-1):0] i_xclk_data,
    input wire i_xclk_err
);

    wire wbs_cyc_sync, wbs_stb_sync, wbs_we_sync;
    wire [(AW-1):0] wbs_addr_sync;
    wire [(DW-1):0] wbs_data_sync;
    wire [(DW/8-1):0] wbs_sel_sync;
    wire wbs_stall_sync, wbs_ack_sync, wbs_err_sync;
    wire xbs_cyc_sync, xbs_stb_sync, xbs_we_sync;
    wire [(AW-1):0] xbs_addr_sync;
    wire [(DW-1):0] xbs_data_sync;
    wire [(DW/8-1):0] xbs_sel_sync;
    wire xbs_stall_sync, xbs_ack_sync, xbs_err_sync;

    fifo_wb_to_xclk wb_to_xclk (
        .clk_in(i_wb_clk),
        .reset_in(i_reset),
        .wbs_cyc(i_wb_cyc),
        .wbs_stb(i_wb_stb),
        .wbs_we(i_wb_we),
        .wbs_addr(i_wb_addr),
        .wbs_data(i_wb_data),
        .wbs_sel(i_wb_sel),
        .wbs_stall(o_wb_stall),
        .wbs_ack(o_wb_ack),
        .wbs_data_out(o_wb_data),
        .wbs_err(o_wb_err),
        .clk_out(i_xclk_clk),
        .xbs_cyc(xbs_cyc_sync),
        .xbs_stb(xbs_stb_sync),
        .xbs_we(xbs_we_sync),
        .xbs_addr(xbs_addr_sync),
        .xbs_data(xbs_data_sync),
        .xbs_sel(xbs_sel_sync),
        .xbs_stall(xbs_stall_sync),
        .xbs_ack(xbs_ack_sync),
        .xbs_data_in(i_xclk_data),
        .xbs_err(i_xclk_err)
    );

    cdc_sync sync_wb_to_xclk (
        .clk_in(i_wb_clk),
        .reset_in(i_reset),
        .wbs_cyc(i_wb_cyc),
        .wbs_stb(i_wb_stb),
        .wbs_we(i_wb_we),
        .wbs_addr(i_wb_addr),
        .wbs_data(i_wb_data),
        .wbs_sel(i_wb_sel),
        .wbs_stall(o_wb_stall),
        .wbs_ack(o_wb_ack),
        .wbs_data_out(o_wb_data),
        .wbs_err(o_wb_err),
        .clk_out(i_xclk_clk),
        .xbs_cyc(xbs_cyc_sync),
        .xbs_stb(xbs_stb_sync),
        .xbs_we(xbs_we_sync),
        .xbs_addr(xbs_addr_sync),
        .xbs_data(xbs_data_sync),
        .xbs_sel(xbs_sel_sync),
        .xbs_stall(xbs_stall_sync),
        .xbs_ack(xbs_ack_sync),
        .xbs_data_in(i_xclk_data),
        .xbs_err(i_xclk_err)
    );

    assign o_xclk_cyc = xbs_cyc_sync;
    assign o_xclk_stb = xbs_stb_sync;
    assign o_xclk_we = xbs_we_sync;
    assign o_xclk_addr = xbs_addr_sync;
    assign o_xclk_data = xbs_data_sync;
    assign o_xclk_sel = xbs_sel_sync;

endmodule
