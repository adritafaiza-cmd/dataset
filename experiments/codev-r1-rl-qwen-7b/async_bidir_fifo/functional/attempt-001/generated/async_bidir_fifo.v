module async_bidir_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE"
) (
    // a side
    input wire a_clk,
    input wire a_rst_n,
    input wire a_winc,
    input wire [DSIZE-1:0] a_wdata,
    input wire a_rinc,
    output wire [DSIZE-1:0] a_rdata,
    output wire a_full,
    output wire a_afull,
    output wire a_empty,
    output wire a_aempty,
    input wire a_dir,

    // b side
    input wire b_clk,
    input wire b_rst_n,
    input wire b_winc,
    input wire [DSIZE-1:0] b_wdata,
    input wire b_rinc,
    output wire [DSIZE-1:0] b_rdata,
    output wire b_full,
    output wire b_afull,
    output wire b_empty,
    output wire b_aempty,
    input wire b_dir
);

    // Memory declaration
    reg [DSIZE-1:0] mem [0:(1 << ASIZE)-1];

    // Pointers
    reg [ASIZE:0] a_wptr, a_rptr; // binary pointers
    reg [ASIZE:0] b_wptr, b_rptr;

    // Gray code pointers for synchronization
    reg [ASIZE:0] a_wptr_gray, a_rptr_gray;
    reg [ASIZE:0] b_wptr_gray, b_rptr_gray;

    // Synchronization registers
    // a_clk domain synchronization of b's pointers
    reg [ASIZE:0] b_wptr_gray_sync_a0, b_wptr_gray_sync_a1;
    reg [ASIZE:0] b_rptr_gray_sync_a0, b_rptr_gray_sync_a1;

    // b_clk domain synchronization of a's pointers
    reg [ASIZE:0] a_wptr_gray_sync_b0, a_wptr_gray_sync_b1;
    reg [ASIZE:0] a_rptr_gray_sync_b0, a_rptr_gray_sync_b1;

    // Convert Gray to binary
    function [ASIZE:0] gray2bin;
        input [ASIZE:0] gray;
        reg [ASIZE:0] bin;
        integer i;
        begin
            bin[ASIZE] = gray[ASIZE];
            for (i = ASIZE-1; i >= 0; i = i-1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // Function to convert binary to Gray code
    function [ASIZE:0] bin2gray;
        input [ASIZE:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // a_clk domain logic
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wptr <= 0;
            a_rptr <= 0;
            a_wptr_gray <= 0;
            a_rptr_gray <= 0;
        end else begin
            // Update write pointer
            if (a_dir && a_winc && !a_full) begin
                mem[a_wptr[ASIZE-1:0]] <= a_wdata;
                a_wptr <= a_wptr + 1;
            end
            // Update read pointer
            if (!a_dir && a_rinc && !a_empty) begin
                a_rdata <= mem[a_rptr[ASIZE-1:0]];
                a_rptr <= a_rptr + 1;
            end
            // Update Gray pointers
            a_wptr_gray <= bin2gray(a_wptr);
            a_rptr_gray <= bin2gray(a_rptr);
        end
    end

    // Synchronize b's pointers to a_clk domain
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            b_wptr_gray_sync_a0 <= 0;
            b_wptr_gray_sync_a1 <= 0;
            b_rptr_gray_sync_a0 <= 0;
            b_rptr_gray_sync_a1 <= 0;
        end else begin
            b_wptr_gray_sync_a0 <= b_wptr_gray;
            b_wptr_gray_sync_a1 <= b_wptr_gray_sync_a0;
            b_rptr_gray_sync_a0 <= b_rptr_gray;
            b_rptr_gray_sync_a1 <= b_rptr_gray_sync_a0;
        end
    end

    // Convert synchronized Gray pointers to binary
    wire [ASIZE:0] b_wptr_sync_a = gray2bin(b_wptr_gray_sync_a1);
    wire [ASIZE:0] b_rptr_sync_a = gray2bin(b_rptr_gray_sync_a1);

    // Compute a_full and a_empty
    wire [ASIZE+1:0] a_wm = a_wptr + b_wptr_sync_a;
    wire [ASIZE+1:0] a_rm = a_rptr + b_rptr_sync_a;
    assign a_full = (a_wm - a_rm) >= (1 << ASIZE);
    assign a_empty = (a_rm >= a_wm);

    // Similar for b side

    // b_clk domain logic
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wptr <= 0;
            b_rptr <= 0;
            b_wptr_gray <= 0;
            b_rptr_gray <= 0;
        end else begin
            // Update write pointer
            if (b_dir && b_winc && !b_full) begin
                mem[b_wptr[ASIZE-1:0]] <= b_wdata;
                b_wptr <= b_wptr + 1;
            end
            // Update read pointer
            if (!b_dir && b_rinc && !b_empty) begin
                b_rdata <= mem[b_rptr[ASIZE-1:0]];
                b_rptr <= b_rptr + 1;
            end
            // Update Gray pointers
            b_wptr_gray <= bin2gray(b_wptr);
            b_rptr_gray <= bin2gray(b_rptr);
        end
    end

    // Synchronize a's pointers to b_clk domain
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            a_wptr_gray_sync_b0 <= 0;
            a_wptr_gray_sync_b1 <= 0;
            a_rptr_gray_sync_b0 <= 0;
            a_rptr_gray_sync_b1 <= 0;
        end else begin
            a_wptr_gray_sync_b0 <= a_wptr_gray;
            a_wptr_gray_sync_b1 <= a_wptr_gray_sync_b0;
            a_rptr_gray_sync_b0 <= a_rptr_gray;
            a_rptr_gray_sync_b1 <= a_rptr_gray_sync_b0;
        end
    end

    // Convert synchronized Gray pointers to binary
    wire [ASIZE:0] a_wptr_sync_b = gray2bin(a_wptr_gray_sync_b1);
    wire [ASIZE:0] a_rptr_sync_b = gray2bin(a_rptr_gray_sync_b1);

    // Compute b_full and b_empty
    wire [ASIZE+1:0] b_wm = b_wptr + a_wptr_sync_b;
    wire [ASIZE+1:0] b_rm = b_rptr + a_rptr_sync_b;
    assign b_full = (b_wm - b_rm) >= (1 << ASIZE);
    assign b_empty = (b_rm >= b_wm);

    // Almost full/empty (assuming threshold is 1 entry less)
    assign a_afull = (a_wm - a_rm) >= ( (1 << ASIZE) - 1 );
    assign a_aempty = (a_rm >= a_wm + 1);

    assign b_afull = (b_wm - b_rm) >= ( (1 << ASIZE) - 1 );
    assign b_aempty = (b_rm >= b_wm + 1);

endmodule
