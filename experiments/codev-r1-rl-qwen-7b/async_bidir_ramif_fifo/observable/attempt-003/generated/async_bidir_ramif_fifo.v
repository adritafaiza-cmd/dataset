module async_bidir_ramif_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "FALSE"
) (
    input wire              a_clk,
    input wire              a_rst_n,
    input wire              a_winc,
    input wire [DSIZE-1:0]  a_wdata,
    input wire              a_rinc,
    output wire [DSIZE-1:0] a_rdata,
    output wire             a_full,
    output wire             a_afull,
    output wire             a_empty,
    output wire             a_aempty,
    input wire              a_dir,
    input wire              b_clk,
    input wire              b_rst_n,
    input wire              b_winc,
    input wire [DSIZE-1:0]  b_wdata,
    input wire              b_rinc,
    output wire [DSIZE-1:0] b_rdata,
    output wire             b_full,
    output wire             b_afull,
    output wire             b_empty,
    output wire             b_aempty,
    input wire              b_dir,
    output wire             o_ram_a_clk,
    output wire [DSIZE-1:0] o_ram_a_wdata,
    input wire [DSIZE-1:0]  i_ram_a_rdata,
    output wire [ASIZE-1:0] o_ram_a_addr,
    output wire             o_ram_a_rinc,
    output wire             o_ram_a_winc,
    output wire             o_ram_b_clk,
    output wire [DSIZE-1:0] o_ram_b_wdata,
    input wire [DSIZE-1:0]  i_ram_b_rdata,
    output wire [ASIZE-1:0] o_ram_b_addr,
    output wire             o_ram_b_rinc,
    output wire             o_ram_b_winc
);

    // FIFO A to B (A writes, B reads)
    reg [ASIZE:0] a2b_wptr, a2b_rptr;
    reg [ASIZE:0] a2b_wptr_gray, a2b_rptr_gray;
    reg [ASIZE:0] a2b_rptr_gray_sync1, a2b_rptr_gray_sync2;
    wire a2b_full, a2b_empty;
    wire a2b_wen, a2b_ren;

    // FIFO B to A (B writes, A reads)
    reg [ASIZE:0] b2a_wptr, b2a_rptr;
    reg [ASIZE:0] b2a_wptr_gray, b2a_rptr_gray;
    reg [ASIZE:0] b2a_rptr_gray_sync1, b2a_rptr_gray_sync2;
    wire b2a_full, b2a_empty;
    wire b2a_wen, b2a_ren;

    // A to B FIFO
    assign a2b_wen = a_dir && a_winc && !a2b_full;
    assign a2b_ren = b_dir && b_rinc && !a2b_empty;

    // B to A FIFO
    assign b2a_wen = b_dir && b_winc && !b2a_full;
    assign b2a_ren = a_dir && a_rinc && !b2a_empty;

    // A to B FIFO pointers and CDC
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a2b_wptr <= 0;
            a2b_wptr_gray <= 0;
        end else if (a2b_wen) begin
            a2b_wptr <= a2b_wptr + 1;
            a2b_wptr_gray <= (a2b_wptr + 1) ^ ((a2b_wptr + 1) >> 1);
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a2b_rptr_gray_sync1 <= 0;
            a2b_rptr_gray_sync2 <= 0;
        end else begin
            a2b_rptr_gray_sync1 <= a2b_rptr_gray;
            a2b_rptr_gray_sync2 <= a2b_rptr_gray_sync1;
        end
    end

    assign a2b_full = (a2b_wptr_gray == {~a2b_rptr_gray_sync2[ASIZE:ASIZE-1], a2b_rptr_gray_sync2[ASIZE-2:0]});
    assign a2b_empty = (a2b_wptr_gray == a2b_rptr_gray_sync2);

    // B to A FIFO pointers and CDC
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b2a_wptr <= 0;
            b2a_wptr_gray <= 0;
        end else if (b2a_wen) begin
            b2a_wptr <= b2a_wptr + 1;
            b2a_wptr_gray <= (b2a_wptr + 1) ^ ((b2a_wptr + 1) >> 1);
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b2a_rptr_gray_sync1 <= 0;
            b2a_rptr_gray_sync2 <= 0;
        end else begin
            b2a_rptr_gray_sync1 <= b2a_rptr_gray;
            b2a_rptr_gray_sync2 <= b2a_rptr_gray_sync1;
        end
    end

    assign b2a_full = (b2a_wptr_gray == {~b2a_rptr_gray_sync2[ASIZE:ASIZE-1], b2a_rptr_gray_sync2[ASIZE-2:0]});
    assign b2a_empty = (b2a_wptr_gray == b2a_rptr_gray_sync2);

    // A to B FIFO read pointer
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            a2b_rptr <= 0;
            a2b_rptr_gray <= 0;
        end else if (a2b_ren) begin
            a2b_rptr <= a2b_rptr + 1;
            a2b_rptr_gray <= (a2b_rptr + 1) ^ ((a2b_rptr + 1) >> 1);
        end
    end

    // B to A FIFO read pointer
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            b2a_rptr <= 0;
            b2a_rptr_gray <= 0;
        end else if (b2a_ren) begin
            b2a_rptr <= b2a_rptr + 1;
            b2a_rptr_gray <= (b2a_rptr + 1) ^ ((b2a_rptr + 1) >> 1);
        end
    end

    // Almost full/empty calculations
    assign a_afull = (a2b_wptr - a2b_rptr) >= (2**ASIZE - 2);
    assign a_aempty = (a2b_wptr - a2b_rptr) <= 1;
    assign b_afull = (b2a_wptr - b2a_rptr) >= (2**ASIZE - 2);
    assign b_aempty = (b2a_wptr - b2a_rptr) <= 1;

    // Output assignments
    assign a_full = a2b_full;
    assign a_empty = a2b_empty;
    assign b_full = b2a_full;
    assign b_empty = b2a_empty;

    assign a_rdata = i_ram_b_rdata;
    assign b_rdata = i_ram_a_rdata;

    // RAM interface assignments
    assign o_ram_a_clk = a_clk;
    assign o_ram_a_wdata = a_wdata;
    assign o_ram_a_addr = a2b_wptr[ASIZE-1:0];
    assign o_ram_a_winc = a2b_wen;
    assign o_ram_a_rinc = a2b_ren;

    assign o_ram_b_clk = b_clk;
    assign o_ram_b_wdata = b_wdata;
    assign o_ram_b_addr = b2a_wptr[ASIZE-1:0];
    assign o_ram_b_winc = b2a_wen;
    assign o_ram_b_rinc = b2a_ren;

endmodule
