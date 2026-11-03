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

    reg [AW-1:0] wb_addr_reg;
    reg [DW-1:0] wb_data_reg;
    reg [DW/8-1:0] wb_sel_reg;
    reg wb_cyc_reg;
    reg wb_stb_reg;
    reg wb_we_reg;

    wire wb_stall_wire;
    wire wb_ack_wire;
    wire [DW-1:0] wb_data_wire;
    wire wb_err_wire;

    wire xclk_cyc_wire;
    wire xclk_stb_wire;
    wire xclk_we_wire;
    wire [AW-1:0] xclk_addr_wire;
    wire [DW-1:0] xclk_data_wire;
    wire [DW/8-1:0] xclk_sel_wire;

    assign o_wb_stall = wb_stall_wire;
    assign o_wb_ack = wb_ack_wire;
    assign o_wb_data = wb_data_wire;
    assign o_wb_err = wb_err_wire;

    assign o_xclk_cyc = xclk_cyc_wire;
    assign o_xclk_stb = xclk_stb_wire;
    assign o_xclk_we = xclk_we_wire;
    assign o_xclk_addr = xclk_addr_wire;
    assign o_xclk_data = xclk_data_wire;
    assign o_xclk_sel = xclk_sel_wire;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_addr_reg <= 0;
            wb_data_reg <= 0;
            wb_sel_reg <= 0;
            wb_cyc_reg <= 0;
            wb_stb_reg <= 0;
            wb_we_reg <= 0;
            wb_ack_wire <= 0;
            wb_err_wire <= 0;
        end else begin
            wb_addr_reg <= i_wb_addr;
            wb_data_reg <= i_wb_data;
            wb_sel_reg <= i_wb_sel;
            wb_cyc_reg <= i_wb_cyc;
            wb_stb_reg <= i_wb_stb;
            wb_we_reg <= i_wb_we;
        end
    end

    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            xclk_cyc_wire <= 0;
            xclk_stb_wire <= 0;
            xclk_we_wire <= 0;
            xclk_addr_wire <= 0;
            xclk_data_wire <= 0;
            xclk_sel_wire <= 0;
        end else begin
            xclk_cyc_wire <= wb_cyc_reg;
            xclk_stb_wire <= wb_stb_reg;
            xclk_we_wire <= wb_we_reg;
            xclk_addr_wire <= wb_addr_reg;
            xclk_data_wire <= wb_data_reg;
            xclk_sel_wire <= wb_sel_reg;
        end
    end

    assign wb_stall_wire = i_xclk_stall;
    assign wb_ack_wire = i_xclk_ack;
    assign wb_data_wire = i_xclk_data;
    assign wb_err_wire = i_xclk_err;

endmodule
