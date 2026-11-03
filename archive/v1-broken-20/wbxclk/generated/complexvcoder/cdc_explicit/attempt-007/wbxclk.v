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

    wire wb_crossing_i_clk = i_wb_clk;
    wire wb_crossing_i_reset = i_reset;
    wire wb_crossing_i_cyc = i_wb_cyc;
    wire wb_crossing_i_stb = i_wb_stb;
    wire wb_crossing_i_we = i_wb_we;
    wire [(AW-1):0] wb_crossing_i_addr = i_wb_addr;
    wire [(DW-1):0] wb_crossing_i_data = i_wb_data;
    wire [(DW/8-1):0] wb_crossing_i_sel = i_wb_sel;
    wire wb_crossing_o_cyc;
    wire wb_crossing_o_stb;
    wire wb_crossing_o_we;
    wire [(AW-1):0] wb_crossing_o_addr;
    wire [(DW-1):0] wb_crossing_o_data;
    wire [(DW/8-1):0] wb_crossing_o_sel;
    wire wb_crossing_o_clk = i_xclk_clk;
    wire wb_crossing_o_stall = i_xclk_stall;
    wire wb_crossing_o_ack = i_xclk_ack;
    wire [(DW-1):0] wb_crossing_o_data_in;
    wire wb_crossing_o_err = i_xclk_err;

    wb_crossing #(
        .AW(AW),
        .DW(DW),
        .LGFIFO(LGFIFO)
    ) wb_crossing_inst (
        .i_clk(wb_crossing_i_clk),
        .i_reset(wb_crossing_i_reset),
        .i_cyc(wb_crossing_i_cyc),
        .i_stb(wb_crossing_i_stb),
        .i_we(wb_crossing_i_we),
        .i_addr(wb_crossing_i_addr),
        .i_data(wb_crossing_i_data),
        .i_sel(wb_crossing_i_sel),
        .o_cyc(wb_crossing_o_cyc),
        .o_stb(wb_crossing_o_stb),
        .o_we(wb_crossing_o_we),
        .o_addr(wb_crossing_o_addr),
        .o_data(wb_crossing_o_data),
        .o_sel(wb_crossing_o_sel),
        .o_clk(wb_crossing_o_clk),
        .o_stall(wb_crossing_o_stall),
        .o_ack(wb_crossing_o_ack),
        .o_data(wb_crossing_o_data_in),
        .o_err(wb_crossing_o_err)
    );

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_stall <= 0;
            o_wb_ack <= 0;
            o_wb_err <= 0;
        end else begin
            o_wb_stall <= wb_crossing_o_stall;
            o_wb_ack <= wb_crossing_o_ack;
            o_wb_err <= wb_crossing_o_err;
        end
    end

    always @(posedge i_xclk_clk) begin
        o_xclk_cyc <= wb_crossing_o_cyc;
        o_xclk_stb <= wb_crossing_o_stb;
        o_xclk_we <= wb_crossing_o_we;
        o_xclk_addr <= wb_crossing_o_addr;
        o_xclk_data <= wb_crossing_o_data_in;
        o_xclk_sel <= wb_crossing_o_sel;
    end

endmodule
