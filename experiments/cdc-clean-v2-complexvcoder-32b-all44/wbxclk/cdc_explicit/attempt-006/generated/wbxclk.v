module wbxclk #(
        parameter AW=32,
                  DW=32,
                  LGFIFO=5
) (
        input wire i_wb_clk, i_reset,
        input wire i_wb_cyc, i_wb_stb, i_wb_we,
        input wire [AW-1:0] i_wb_addr,
        input wire [DW-1:0] i_wb_data,
        input wire [DW/8-1:0] i_wb_sel,
        output wire o_wb_stall,
        output reg o_wb_ack,
        output reg [DW-1:0] o_wb_data,
        output reg o_wb_err,
        input wire i_xclk_clk,
        output reg o_xclk_cyc,
        output reg o_xclk_stb,
        output reg o_xclk_we,
        output reg [AW-1:0] o_xclk_addr,
        output reg [DW-1:0] o_xclk_data,
        output reg [DW/8-1:0] o_xclk_sel,
        input wire i_xclk_stall,
        input wire i_xclk_ack,
        input wire [DW-1:0] i_xclk_data,
        input wire i_xclk_err
);

    reg o_xclk_cyc_reg, o_xclk_stb_reg;
    reg o_wb_stall_reg, o_wb_ack_reg;

    fifo_async #(.WIDTH(AW), .LGDEPTH(LGFIFO)) wb_to_xclk_addr_fifo (
        .clk_w(i_xclk_clk),
        .clk_r(i_wb_clk),
        .reset(i_reset),
        .stall(i_xclk_stall),
        .data_in(i_wb_addr),
        .data_out(o_xclk_addr),
        .full(o_wb_stall_reg)
    );

    fifo_async #(.WIDTH(DW), .LGDEPTH(LGFIFO)) wb_to_xclk_data_fifo (
        .clk_w(i_xclk_clk),
        .clk_r(i_wb_clk),
        .reset(i_reset),
        .stall(i_xclk_stall),
        .data_in(i_wb_data),
        .data_out(o_xclk_data),
        .full()
    );

    fifo_async #(.WIDTH(1), .LGDEPTH(LGFIFO)) wb_to_xclk_we_fifo (
        .clk_w(i_xclk_clk),
        .clk_r(i_wb_clk),
        .reset(i_reset),
        .stall(i_xclk_stall),
        .data_in(i_wb_we),
        .data_out(o_xclk_we),
        .full()
    );

    fifo_async #(.WIDTH(DW/8), .LGDEPTH(LGFIFO)) wb_to_xclk_sel_fifo (
        .clk_w(i_xclk_clk),
        .clk_r(i_wb_clk),
        .reset(i_reset),
        .stall(i_xclk_stall),
        .data_in(i_wb_sel),
        .data_out(o_xclk_sel),
        .full()
    );

    fifo_async #(.WIDTH(DW), .LGDEPTH(LGFIFO)) xclk_to_wb_data_fifo (
        .clk_w(i_wb_clk),
        .clk_r(i_xclk_clk),
        .reset(i_reset),
        .stall(),
        .data_in(i_xclk_data),
        .data_out(o_wb_data),
        .full(),
        .ack(i_xclk_ack)
    );

    fifo_async #(.WIDTH(1), .LGDEPTH(LGFIFO)) xclk_to_wb_err_fifo (
        .clk_w(i_wb_clk),
        .clk_r(i_xclk_clk),
        .reset(i_reset),
        .stall(),
        .data_in(i_xclk_err),
        .data_out(o_wb_err),
        .full(),
        .ack(i_xclk_ack)
    );

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
            o_wb_stall <= 0;
        end else begin
            o_wb_ack <= i_xclk_ack;
            o_wb_stall <= o_wb_stall_reg;
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else begin
            o_xclk_cyc <= i_wb_cyc;
            o_xclk_stb <= i_wb_stb;
        end
    end

endmodule

module fifo_async #(
        parameter WIDTH = 32,
                  LGDEPTH = 5
) (
        input wire clk_w,
        input wire clk_r,
        input wire reset,
        input wire stall,
        input wire [WIDTH-1:0] data_in,
        output reg [WIDTH-1:0] data_out,
        output reg full,
        input wire ack
);

    localparam DEPTH = 1 << LGDEPTH;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_r, rd_ptr_gray_r;

    always @(posedge clk_w or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
        end else if (~stall) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk_r or posedge reset) begin
        if (reset) begin
            rd_ptr <= 0;
        end else if (ack) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    always @(posedge clk_w) begin
        wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
    end

    always @(posedge clk_r) begin
        rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
    end

    always @(posedge clk_w) begin
        wr_ptr_gray_r <= wr_ptr_gray;
    end

    always @(posedge clk_r) begin
        rd_ptr_gray_r <= rd_ptr_gray;
    end

    always @(posedge clk_w or posedge reset) begin
        if (reset) begin
            full <= 0;
        end else begin
            full <= (wr_ptr_gray_r == {~rd_ptr_gray_r[$clog2(DEPTH)], rd_ptr_gray_r[$clog2(DEPTH)-1:0]});
        end
    end

    always @(posedge clk_w or posedge reset) begin
        if (reset) begin
            mem[wr_ptr] <= 0;
        end else if (~stall) begin
            mem[wr_ptr] <= data_in;
        end
    end

    always @(posedge clk_r) begin
        data_out <= mem[rd_ptr];
    end

endmodule
