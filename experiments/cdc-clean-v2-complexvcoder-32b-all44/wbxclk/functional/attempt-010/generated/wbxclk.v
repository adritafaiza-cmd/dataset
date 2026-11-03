module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
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

    // Internal signals for FIFO control
    reg wb_xclk_addr_fifo_wr_en;
    reg wb_xclk_data_fifo_wr_en;
    reg wb_xclk_sel_fifo_wr_en;
    reg [2:0] wb_xclk_ctrl_fifo_din;
    reg wb_xclk_ctrl_fifo_wr_en;
    reg wb_xclk_addr_fifo_rd_en;
    reg wb_xclk_data_fifo_rd_en;
    reg wb_xclk_sel_fifo_rd_en;
    reg wb_xclk_ctrl_fifo_rd_en;
    wire wb_xclk_addr_fifo_full;
    wire wb_xclk_data_fifo_full;
    wire wb_xclk_sel_fifo_full;
    wire wb_xclk_ctrl_fifo_full;
    wire wb_xclk_addr_fifo_empty;
    wire wb_xclk_data_fifo_empty;
    wire wb_xclk_sel_fifo_empty;
    wire wb_xclk_ctrl_fifo_empty;
    wire [2:0] wb_xclk_ctrl_fifo_dout;

    // FIFO instances
    fifo_sync #(.WIDTH(AW), .LGFIFO(LGFIFO)) wb_xclk_addr_fifo (
        .clk(i_xclk_clk),
        .rst(i_reset),
        .din(i_wb_addr),
        .wr_en(wb_xclk_addr_fifo_wr_en),
        .rd_en(wb_xclk_addr_fifo_rd_en),
        .dout(o_xclk_addr),
        .full(wb_xclk_addr_fifo_full),
        .empty(wb_xclk_addr_fifo_empty)
    );

    fifo_sync #(.WIDTH(DW), .LGFIFO(LGFIFO)) wb_xclk_data_fifo (
        .clk(i_xclk_clk),
        .rst(i_reset),
        .din(i_wb_data),
        .wr_en(wb_xclk_data_fifo_wr_en),
        .rd_en(wb_xclk_data_fifo_rd_en),
        .dout(o_xclk_data),
        .full(wb_xclk_data_fifo_full),
        .empty(wb_xclk_data_fifo_empty)
    );

    fifo_sync #(.WIDTH(DW/8), .LGFIFO(LGFIFO)) wb_xclk_sel_fifo (
        .clk(i_xclk_clk),
        .rst(i_reset),
        .din(i_wb_sel),
        .wr_en(wb_xclk_sel_fifo_wr_en),
        .rd_en(wb_xclk_sel_fifo_rd_en),
        .dout(o_xclk_sel),
        .full(wb_xclk_sel_fifo_full),
        .empty(wb_xclk_sel_fifo_empty)
    );

    fifo_sync #(.WIDTH(3), .LGFIFO(LGFIFO)) wb_xclk_ctrl_fifo (
        .clk(i_xclk_clk),
        .rst(i_reset),
        .din(wb_xclk_ctrl_fifo_din),
        .wr_en(wb_xclk_ctrl_fifo_wr_en),
        .rd_en(wb_xclk_ctrl_fifo_rd_en),
        .dout(wb_xclk_ctrl_fifo_dout),
        .full(wb_xclk_ctrl_fifo_full),
        .empty(wb_xclk_ctrl_fifo_empty)
    );

    // FIFO control logic
    assign wb_xclk_addr_fifo_wr_en = i_wb_stb & !wb_xclk_addr_fifo_full;
    assign wb_xclk_data_fifo_wr_en = i_wb_stb & !wb_xclk_data_fifo_full;
    assign wb_xclk_sel_fifo_wr_en = i_wb_stb & !wb_xclk_sel_fifo_full;
    assign wb_xclk_ctrl_fifo_din = {i_wb_cyc, i_wb_stb, i_wb_we};
    assign wb_xclk_ctrl_fifo_wr_en = i_wb_stb & !wb_xclk_ctrl_fifo_full;
    assign wb_xclk_addr_fifo_rd_en = !wb_xclk_addr_fifo_empty & !i_xclk_stall;
    assign wb_xclk_data_fifo_rd_en = !wb_xclk_data_fifo_empty & !i_xclk_stall;
    assign wb_xclk_sel_fifo_rd_en = !wb_xclk_sel_fifo_empty & !i_xclk_stall;
    assign wb_xclk_ctrl_fifo_rd_en = !wb_xclk_ctrl_fifo_empty & !i_xclk_stall;

    // Output assignments
    assign o_wb_stall = wb_xclk_addr_fifo_full;
    assign o_xclk_cyc = wb_xclk_ctrl_fifo_dout[2];
    assign o_xclk_stb = wb_xclk_ctrl_fifo_dout[1];
    assign o_xclk_we = wb_xclk_ctrl_fifo_dout[0];

    // Acknowledge, data, and error handling
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
        end else begin
            o_wb_ack <= i_xclk_ack;
            o_wb_data <= i_xclk_data;
            o_wb_err <= i_xclk_err;
        end
    end

endmodule

module fifo_sync #(
    parameter WIDTH = 32,
              LGFIFO = 5
) (
    input wire clk, rst,
    input wire [WIDTH-1:0] din,
    input wire wr_en, rd_en,
    output reg [WIDTH-1:0] dout,
    output reg full,
    output reg empty
);

    localparam DEPTH = 1 << LGFIFO;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                cnt <= cnt + 1;
                if (cnt == DEPTH - 1)
                    full <= 1;
                empty <= 0;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
                full <= 0;
                if (cnt == 0)
                    empty <= 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= 0;
        else if (rd_en && !empty)
            dout <= mem[rd_ptr];
    end

endmodule
