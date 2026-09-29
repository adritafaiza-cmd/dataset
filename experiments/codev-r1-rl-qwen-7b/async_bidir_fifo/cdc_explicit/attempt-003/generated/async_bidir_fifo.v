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

    localparam FIFO_DEPTH = 1 << ASIZE;

    // Memory array
    reg [DSIZE-1:0] mem [0:FIFO_DEPTH-1];

    // Pointers and gray codes
    reg [ASIZE:0] wptr_a, rptr_b; // a writes, b reads
    reg [ASIZE:0] wptr_b, rptr_a; // b writes, a reads

    // Gray code conversions
    function [ASIZE:0] bin2gray(input [ASIZE:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Synchronizers
    reg [ASIZE:0] wptr_a_gray, wptr_b_gray;
    reg [ASIZE:0] rptr_a_gray, rptr_b_gray;

    // a_clk domain
    reg [ASIZE:0] rptr_b_sync1, rptr_b_sync2;
    reg [ASIZE:0] wptr_b_sync1, wptr_b_sync2;

    // b_clk domain
    reg [ASIZE:0] rptr_a_sync1, rptr_a_sync2;
    reg [ASIZE:0] wptr_a_sync1, wptr_a_sync2;

    // a_clk domain logic
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            wptr_a <= 0;
            rptr_b_sync1 <= 0;
            rptr_b_sync2 <= 0;
            wptr_b_sync1 <= 0;
            wptr_b_sync2 <= 0;
        end else begin
            // Synchronize read pointers from b_clk
            rptr_b_sync1 <= rptr_b_gray;
            rptr_b_sync2 <= rptr_b_sync1;
            wptr_b_sync1 <= wptr_b_gray;
            wptr_b_sync2 <= wptr_b_sync1;

            // Write logic when a_dir is write (1)
            if (a_dir && a_winc && !a_full) begin
                mem[wptr_a[ASIZE-1:0]] <= a_wdata;
                wptr_a <= wptr_a + 1;
            end

            // Read logic when a_dir is read (0)
            if (!a_dir && a_rinc && !a_empty) begin
                // Read handled by output register
            end
        end
    end

    // b_clk domain logic
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            wptr_b <= 0;
            rptr_a_sync1 <= 0;
            rptr_a_sync2 <= 0;
            wptr_a_sync1 <= 0;
            wptr_a_sync2 <= 0;
        end else begin
            // Synchronize read pointers from a_clk
            rptr_a_sync1 <= rptr_a_gray;
            rptr_a_sync2 <= rptr_a_sync1;
            wptr_a_sync1 <= wptr_a_gray;
            wptr_a_sync2 <= wptr_a_sync1;

            // Write logic when b_dir is write (1)
            if (b_dir && b_winc && !b_full) begin
                mem[wptr_b[ASIZE-1:0]] <= b_wdata;
                wptr_b <= wptr_b + 1;
            end

            // Read logic when b_dir is read (0)
            if (!b_dir && b_rinc && !b_empty) begin
                // Read handled by output register
            end
        end
    end

    // Convert pointers to gray
    always @* begin
        wptr_a_gray = bin2gray(wptr_a);
        wptr_b_gray = bin2gray(wptr_b);
        rptr_b_gray = bin2gray(rptr_b);
        rptr_a_gray = bin2gray(rptr_a);
    end

    // Full and empty calculations
    assign a_full = (wptr_a - rptr_b_sync2) >= FIFO_DEPTH;
    assign a_empty = (wptr_b_sync2 - wptr_a) == 0;

    // Similar for b side

    // Output data registers
    reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
    assign a_rdata = FALLTHROUGH == "TRUE" ? a_rdata_reg : (a_empty ? 0 : a_rdata_reg);
    assign b_rdata = FALLTHROUGH == "TRUE" ? b_rdata_reg : (b_empty ? 0 : b_rdata_reg);

endmodule
