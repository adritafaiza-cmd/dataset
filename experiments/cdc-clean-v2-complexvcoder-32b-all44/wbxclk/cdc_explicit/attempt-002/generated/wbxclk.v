module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
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

    // Internal signals
    reg wb_fifo_wen;
    reg wb_fifo_ren;
    reg wb_fifo_full;
    reg wb_fifo_empty;
    reg [(DW-1):0] wb_fifo_data;
    reg wb_fifo_err;
    reg wb_fifo_ack;

    reg xclk_fifo_wen;
    reg xclk_fifo_ren;
    reg xclk_fifo_full;
    reg xclk_fifo_empty;
    reg xclk_fifo_cyc;
    reg xclk_fifo_stb;
    reg xclk_fifo_we;
    reg [(AW-1):0] xclk_fifo_addr;
    reg [(DW-1):0] xclk_fifo_data;
    reg [(DW/8-1):0] xclk_fifo_sel;
    reg xclk_fifo_ack_delayed;
    reg xclk_fifo_err_delayed;

    // FIFO instances
    fifo_sync #(
        .DWIDTH(71),
        .LGFIFO(LGFIFO)
    ) wb_to_xclk_fifo (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .din({i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
        .wen(wb_fifo_wen),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .ren(xclk_fifo_ren),
        .dout({xclk_fifo_cyc, xclk_fifo_stb, xclk_fifo_we, xclk_fifo_addr, xclk_fifo_data, xclk_fifo_sel}),
        .full(wb_fifo_full),
        .empty(wb_fifo_empty)
    );

    fifo_sync #(
        .DWIDTH(34),
        .LGFIFO(LGFIFO)
    ) xclk_to_wb_fifo (
        .clk_wr(i_xclk_clk),
        .rst_wr(i_reset),
        .din({i_xclk_data, i_xclk_err, i_xclk_ack}),
        .wen(xclk_fifo_wen),
        .clk_rd(i_wb_clk),
        .rst_rd(i_reset),
        .ren(wb_fifo_ren),
        .dout({wb_fifo_data, wb_fifo_err, wb_fifo_ack}),
        .full(xclk_fifo_full),
        .empty(xclk_fifo_empty)
    );

    // WB side logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_stall <= 1'b1;
            o_wb_ack <= 1'b0;
            o_wb_data <= {(DW){1'b0}};
            o_wb_err <= 1'b0;
            wb_fifo_ren <= 1'b0;
        end else begin
            o_wb_stall <= wb_fifo_full;
            wb_fifo_ren <= xclk_fifo_ack_delayed;

            if (wb_fifo_ren && !wb_fifo_empty) begin
                o_wb_ack <= wb_fifo_ack;
                o_wb_err <= wb_fifo_err;
                o_wb_data <= wb_fifo_data;
            end else begin
                o_wb_ack <= 1'b0;
                o_wb_err <= 1'b0;
            end
        end
    end

    // XCLK side logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 1'b0;
            o_xclk_stb <= 1'b0;
            o_xclk_we <= 1'b0;
            o_xclk_addr <= {(AW){1'b0}};
            o_xclk_data <= {(DW){1'b0}};
            o_xclk_sel <= {(DW/8){1'b0}};
            xclk_fifo_wen <= 1'b0;
            xclk_fifo_ack_delayed <= 1'b0;
            xclk_fifo_err_delayed <= 1'b0;
        end else begin
            xclk_fifo_wen <= !xclk_fifo_full && xclk_fifo_cyc;
            o_xclk_cyc <= xclk_fifo_cyc;
            o_xclk_stb <= xclk_fifo_stb;
            o_xclk_we <= xclk_fifo_we;
            o_xclk_addr <= xclk_fifo_addr;
            o_xclk_sel <= xclk_fifo_sel;

            if (xclk_fifo_wen && !xclk_fifo_full) begin
                o_xclk_data <= xclk_fifo_data;
            end

            // Delay ACK and ERR for two clock cycles
            xclk_fifo_ack_delayed <= i_xclk_ack;
            xclk_fifo_err_delayed <= i_xclk_err;
        end
    end

endmodule

// Synchronous FIFO module
module fifo_sync #(
    parameter DWIDTH = 32,
              LGFIFO = 5
) (
    input wire clk_wr, rst_wr,
    input wire [DWIDTH-1:0] din,
    input wire wen,
    input wire clk_rd, rst_rd,
    input wire ren,
    output reg [DWIDTH-1:0] dout,
    output reg full,
    output reg empty
);

    localparam DEPTH = 1 << LGFIFO;
    reg [DWIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] cnt;

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            cnt <= 0;
        end else if (wen && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            cnt <= cnt + 1;
        end
    end

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            empty <= 1'b1;
            full <= 1'b0;
        end else if (ren && !empty) begin
            rd_ptr <= rd_ptr + 1;
            cnt <= cnt - 1;
        end
    end

    assign dout = mem[rd_ptr];
    assign full = (cnt == DEPTH);
    assign empty = (cnt == 0);

endmodule
