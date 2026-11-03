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

    reg wb_cyc_reg, wb_stb_reg, wb_we_reg;
    reg [(AW-1):0] wb_addr_reg;
    reg [(DW-1):0] wb_data_reg;
    reg [(DW/8-1):0] wb_sel_reg;
    reg wb_stall_reg;

    wire wb_ack_reg;
    wire wb_err_reg;
    wire [(DW-1):0] wb_data_out_reg;

    reg xclk_cyc_reg, xclk_stb_reg, xclk_we_reg;
    reg [(AW-1):0] xclk_addr_reg;
    reg [(DW-1):0] xclk_data_reg;
    reg [(DW/8-1):0] xclk_sel_reg;
    reg xclk_stall_reg;

    wire xclk_ack_reg;
    wire xclk_err_reg;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_cyc_reg <= 1'b0;
            wb_stb_reg <= 1'b0;
            wb_we_reg <= 1'b0;
            wb_addr_reg <= 32'b0;
            wb_data_reg <= 32'b0;
            wb_sel_reg <= 4'b0;
            wb_stall_reg <= 1'b0;
            o_wb_ack <= 1'b0;
            o_wb_data <= 32'b0;
            o_wb_err <= 1'b0;
        end else begin
            wb_cyc_reg <= i_wb_cyc;
            wb_stb_reg <= i_wb_stb;
            wb_we_reg <= i_wb_we;
            wb_addr_reg <= i_wb_addr;
            wb_data_reg <= i_wb_data;
            wb_sel_reg <= i_wb_sel;
            wb_stall_reg <= i_xclk_stall;
            o_wb_ack <= wb_ack_reg;
            o_wb_data <= wb_data_out_reg;
            o_wb_err <= wb_err_reg;
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_cyc_reg <= 1'b0;
            xclk_stb_reg <= 1'b0;
            xclk_we_reg <= 1'b0;
            xclk_addr_reg <= 32'b0;
            xclk_data_reg <= 32'b0;
            xclk_sel_reg <= 4'b0;
            xclk_stall_reg <= 1'b0;
        end else begin
            xclk_cyc_reg <= i_xclk_cyc;
            xclk_stb_reg <= i_xclk_stb;
            xclk_we_reg <= i_xclk_we;
            xclk_addr_reg <= i_xclk_addr;
            xclk_data_reg <= i_xclk_data;
            xclk_sel_reg <= i_xclk_sel;
            xclk_stall_reg <= i_wb_stall;
        end
    end

    assign o_xclk_cyc = xclk_cyc_reg;
    assign o_xclk_stb = xclk_stb_reg;
    assign o_xclk_we = xclk_we_reg;
    assign o_xclk_addr = xclk_addr_reg;
    assign o_xclk_data = xclk_data_reg;
    assign o_xclk_sel = xclk_sel_reg;
    assign o_xclk_stall = xclk_stall_reg;

    assign wb_ack_reg = i_xclk_ack;
    assign wb_err_reg = i_xclk_err;
    assign wb_data_out_reg = i_xclk_data;

endmodule
