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

    // FIFO for Wishbone to XCLK data transfer
    wire fifo_wb_to_xclk_full;
    wire fifo_wb_to_xclk_empty;
    wire [DW+AW+DW/8+2:0] fifo_wb_to_xclk_dout;
    wire fifo_wb_to_xclk_wr_en;
    wire fifo_wb_to_xclk_rd_en;

    // FIFO for XCLK to Wishbone data transfer
    wire fifo_xclk_to_wb_full;
    wire fifo_xclk_to_wb_empty;
    wire [DW+2:0] fifo_xclk_to_wb_dout;
    wire fifo_xclk_to_wb_wr_en;
    wire fifo_xclk_to_wb_rd_en;

    // FIFO write enable signals
    assign fifo_wb_to_xclk_wr_en = i_wb_cyc & i_wb_stb & ~fifo_wb_to_xclk_full;
    assign fifo_xclk_to_wb_wr_en = i_xclk_ack & ~fifo_xclk_to_wb_full;

    // FIFO read enable signals
    assign fifo_wb_to_xclk_rd_en = ~fifo_wb_to_xclk_empty & i_xclk_clk;
    assign fifo_xclk_to_wb_rd_en = ~fifo_xclk_to_wb_empty;

    // FIFO instances
    async_fifo #(
        .WIDTH(DW+AW+DW/8+3),
        .LGFIFO(LGFIFO)
    ) fifo_wb_to_xclk (
        .write_clk(i_wb_clk),
        .write_data({i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
        .write_en(fifo_wb_to_xclk_wr_en),
        .read_clk(i_xclk_clk),
        .read_data(fifo_wb_to_xclk_dout),
        .read_en(fifo_wb_to_xclk_rd_en),
        .full(fifo_wb_to_xclk_full),
        .empty(fifo_wb_to_xclk_empty),
        .reset(i_reset)
    );

    async_fifo #(
        .WIDTH(DW+3),
        .LGFIFO(LGFIFO)
    ) fifo_xclk_to_wb (
        .write_clk(i_xclk_clk),
        .write_data({i_xclk_data, i_xclk_err, i_xclk_ack}),
        .write_en(fifo_xclk_to_wb_wr_en),
        .read_clk(i_wb_clk),
        .read_data(fifo_xclk_to_wb_dout),
        .read_en(fifo_xclk_to_wb_rd_en),
        .full(fifo_xclk_to_wb_full),
        .empty(fifo_xclk_to_wb_empty),
        .reset(i_reset)
    );

    // Output assignments
    assign o_wb_stall = fifo_wb_to_xclk_full;
    assign o_wb_ack = fifo_xclk_to_wb_dout[DW+1];
    assign o_wb_data = fifo_xclk_to_wb_dout[DW-1:0];
    assign o_wb_err = fifo_xclk_to_wb_dout[DW];

    assign o_xclk_cyc = fifo_wb_to_xclk_dout[0];
    assign o_xclk_stb = fifo_wb_to_xclk_dout[1];
    assign o_xclk_we = fifo_wb_to_xclk_dout[2];
    assign o_xclk_addr = fifo_wb_to_xclk_dout[AW+2:3];
    assign o_xclk_data = fifo_wb_to_xclk_dout[DW+AW+2:AW+3];
    assign o_xclk_sel = fifo_wb_to_xclk_dout[DW+AW+DW/8+2:DW+AW+3];

endmodule

// Asynchronous FIFO module
module async_fifo #(
    parameter WIDTH = 32,
              LGFIFO = 5
) (
    input wire write_clk,
    input wire [WIDTH-1:0] write_data,
    input wire write_en,
    input wire read_clk,
    output reg [WIDTH-1:0] read_data,
    input wire read_en,
    output reg full,
    output reg empty,
    input wire reset
);

    localparam DEPTH = 1 << LGFIFO;
    localparam AWIDTH = LGFIFO;

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [AWIDTH:0] wr_ptr, rd_ptr;
    reg [AWIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [AWIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Gray code conversion functions
    function [AWIDTH:0] bin_to_gray;
        input [AWIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [AWIDTH:0] gray_to_bin;
        input [AWIDTH:0] gray;
        integer i;
        reg [AWIDTH:0] bin;
        bin = gray;
        for (i = AWIDTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i] ^ bin[i+1];
        end
        gray_to_bin = bin;
    endfunction

    // Write pointer logic
    always @(posedge write_clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (write_en & ~full) begin
            mem[wr_ptr[AWIDTH-1:0]] <= write_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge read_clk or posedge reset) begin
        if (reset) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (read_en & ~empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
        end
    end

    // Synchronize write pointer gray code to read clock domain
    always @(posedge read_clk or posedge reset) begin
        if (reset) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Synchronize read pointer gray code to write clock domain
    always @(posedge write_clk or posedge reset) begin
        if (reset) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Calculate full and empty flags
    always @(posedge write_clk or posedge reset) begin
        if (reset) begin
            full <= 0;
        end else begin
            full <= (wr_ptr_gray[AWIDTH] != wr_ptr_gray_sync[AWIDTH]) && (wr_ptr_gray[AWIDTH-1:0] == rd_ptr_gray_sync[AWIDTH-1:0]);
        end
    end

    always @(posedge read_clk or posedge reset) begin
        if (reset) begin
            empty <= 1;
        end else begin
            empty <= (wr_ptr_gray_sync[AWIDTH] == rd_ptr_gray[AWIDTH]) && (wr_ptr_gray_sync[AWIDTH-1:0] == rd_ptr_gray[AWIDTH-1:0]);
        end
    end

    // Read data output
    always @(posedge read_clk or posedge reset) begin
        if (reset) begin
            read_data <= 0;
        end else if (read_en & ~empty) begin
            read_data <= mem[rd_ptr[AWIDTH-1:0]];
        end
    end

endmodule
