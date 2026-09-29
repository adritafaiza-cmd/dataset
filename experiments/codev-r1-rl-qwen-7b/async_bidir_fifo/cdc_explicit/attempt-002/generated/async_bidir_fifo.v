module async_bidir_fifo #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
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
    input wire              b_dir
);

    reg [DSIZE-1:0] mem [0:(1 << ASIZE)-1];
    reg [ASIZE:0] wptr, rptr;
    reg [ASIZE:0] wptr_gray, rptr_gray;
    reg [ASIZE:0] rptr_gray_sync1, rptr_gray_sync2;
    reg [ASIZE:0] wptr_gray_sync1, wptr_gray_sync2;

    // Convert binary to gray code
    function [ASIZE:0] bin2gray(input [ASIZE:0] bin);
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Convert gray code to binary
    function [ASIZE:0] gray2bin(input [ASIZE:0] gray);
        reg [ASIZE:0] bin;
        integer i;
        begin
            bin[ASIZE] = gray[ASIZE];
            for (i = ASIZE-1; i >= 0; i = i-1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // Write pointer logic
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else begin
            if (a_dir && !a_full && a_winc) begin
                mem[wptr[ASIZE-1:0]] <= a_wdata;
                wptr <= wptr + 1;
                wptr_gray <= bin2gray(wptr + 1);
            end else begin
                wptr_gray <= bin2gray(wptr);
            end
        end
    end

    // Read pointer logic
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else begin
            if (!b_dir && !b_empty && b_rinc) begin
                rptr <= rptr + 1;
                rptr_gray <= bin2gray(rptr + 1);
            end else begin
                rptr_gray <= bin2gray(rptr);
            end
        end
    end

    // Synchronize read pointer to a_clk domain
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Synchronize write pointer to b_clk domain
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Convert synchronized gray pointers to binary
    wire [ASIZE:0] rptr_bin = gray2bin(rptr_gray_sync2);
    wire [ASIZE:0] wptr_bin = gray2bin(wptr_gray_sync2);

    // Full and empty conditions
    assign a_full = ((wptr - rptr_bin) >= (1 << ASIZE));
    assign a_empty = (rptr_bin == wptr_bin);

    assign b_full = ((wptr_bin - rptr) >= (1 << ASIZE));
    assign b_empty = (wptr_bin == rptr);

    // Almost full and almost empty (example thresholds)
    assign a_afull = ((wptr - rptr_bin) >= ((1 << ASIZE) - 1));
    assign a_aempty = ((wptr_bin - rptr) <= 1);

    assign b_afull = ((wptr_bin - rptr) >= ((1 << ASIZE) - 1));
    assign b_aempty = ((rptr - wptr_bin) <= 1);

    // Read data outputs
    assign a_rdata = mem[rptr[ASIZE-1:0]];
    assign b_rdata = mem[wptr[ASIZE-1:0]];

endmodule
