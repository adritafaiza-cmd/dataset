module async_bidir_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE"
) (
    // a side
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

    // b side
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

    localparam PTRSIZE = ASIZE + 1;

    // Memory declaration
    reg [DSIZE-1:0] mem [0:(1 << ASIZE)-1];

    // Pointers
    reg [PTRSIZE-1:0] a_wptr_bin, a_rptr_bin;
    reg [PTRSIZE-1:0] b_wptr_bin, b_rptr_bin;

    // Gray code pointers
    wire [PTRSIZE-1:0] a_wptr_gray = a_wptr_bin ^ (a_wptr_bin >> 1);
    wire [PTRSIZE-1:0] a_rptr_gray = a_rptr_bin ^ (a_rptr_bin >> 1);
    wire [PTRSIZE-1:0] b_wptr_gray = b_wptr_bin ^ (b_wptr_bin >> 1);
    wire [PTRSIZE-1:0] b_rptr_gray = b_rptr_bin ^ (b_rptr_bin >> 1);

    // Synchronization registers
    reg [PTRSIZE-1:0] a_wptr_gray_sync1, a_wptr_gray_sync2;
    reg [PTRSIZE-1:0] a_rptr_gray_sync1, a_rptr_gray_sync2;
    reg [PTRSIZE-1:0] b_wptr_gray_sync1, b_wptr_gray_sync2;
    reg [PTRSIZE-1:0] b_rptr_gray_sync1, b_rptr_gray_sync2;

    // Convert Gray to binary
    function [PTRSIZE-1:0] gray2bin;
        input [PTRSIZE-1:0] gray;
        integer i;
        begin
            gray2bin[PTRSIZE-1] = gray[PTRSIZE-1];
            for (i = PTRSIZE-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // a side logic
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wptr_bin <= 0;
            a_rptr_bin <= 0;
        end else begin
            if (a_dir) begin // Write
                if (a_winc && !a_full) begin
                    mem[a_wptr_bin[ASIZE-1:0]] <= a_wdata;
                    a_wptr_bin <= a_wptr_bin + 1;
                end
            end else begin // Read
                if (a_rinc && !a_empty) begin
                    a_rptr_bin <= a_rptr_bin + 1;
                end
            end
        end
    end

    // b side logic
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wptr_bin <= 0;
            b_rptr_bin <= 0;
        end else begin
            if (b_dir) begin // Write
                if (b_winc && !b_full) begin
                    mem[b_wptr_bin[ASIZE-1:0]] <= b_wdata;
                    b_wptr_bin <= b_wptr_bin + 1;
                end
            end else begin // Read
                if (b_rinc && !b_empty) begin
                    b_rptr_bin <= b_rptr_bin + 1;
                end
            end
        end
    end

    // Synchronize pointers across domains
    // a_wptr_gray to b_clk domain
    always @(posedge b_clk) begin
        a_wptr_gray_sync1 <= a_wptr_gray;
        a_wptr_gray_sync2 <= a_wptr_gray_sync1;
    end

    // a_rptr_gray to b_clk domain
    always @(posedge b_clk) begin
        a_rptr_gray_sync1 <= a_rptr_gray;
        a_rptr_gray_sync2 <= a_rptr_gray_sync1;
    end

    // b_wptr_gray to a_clk domain
    always @(posedge a_clk) begin
        b_wptr_gray_sync1 <= b_wptr_gray;
        b_wptr_gray_sync2 <= b_wptr_gray_sync1;
    end

    // b_rptr_gray to a_clk domain
    always @(posedge a_clk) begin
        b_rptr_gray_sync1 <= b_rptr_gray;
        b_rptr_gray_sync2 <= b_rptr_gray_sync1;
    end

    // Convert synchronized Gray to binary
    wire [PTRSIZE-1:0] a_wptr_bin_sync = gray2bin(a_wptr_gray_sync2);
    wire [PTRSIZE-1:0] a_rptr_bin_sync = gray2bin(a_rptr_gray_sync2);
    wire [PTRSIZE-1:0] b_wptr_bin_sync = gray2bin(b_wptr_gray_sync2);
    wire [PTRSIZE-1:0] b_rptr_bin_sync = gray2bin(b_rptr_gray_sync2);

    // Calculate entries
    wire [PTRSIZE-1:0] a_entries = a_wptr_bin - a_rptr_bin_sync;
    wire [PTRSIZE-1:0] b_entries = b_wptr_bin_sync - b_rptr_bin;

    // Flags
    assign a_full = (a_entries >= (1 << ASIZE));
    assign a_empty = (a_entries == 0);
    assign b_full = (b_entries >= (1 << ASIZE));
    assign b_empty = (b_entries == 0);

    // Almost full/empty (example with threshold 1)
    assign a_afull = (a_entries >= (1 << ASIZE) - 1);
    assign a_aempty = (a_entries <= 1);
    assign b_afull = (b_entries >= (1 << ASIZE) - 1);
    assign b_aempty = (b_entries <= 1);

    // Read data
    assign a_rdata = mem[a_rptr_bin[ASIZE-1:0]];
    assign b_rdata = mem[b_rptr_bin[ASIZE-1:0]];

endmodule
