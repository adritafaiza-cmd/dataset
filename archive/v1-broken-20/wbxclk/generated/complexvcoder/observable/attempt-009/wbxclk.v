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

    reg wb_fifo_we, wb_fifo_stb, wb_fifo_cyc;
    wire wb_fifo_dout, wb_fifo_full, wb_fifo_empty;
    reg wb_fifo_sel[(DW/8-1):0];
    wire wb_fifo_addr[(AW-1):0];

    reg xclk_fifo_we, xclk_fifo_stb, xclk_fifo_cyc;
    wire xclk_fifo_dout, xclk_fifo_full, xclk_fifo_empty;
    reg xclk_fifo_sel[(DW/8-1):0];
    wire xclk_fifo_addr[(AW-1):0];

    wb_fifo wb_fifo_inst (
        .clk(i_wb_clk),
        .rst(i_reset),
        .din(i_wb_data),
        .we(wb_fifo_we),
        .dout(wb_fifo_dout),
        .full(wb_fifo_full),
        .empty(wb_fifo_empty)
    );

    wb_fifo xclk_fifo_inst (
        .clk(i_xclk_clk),
        .rst(i_reset),
        .din(i_xclk_data),
        .we(xclk_fifo_we),
        .dout(xclk_fifo_dout),
        .full(xclk_fifo_full),
        .empty(xclk_fifo_empty)
    );

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_err <= 0;
            wb_fifo_we <= 0;
            wb_fifo_stb <= 0;
            wb_fifo_cyc <= 0;
            wb_fifo_sel <= 0;
            wb_fifo_addr <= 0;
        end else begin
            o_wb_ack <= (wb_fifo_full) ? 0 : 1;
            o_wb_err <= 0;
            wb_fifo_we <= (i_wb_cyc && i_wb_stb && i_wb_we && !wb_fifo_full) ? 1 : 0;
            wb_fifo_stb <= (i_wb_cyc && i_wb_stb && !wb_fifo_full) ? 1 : 0;
            wb_fifo_cyc <= (i_wb_cyc && !wb_fifo_full) ? 1 : 0;
            wb_fifo_sel <= i_wb_sel;
            wb_fifo_addr <= i_wb_addr;
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else begin
            o_xclk_cyc <= (xclk_fifo_full) ? 0 : 1;
            o_xclk_stb <= (xclk_fifo_full) ? 0 : 1;
            o_xclk_we <= (xclk_fifo_full) ? 0 : 1;
            o_xclk_addr <= xclk_fifo_addr;
            o_xclk_data <= xclk_fifo_dout;
            o_xclk_sel <= xclk_fifo_sel;
        end
    end

endmodule
