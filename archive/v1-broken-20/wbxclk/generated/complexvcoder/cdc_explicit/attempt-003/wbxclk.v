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

    // FIFO for Wishbone to Xclk transactions
    wire wrt_en;
    wire rd_en;
    wire [DW-1:0] wrt_data;
    wire [AW-1:0] rd_addr;
    wire [DW-1:0] rd_data;
    wire [DW/8-1:0] rd_sel;
    wire rd_valid;
    wire rd_err;

    fifo #(
        .AW(AW),
        .DW(DW),
        .LGFIFO(LGFIFO)
    ) wb_to_xclk_fifo (
        .clk(i_wb_clk),
        .rst(i_reset),
        .wrt_en(wrt_en),
        .rd_en(rd_en),
        .wrt_data(wrt_data),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_sel(rd_sel),
        .rd_valid(rd_valid),
        .rd_err(rd_err)
    );

    // Internal signals
    reg wb_cyc_reg;
    reg wb_stb_reg;
    reg wb_we_reg;
    reg [AW-1:0] wb_addr_reg;
    reg [DW-1:0] wb_data_reg;
    reg [DW/8-1:0] wb_sel_reg;

    // Pipeline registers
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_cyc_reg <= 0;
            wb_stb_reg <= 0;
            wb_we_reg <= 0;
            wb_addr_reg <= 0;
            wb_data_reg <= 0;
            wb_sel_reg <= 0;
        end else begin
            wb_cyc_reg <= i_wb_cyc;
            wb_stb_reg <= i_wb_stb;
            wb_we_reg <= i_wb_we;
            wb_addr_reg <= i_wb_addr;
            wb_data_reg <= i_wb_data;
            wb_sel_reg <= i_wb_sel;
        end
    end

    // Forward to Xclk domain
    assign wrt_en = wb_cyc_reg && wb_stb_reg;
    assign wrt_data = wb_data_reg;
    assign wrt_data.addr = wb_addr_reg;
    assign wrt_data.data = wb_data_reg;
    assign wrt_data.sel = wb_sel_reg;

    // Receive from Xclk domain
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_stall <= 0;
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else begin
            o_wb_stall <= i_xclk_stall;
            o_wb_ack <= i_xclk_ack;
            o_wb_data <= i_xclk_data;
            o_wb_err <= i_xclk_err;
            o_xclk_cyc <= rd_valid;
            o_xclk_stb <= rd_valid;
            o_xclk_we <= rd_valid;
            o_xclk_addr <= rd_addr;
            o_xclk_data <= rd_data;
            o_xclk_sel <= rd_sel;
        end
    end

endmodule
