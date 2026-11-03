module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
) (
    input  wire          i_wb_clk, i_reset,
    input  wire          i_wb_cyc, i_wb_stb, i_wb_we,
    input  wire [AW-1:0] i_wb_addr,
    input  wire [DW-1:0] i_wb_data,
    input  wire [DW/8-1:0] i_wb_sel,
    output wire          o_wb_stall,
    output reg           o_wb_ack,
    output reg [DW-1:0]  o_wb_data,
    output reg           o_wb_err,
    input  wire          i_xclk_clk,
    output reg           o_xclk_cyc,
    output reg           o_xclk_stb,
    output reg           o_xclk_we,
    output reg [AW-1:0]  o_xclk_addr,
    output reg [DW-1:0]  o_xclk_data,
    output reg [DW/8-1:0] o_xclk_sel,
    input  wire          i_xclk_stall,
    input  wire          i_xclk_ack,
    input  wire [DW-1:0] i_xclk_data,
    input  wire          i_xclk_err
);

    reg [DW-1:0] xclk_data_sync;
    reg          xclk_ack_sync;
    reg          xclk_err_sync;

    wire wb_xclk_cyc;

    async_fifo #(
        .DATA_WIDTH(AW),
        .LOG_DEPTH(LGFIFO)
    ) wb_xclk_addr_fifo (
        .wr_clk(i_wb_clk),
        .reset(i_reset),
        .din(i_wb_addr),
        .wr_en(i_wb_cyc && i_wb_stb),
        .dout(o_xclk_addr),
        .rd_en(!wb_xclk_cyc && !i_xclk_stall && i_xclk_clk),
        .rd_clk(i_xclk_clk),
        .o_full(o_wb_stall),
        .o_empty(wb_xclk_cyc)
    );

    async_fifo #(
        .DATA_WIDTH(DW),
        .LOG_DEPTH(LGFIFO)
    ) wb_xclk_data_fifo (
        .wr_clk(i_wb_clk),
        .reset(i_reset),
        .din(i_wb_data),
        .wr_en(i_wb_cyc && i_wb_stb),
        .dout(o_xclk_data),
        .rd_en(!wb_xclk_cyc && !i_xclk_stall && i_xclk_clk),
        .rd_clk(i_xclk_clk),
        .o_full(o_wb_stall),
        .o_empty(wb_xclk_cyc)
    );

    async_fifo #(
        .DATA_WIDTH(1),
        .LOG_DEPTH(LGFIFO)
    ) wb_xclk_we_fifo (
        .wr_clk(i_wb_clk),
        .reset(i_reset),
        .din(i_wb_we),
        .wr_en(i_wb_cyc && i_wb_stb),
        .dout(o_xclk_we),
        .rd_en(!wb_xclk_cyc && !i_xclk_stall && i_xclk_clk),
        .rd_clk(i_xclk_clk),
        .o_full(o_wb_stall),
        .o_empty(wb_xclk_cyc)
    );

    async_fifo #(
        .DATA_WIDTH(DW/8),
        .LOG_DEPTH(LGFIFO)
    ) wb_xclk_sel_fifo (
        .wr_clk(i_wb_clk),
        .reset(i_reset),
        .din(i_wb_sel),
        .wr_en(i_wb_cyc && i_wb_stb),
        .dout(o_xclk_sel),
        .rd_en(!wb_xclk_cyc && !i_xclk_stall && i_xclk_clk),
        .rd_clk(i_xclk_clk),
        .o_full(o_wb_stall),
        .o_empty(wb_xclk_cyc)
    );

    sync_register #(
        .DATA_WIDTH(1)
    ) xclk_ack_sync_inst (
        .src_clk(i_xclk_clk),
        .src_data(i_xclk_ack),
        .dst_clk(i_wb_clk),
        .dst_data(xclk_ack_sync)
    );

    sync_register #(
        .DATA_WIDTH(1)
    ) xclk_err_sync_inst (
        .src_clk(i_xclk_clk),
        .src_data(i_xclk_err),
        .dst_clk(i_wb_clk),
        .dst_data(xclk_err_sync)
    );

    sync_register #(
        .DATA_WIDTH(DW)
    ) xclk_data_sync_inst (
        .src_clk(i_xclk_clk),
        .src_data(i_xclk_data),
        .dst_clk(i_wb_clk),
        .dst_data(xclk_data_sync)
    );

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else begin
            o_wb_ack <= xclk_ack_sync;
            o_wb_err <= xclk_err_sync;
            o_wb_data <= xclk_data_sync;
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else begin
            o_xclk_cyc <= !wb_xclk_cyc && !i_xclk_stall;
            o_xclk_stb <= !wb_xclk_cyc && !i_xclk_stall;
        end
    end

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
              LOG_DEPTH = 5
) (
    input  wire wr_clk,
    input  wire reset,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire wr_en,
    output wire [DATA_WIDTH-1:0] dout,
    input  wire rd_en,
    input  wire rd_clk,
    output wire o_full,
    output wire o_empty
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam AW = LOG_DEPTH;

    reg [AW-1:0] wr_ptr, rd_ptr;
    reg [AW-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [AW-1:0] rd_ptr_gray_sync;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    wire [AW-1:0] wr_ptr_gray_next;
    wire [AW-1:0] rd_ptr_gray_next;

    assign wr_ptr_gray_next = (wr_ptr >> 1) ^ wr_ptr;
    assign rd_ptr_gray_next = (rd_ptr >> 1) ^ rd_ptr;

    assign o_full = (wr_ptr_gray_next == {~rd_ptr_gray_sync[AW-1], rd_ptr_gray_sync[AW-2:0]});
    assign o_empty = (wr_ptr_gray == rd_ptr_gray_sync);

    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !o_full) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray_next;
            mem[wr_ptr] <= din;
        end
    end

    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !o_empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end

    sync_register #(
        .DATA_WIDTH(AW)
    ) rd_ptr_gray_sync_inst (
        .src_clk(wr_clk),
        .src_data(wr_ptr_gray),
        .dst_clk(rd_clk),
        .dst_data(rd_ptr_gray_sync)
    );

    always @(posedge rd_clk) begin
        if (!o_empty)
            dout <= mem[rd_ptr];
    end

endmodule

module sync_register #(
    parameter DATA_WIDTH = 32
) (
    input  wire src_clk,
    input  wire [DATA_WIDTH-1:0] src_data,
    input  wire dst_clk,
    output reg [DATA_WIDTH-1:0] dst_data
);

    reg [DATA_WIDTH-1:0] sync_reg [0:1];

    always @(posedge src_clk) begin
        sync_reg[0] <= src_data;
    end

    always @(posedge dst_clk) begin
        sync_reg[1] <= sync_reg[0];
        dst_data <= sync_reg[1];
    end

endmodule
