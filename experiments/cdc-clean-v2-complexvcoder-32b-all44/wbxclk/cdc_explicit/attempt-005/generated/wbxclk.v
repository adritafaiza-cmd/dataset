module wbxclk #(
        parameter AW=32,
                  DW=32,
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
    reg wb_to_xclk_wr_en;
    reg [(DW + AW + 2 + DW/8 - 1):0] wb_to_xclk_data;
    reg wb_to_xclk_full;
    reg wb_to_xclk_empty;
    reg wb_to_xclk_ack;
    reg wb_to_xclk_err;
    reg xclk_to_wb_wr_en;
    reg [(DW + 2 - 1):0] xclk_to_wb_data;
    reg xclk_to_wb_full;
    reg xclk_to_wb_empty;
    reg xclk_cyc;
    reg xclk_stb;
    reg xclk_ack_reg;
    reg xclk_err_reg;

    // Instantiate FIFOs
    fifo_async #(.WIDTH(DW + AW + 2 + DW/8))
    fifo_wb_to_xclk (
        .i_clk_wr(i_wb_clk),
        .i_clk_rd(i_xclk_clk),
        .i_reset(i_reset),
        .i_wr_en(wb_to_xclk_wr_en),
        .i_data(wb_to_xclk_data),
        .i_full(wb_to_xclk_full),
        .i_empty(wb_to_xclk_empty),
        .o_rd_en(xclk_to_wb_rd_en),
        .o_data(xclk_to_wb_data)
    );

    fifo_async #(.WIDTH(DW + 2))
    fifo_xclk_to_wb (
        .i_clk_wr(i_xclk_clk),
        .i_clk_rd(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(xclk_to_wb_wr_en),
        .i_data(xclk_to_wb_data),
        .i_full(xclk_to_wb_full),
        .i_empty(xclk_to_wb_empty),
        .o_rd_en(wb_to_xclk_rd_en),
        .o_data(wb_to_xclk_data)
    );

    // WB to XCLK data packing
    always @(*) begin
        wb_to_xclk_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
    end

    // XCLK to WB data unpacking
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
        end else if (wb_to_xclk_ack) begin
            o_wb_ack <= 1;
            o_wb_data <= wb_to_xclk_data[(DW + 2 + AW + DW/8 - 1):(2 + AW + DW/8)];
            o_wb_err <= wb_to_xclk_data[0];
        end else begin
            o_wb_ack <= 0;
        end
    end

    // XCLK to WB response handling
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_to_xclk_ack <= 0;
            wb_to_xclk_err <= 0;
        end else if (xclk_to_wb_empty) begin
            wb_to_xclk_ack <= 0;
            wb_to_xclk_err <= 0;
        end else if (wb_to_xclk_rd_en) begin
            wb_to_xclk_ack <= xclk_ack_reg;
            wb_to_xclk_err <= xclk_err_reg;
        end
    end

    // WB to XCLK write enable
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_to_xclk_wr_en <= 0;
        end else begin
            wb_to_xclk_wr_en <= i_wb_cyc & i_wb_stb & ~wb_to_xclk_full;
        end
    end

    // XCLK to WB write enable
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_to_wb_wr_en <= 0;
        end else begin
            xclk_to_wb_wr_en <= i_xclk_ack & ~xclk_to_wb_full;
        end
    end

    // XCLK cycle and strobe generation
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else if (xclk_to_wb_empty) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else begin
            o_xclk_cyc <= 1;
            o_xclk_stb <= ~xclk_to_wb_empty;
        end
    end

    // XCLK write, address, data, and select
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else if (xclk_to_wb_empty) begin
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else if (xclk_to_wb_rd_en) begin
            o_xclk_we <= xclk_to_wb_data[(DW + 1)];
            o_xclk_addr <= xclk_to_wb_data[(DW + 1 + AW - 1):(DW + 2)];
            o_xclk_data <= xclk_to_wb_data[(DW + 1 + AW + DW/8 - 1):(DW + 1 + AW)];
            o_xclk_sel <= xclk_to_wb_data[(DW + 1 + AW + DW/8 + DW - 1):(DW + 1 + AW + DW/8)];
        end
    end

    // XCLK ACK and ERR registration
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_ack_reg <= 0;
            xclk_err_reg <= 0;
        end else begin
            xclk_ack_reg <= i_xclk_ack;
            xclk_err_reg <= i_xclk_err;
        end
    end

    // WB stall signal
    assign o_wb_stall = wb_to_xclk_full;

endmodule

module fifo_async #(
        parameter WIDTH = 32
) (
        input wire i_clk_wr, i_clk_rd,
        input wire i_reset,
        input wire i_wr_en,
        input wire [WIDTH-1:0] i_data,
        output reg i_full,
        output reg i_empty,
        input wire o_rd_en,
        output reg [WIDTH-1:0] o_data
);

    // FIFO parameters
    localparam DEPTH = 1 << LGFIFO;
    localparam ADDR_WIDTH = LGFIFO;

    // FIFO memories
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    // Write pointer logic
    always @(posedge i_clk_wr or posedge i_reset) begin
        if (i_reset) begin
            wr_ptr <= 0;
        end else if (i_wr_en & ~i_full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge i_clk_rd or posedge i_reset) begin
        if (i_reset) begin
            rd_ptr <= 0;
        end else if (o_rd_en & ~i_empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion for pointers
    always @(posedge i_clk_wr or posedge i_reset) begin
        if (i_reset) begin
            wr_ptr_gray <= 0;
        end else begin
            wr_ptr_gray <= bin_to_gray(wr_ptr);
        end
    end

    always @(posedge i_clk_rd or posedge i_reset) begin
        if (i_reset) begin
            rd_ptr_gray <= 0;
        end else begin
            rd_ptr_gray <= bin_to_gray(rd_ptr);
        end
    end

    // Synchronize gray code pointers across clock domains
    always @(posedge i_clk_rd or posedge i_reset) begin
        if (i_reset) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    always @(posedge i_clk_wr or posedge i_reset) begin
        if (i_reset) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // FIFO full and empty flags
    assign i_full = (wr_ptr_gray[ADDR_WIDTH] != wr_ptr_gray_sync[ADDR_WIDTH]) & (wr_ptr_gray[ADDR_WIDTH-1:0] == rd_ptr_gray_sync[ADDR_WIDTH-1:0]);
    assign i_empty = (wr_ptr_gray_sync[ADDR_WIDTH] == rd_ptr_gray[ADDR_WIDTH]) & (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);

    // Write to FIFO memory
    always @(posedge i_clk_wr) begin
        if (i_wr_en & ~i_full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_data;
        end
    end

    // Read from FIFO memory
    always @(posedge i_clk_rd) begin
        if (o_rd_en & ~i_empty) begin
            o_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

endmodule
