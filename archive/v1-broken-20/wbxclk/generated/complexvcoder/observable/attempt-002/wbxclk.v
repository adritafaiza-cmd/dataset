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

    // Internal signals for wb_clk domain
    reg [AW-1:0] wb_addr;
    reg [DW-1:0] wb_data;
    reg [DW/8-1:0] wb_sel;
    reg wb_cyc;
    reg wb_stb;
    reg wb_we;
    wire wb_ack;
    wire wb_err;
    wire wb_stall;

    // Internal signals for xclk_clk domain
    reg [AW-1:0] xclk_addr;
    reg [DW-1:0] xclk_data;
    reg [DW/8-1:0] xclk_sel;
    reg xclk_cyc;
    reg xclk_stb;
    reg xclk_we;
    wire xclk_ack;
    wire xclk_err;
    wire xclk_stall;

    // Clock divider for generating xclk_clk from i_wb_clk
    wire wb_clk_div;
    wire xclk_clk_div;
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_clk_div <= 0;
            xclk_clk_div <= 0;
        end else begin
            wb_clk_div <= ~wb_clk_div;
            xclk_clk_div <= ~xclk_clk_div;
        end
    end

    // Pipeline registers for wb_clk domain
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_addr <= 0;
            wb_data <= 0;
            wb_sel <= 0;
            wb_cyc <= 0;
            wb_stb <= 0;
            wb_we <= 0;
        end else begin
            wb_addr <= i_wb_addr;
            wb_data <= i_wb_data;
            wb_sel <= i_wb_sel;
            wb_cyc <= i_wb_cyc;
            wb_stb <= i_wb_stb;
            wb_we <= i_wb_we;
        end
    end

    // Pipeline registers for xclk_clk domain
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_addr <= 0;
            xclk_data <= 0;
            xclk_sel <= 0;
            xclk_cyc <= 0;
            xclk_stb <= 0;
            xclk_we <= 0;
        end else begin
            xclk_addr <= wb_addr;
            xclk_data <= wb_data;
            xclk_sel <= wb_sel;
            xclk_cyc <= wb_cyc;
            xclk_stb <= wb_stb;
            xclk_we <= wb_we;
        end
    end

    // Instantiate wb_bridge module
    wb_bridge #(
        .AW(AW),
        .DW(DW),
        .LGFIFO(LGFIFO)
    ) wb_bridge_inst (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_cyc(wb_cyc),
        .i_stb(wb_stb),
        .i_we(wb_we),
        .i_addr(wb_addr),
        .i_data(wb_data),
        .i_sel(wb_sel),
        .o_stall(wb_stall),
        .o_ack(wb_ack),
        .o_data(wb_data),
        .o_err(wb_err),
        .xclk_clk(i_xclk_clk),
        .o_cyc(xclk_cyc),
        .o_stb(xclk_stb),
        .o_we(xclk_we),
        .o_addr(xclk_addr),
        .o_data(xclk_data),
        .o_sel(xclk_sel),
        .i_stall(xclk_stall),
        .i_ack(xclk_ack),
        .i_data(xclk_data),
        .i_err(xclk_err)
    );

    // Assign outputs
    assign o_wb_stall = wb_stall;
    assign o_wb_ack = wb_ack;
    assign o_wb_err = wb_err;
    assign o_xclk_cyc = xclk_cyc;
    assign o_xclk_stb = xclk_stb;
    assign o_xclk_we = xclk_we;
    assign o_xclk_addr = xclk_addr;
    assign o_xclk_data = xclk_data;
    assign o_xclk_sel = xclk_sel;

endmodule

module wb_bridge #(
    parameter AW = 32,
    parameter DW = 32,
    parameter LGFIFO = 5
) (
    input wire i_clk,
    input wire i_reset,
    input wire i_cyc,
    input wire i_stb,
    input wire i_we,
    input wire [(AW-1):0] i_addr,
    input wire [(DW-1):0] i_data,
    input wire [(DW/8-1):0] i_sel,
    output wire o_stall,
    output wire o_ack,
    output wire [(DW-1):0] o_data,
    output wire o_err,
    input wire xclk_clk,
    output wire o_cyc,
    output wire o_stb,
    output wire o_we,
    output wire [(AW-1):0] o_addr,
    output wire [(DW-1):0] o_data,
    output wire [(DW/8-1):0] o_sel,
    input wire xclk_stall,
    input wire xclk_ack,
    input wire [(DW-1):0] xclk_data,
    input wire xclk_err
);

    // Internal signals for wb_clk domain
    reg [AW-1:0] wb_addr;
    reg [DW-1:0] wb_data;
    reg [DW/8-1:0] wb_sel;
    reg wb_cyc;
    reg wb_stb;
    reg wb_we;
    wire wb_ack;
    wire wb_err;
    wire wb_stall;

    // Internal signals for xclk_clk domain
    reg [AW-1:0] xclk_addr;
    reg [DW-1:0] xclk_data;
    reg [DW/8-1:0] xclk_sel;
    reg xclk_cyc;
    reg xclk_stb;
    reg xclk_we;
    wire xclk_ack;
    wire xclk_err;
    wire xclk_stall;

    // Pipeline registers for wb_clk domain
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_addr <= 0;
            wb_data <= 0;
            wb_sel <= 0;
            wb_cyc <= 0;
            wb_stb <= 0;
            wb_we <= 0;
        end else begin
            wb_addr <= i_addr;
            wb_data <= i_data;
            wb_sel <= i_sel;
            wb_cyc <= i_cyc;
            wb_stb <= i_stb;
            wb_we <= i_we;
        end
    end

    // Pipeline registers for xclk_clk domain
    always @(posedge xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_addr <= 0;
            xclk_data <= 0;
            xclk_sel <= 0;
            xclk_cyc <= 0;
            xclk_stb <= 0;
            xclk_we <= 0;
        end else begin
            xclk_addr <= wb_addr;
            xclk_data <= wb_data;
            xclk_sel <= wb_sel;
            xclk_cyc <= wb_cyc;
            xclk_stb <= wb_stb;
            xclk_we <= wb_we;
        end
    end

    // Instantiate wb_bridge_core module
    wb_bridge_core #(
        .AW(AW),
        .DW(DW),
        .LGFIFO(LGFIFO)
    ) wb_bridge_core_inst (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_cyc(wb_cyc),
        .i_stb(wb_stb),
        .i_we(wb_we),
        .i_addr(wb_addr),
        .i_data(wb_data),
        .i_sel(wb_sel),
        .o_stall(wb_stall),
        .o_ack(wb_ack),
        .o_data(wb_data),
        .o_err(wb_err),
        .xclk_clk(xclk_clk),
        .o_cyc(xclk_cyc),
        .o_stb(xclk_stb),
        .o_we(xclk_we),
        .o_addr(xclk_addr),
        .o_data(xclk_data),
        .o_sel(xclk_sel),
        .i_stall(xclk_stall),
        .i_ack(xclk_ack),
        .i_data(xclk_data),
        .i_err(xclk_err)
    );

endmodule

module wb_bridge_core #(
    parameter AW = 32,
    parameter DW = 32,
    parameter LGFIFO = 5
) (
    input wire i_clk,
    input wire i_reset,
    input wire i_cyc,
    input wire i_stb,
    input wire i_we,
    input wire [(AW-1):0] i_addr,
    input wire [(DW-1):0] i_data,
    input wire [(DW/8-1):0] i_sel,
    output wire o_stall,
    output wire o_ack,
    output wire [(DW-1):0] o_data,
    output wire o_err,
    input wire xclk_clk,
    output wire o_cyc,
    output wire o_stb,
    output wire o_we,
    output wire [(AW-1):0] o_addr,
    output wire [(DW-1):0] o_data,
    output wire [(DW/8-1):0] o_sel,
    input wire xclk_stall,
    input wire xclk_ack,
    input wire [(DW-1):0] xclk_data,
    input wire xclk_err
);

    // Internal signals for wb_clk domain
    reg [AW-1:0] wb_addr;
    reg [DW-1:0] wb_data;
    reg [DW/8-1:0] wb_sel;
    reg wb_cyc;
    reg wb_stb;
    reg wb_we;
    wire wb_ack;
    wire wb_err;
    wire wb_stall;

    // Internal signals for xclk_clk domain
    reg [AW-1:0] xclk_addr;
    reg [DW-1:0] xclk_data;
    reg [DW/8-1:0] xclk_sel;
    reg xclk_cyc;
    reg xclk_stb;
    reg xclk_we;
    wire xclk_ack;
    wire xclk_err;
    wire xclk_stall;

    // Pipeline registers for wb_clk domain
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_addr <= 0;
            wb_data <= 0;
            wb_sel <= 0;
            wb_cyc <= 0;
            wb_stb <= 0;
            wb_we <= 0;
        end else begin
            wb_addr <= i_addr;
            wb_data <= i_data;
            wb_sel <= i_sel;
            wb_cyc <= i_cyc;
            wb_stb <= i_stb;
            wb_we <= i_we;
        end
    end

    // Pipeline registers for xclk_clk domain
    always @(posedge xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_addr <= 0;
            xclk_data <= 0;
            xclk_sel <= 0;
            xclk_cyc <= 0;
            xclk_stb <= 0;
            xclk_we <= 0;
        end else begin
            xclk_addr <= wb_addr;
            xclk_data <= wb_data;
            xclk_sel <= wb_sel;
            xclk_cyc <= wb_cyc;
            xclk_stb <= wb_stb;
            xclk_we <= wb_we;
        end
    end

    // Wishbone bridge logic
    assign o_stall = wb_stall || xclk_stall;
    assign o_ack = wb_ack && xclk_ack;
    assign o_data = wb_data;
    assign o_err = wb_err || xclk_err;
    assign o_cyc = wb_cyc && xclk_cyc;
    assign o_stb = wb_stb && xclk_stb;
    assign o_we = wb_we && xclk_we;
    assign o_addr = wb_addr;
    assign o_data = wb_data;
    assign o_sel = wb_sel;

endmodule
