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

    localparam FIFO_DEPTH = 2 ** LGFIFO;
    localparam FIFO_PTR_WIDTH = LGFIFO + 1;

    // Wishbone to XCLK FIFO
    reg [FIFO_PTR_WIDTH-1:0] w2x_wr_ptr = 0, w2x_rd_ptr = 0;
    reg [FIFO_PTR_WIDTH-1:0] w2x_wr_ptr_gray = 0, w2x_rd_ptr_gray = 0;
    reg [FIFO_PTR_WIDTH-1:0] w2x_rd_ptr_gray_sync0 = 0, w2x_rd_ptr_gray_sync1 = 0;
    reg [AW+DW+DW/8:0] w2x_fifo [0:FIFO_DEPTH-1];

    // XCLK to Wishbone FIFO
    reg [FIFO_PTR_WIDTH-1:0] x2w_wr_ptr = 0, x2w_rd_ptr = 0;
    reg [FIFO_PTR_WIDTH-1:0] x2w_wr_ptr_gray = 0, x2w_rd_ptr_gray = 0;
    reg [FIFO_PTR_WIDTH-1:0] x2w_rd_ptr_gray_sync0 = 0, x2w_rd_ptr_gray_sync1 = 0;
    reg [DW+1:0] x2w_fifo [0:FIFO_DEPTH-1];

    // Wishbone side logic
    wire fifo_w2x_full = ((w2x_wr_ptr - w2x_rd_ptr) >= FIFO_DEPTH);
    assign o_wb_stall = fifo_w2x_full;

    // Write to Wishbone FIFO
    wire fifo_w2x_wr_en = i_wb_cyc & i_wb_stb & ~o_wb_stall;
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            w2x_wr_ptr <= 0;
            w2x_rd_ptr <= 0;
            w2x_wr_ptr_gray <= 0;
        end else begin
            if (fifo_w2x_wr_en) begin
                w2x_fifo[w2x_wr_ptr[FIFO_PTR_WIDTH-2:0]] <= {i_wb_addr, i_wb_data, i_wb_we, i_wb_sel};
                w2x_wr_ptr <= w2x_wr_ptr + 1;
            end
            w2x_wr_ptr_gray <= bin2gray(w2x_wr_ptr);
        end
    end

    // Synchronize read pointer to Wishbone domain
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            w2x_rd_ptr_gray_sync0 <= 0;
            w2x_rd_ptr_gray_sync1 <= 0;
        end else begin
            w2x_rd_ptr_gray_sync0 <= w2x_rd_ptr_gray;
            w2x_rd_ptr_gray_sync1 <= w2x_rd_ptr_gray_sync0;
        end
    end

    // XCLK side logic
    reg [FIFO_PTR_WIDTH-1:0] xclk_w2x_rd_ptr = 0;
    reg [FIFO_PTR_WIDTH-1:0] w2x_wr_ptr_gray_sync0 = 0, w2x_wr_ptr_gray_sync1 = 0;

    // Read from Wishbone FIFO
    wire fifo_w2x_empty = ((xclk_w2x_rd_ptr - w2x_rd_ptr) == 0);
    wire fifo_w2x_rd_en = !fifo_w2x_empty && !i_xclk_stall;

    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            w2x_wr_ptr_gray_sync0 <= 0;
            w2x_wr_ptr_gray_sync1 <= 0;
            xclk_w2x_rd_ptr <= 0;
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else begin
            w2x_wr_ptr_gray_sync0 <= w2x_wr_ptr_gray;
            w2x_wr_ptr_gray_sync1 <= w2x_wr_ptr_gray_sync0;

            if (fifo_w2x_rd_en) begin
                {o_xclk_addr, o_xclk_data, o_xclk_we, o_xclk_sel} <= w2x_fifo[xclk_w2x_rd_ptr[FIFO_PTR_WIDTH-2:0]];
                xclk_w2x_rd_ptr <= xclk_w2x_rd_ptr + 1;
                o_xclk_cyc <= 1;
                o_xclk_stb <= 1;
            end else if (i_xclk_ack) begin
                o_xclk_cyc <= 0;
                o_xclk_stb <= 0;
            end
        end
    end

    // Write to XCLK FIFO
    wire fifo_x2w_full = ((x2w_wr_ptr - x2w_rd_ptr) >= FIFO_DEPTH);
    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            x2w_wr_ptr <= 0;
            x2w_rd_ptr <= 0;
            x2w_wr_ptr_gray <= 0;
        end else if (i_xclk_ack && !i_xclk_stall) begin
            x2w_fifo[x2w_wr_ptr[FIFO_PTR_WIDTH-2:0]] <= {i_xclk_data, i_xclk_err};
            x2w_wr_ptr <= x2w_wr_ptr + 1;
        end
        x2w_wr_ptr_gray <= bin2gray(x2w_wr_ptr);
    end

    // Synchronize read pointer to XCLK domain
    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            x2w_rd_ptr_gray_sync0 <= 0;
            x2w_rd_ptr_gray_sync1 <= 0;
        end else begin
            x2w_rd_ptr_gray_sync0 <= x2w_rd_ptr_gray;
            x2w_rd_ptr_gray_sync1 <= x2w_rd_ptr_gray_sync0;
        end
    end

    // Read from XCLK FIFO
    wire fifo_x2w_empty = ((x2w_rd_ptr - x2w_wr_ptr) == 0);
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            x2w_rd_ptr <= 0;
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
        end else begin
            if (!fifo_x2w_empty) begin
                {o_wb_data, o_wb_err} <= x2w_fifo[x2w_rd_ptr[FIFO_PTR_WIDTH-2:0]];
                x2w_rd_ptr <= x2w_rd_ptr + 1;
                o_wb_ack <= 1;
            end else begin
                o_wb_ack <= 0;
            end
        end
    end

    // Binary to Gray code conversion
    function [FIFO_PTR_WIDTH-1:0] bin2gray(input [FIFO_PTR_WIDTH-1:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

endmodule
