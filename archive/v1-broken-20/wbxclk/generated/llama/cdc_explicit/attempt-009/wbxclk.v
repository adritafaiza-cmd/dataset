module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
) (
    input wire            i_wb_clk, i_reset,
    input wire            i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [(AW-1):0] i_wb_addr,
    input wire [(DW-1):0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire           o_wb_stall,
    output reg            o_wb_ack,
    output reg [(DW-1):0] o_wb_data,
    output reg            o_wb_err,
    input wire            i_xclk_clk,
    output reg            o_xclk_cyc,
    output reg            o_xclk_stb,
    output reg            o_xclk_we,
    output reg [(AW-1):0] o_xclk_addr,
    output reg [(DW-1):0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire            i_xclk_stall,
    input wire            i_xclk_ack,
    input wire [(DW-1):0] i_xclk_data,
    input wire            i_xclk_err
);

    reg [LGFIFO-1:0] fifo_fill;
    reg [AW-1:0] fifo_addr[(1<<LGFIFO)-1:0];
    reg [DW-1:0] fifo_data[(1<<LGFIFO)-1:0];
    reg [(DW/8-1):0] fifo_sel[(1<<LGFIFO)-1:0];
    reg [1:0] fifo_we[(1<<LGFIFO)-1:0];

    reg [LGFIFO-1:0] fifo_empty;
    reg [LGFIFO-1:0] fifo_full;

    reg [AW-1:0] xclk_addr;
    reg [DW-1:0] xclk_data;
    reg [(DW/8-1):0] xclk_sel;
    reg [1:0] xclk_we;

    reg wb_stall;
    reg wb_ack;
    reg [DW-1]:0] wb_data;
    reg wb_err;

    reg xclk_cyc;
    reg xclk_stb;
    reg xclk_we_reg;
    reg [(AW-1):0] xclk_addr_reg;
    reg [(DW-1):0] xclk_data_reg;
    reg [(DW/8-1):0] xclk_sel_reg;

    assign o_wb_stall = wb_stall;
    assign o_wb_ack = wb_ack;
    assign o_wb_data = wb_data;
    assign o_wb_err = wb_err;

    assign o_xclk_cyc = xclk_cyc;
    assign o_xclk_stb = xclk_stb;
    assign o_xclk_we = xclk_we_reg;
    assign o_xclk_addr = xclk_addr_reg;
    assign o_xclk_data = xclk_data_reg;
    assign o_xclk_sel = xclk_sel_reg;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_stall <= 1'b0;
            wb_ack <= 1'b0;
            wb_data <= {(DW){1'b0}};
            wb_err <= 1'b0;
            fifo_fill <= {(LGFIFO){1'b0}};
            fifo_empty <= {(LGFIFO){1'b1}};
            fifo_full <= {(LGFIFO){1'b0}};
            xclk_cyc <= 1'b0;
            xclk_stb <= 1'b0;
            xclk_we_reg <= 1'b0;
            xclk_addr_reg <= {(AW){1'b0}};
            xclk_data_reg <= {(DW){1'b0}};
            xclk_sel_reg <= {(DW/8){1'b0}};
        end else begin
            if (i_wb_cyc && i_wb_stb && !wb_stall) begin
                fifo_addr[fifo_fill] <= i_wb_addr;
                fifo_data[fifo_fill] <= i_wb_data;
                fifo_sel[fifo_fill] <= i_wb_sel;
                fifo_we[fifo_fill] <= {i_wb_we, 1'b1};
                fifo_fill <= fifo_fill + 1'b1;
                fifo_empty <= fifo_empty - 1'b1;
                fifo_full <= fifo_full + 1'b1;
                wb_stall <= 1'b1;
            end

            if (i_xclk_ack) begin
                fifo_fill <= fifo_fill - 1'b1;
                fifo_empty <= fifo_empty + 1'b1;
                fifo_full <= fifo_full - 1'b1;
                wb_stall <= 1'b0;
            end

            if (i_xclk_err) begin
                wb_err <= 1'b1;
            end

            if (i_xclk_data != {(DW){1'b0}}) begin
                wb_data <= i_xclk_data;
                wb_ack <= 1'b1;
            end

            if (i_wb_cyc && i_wb_stb && !wb_stall) begin
                xclk_cyc <= 1'b1;
                xclk_stb <= 1'b1;
                xclk_we_reg <= i_wb_we;
                xclk_addr_reg <= i_wb_addr;
                xclk_data_reg <= i_wb_data;
                xclk_sel_reg <= i_wb_sel;
            end

            if (i_xclk_stall) begin
                xclk_cyc <= 1'b0;
                xclk_stb <= 1'b0;
            end
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_cyc <= 1'b0;
            xclk_stb <= 1'b0;
            xclk_we_reg <= 1'b0;
            xclk_addr_reg <= {(AW){1'b0}};
            xclk_data_reg <= {(DW){1'b0}};
            xclk_sel_reg <= {(DW/8){1'b0}};
        end else begin
            if (xclk_cyc && xclk_stb && !i_xclk_stall) begin
                xclk_cyc <= 1'b0;
                xclk_stb <= 1'b0;
            end
        end
    end
endmodule
