module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    localparam AWIDTH = ASIZE + 1;
    localparam DEPTH  = 1 << ASIZE;

    // Write domain
    reg  [AWIDTH-1:0] wptr;
    reg  [AWIDTH-1:0] wptr_gray;
    reg  [AWIDTH-1:0] rptr_gray_w;
    reg  [AWIDTH-1:0] rptr_gray_w_d1;
    reg  [AWIDTH-1:0] rptr_gray_w_d2;

    // Read domain
    reg  [AWIDTH-1:0] rptr;
    reg  [AWIDTH-1:0] rptr_gray;
    reg  [AWIDTH-1:0] wptr_gray_r;
    reg  [AWIDTH-1:0] wptr_gray_r_d1;
    reg  [AWIDTH-1:0] wptr_gray_r_d2;

    // Memory
    reg  [DSIZE-1:0] mem [0:DEPTH-1];

    // Gray code conversion
    function [AWIDTH-1:0] bin2gray;
        input [AWIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr      <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
        end else if (winc && !wfull) begin
            wptr      <= wptr + 1'b1;
            wptr_gray <= bin2gray(wptr + 1'b1);
        end
    end

    // Synchronize read pointer gray into write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w  <= {AWIDTH{1'b0}};
            rptr_gray_w_d1 <= {AWIDTH{1'b0}};
            rptr_gray_w_d2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_gray_w  <= rptr_gray;
            rptr_gray_w_d1 <= rptr_gray_w;
            rptr_gray_w_d2 <= rptr_gray_w_d1;
        end
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr      <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
        end else if (rinc && !rempty) begin
            rptr      <= rptr + 1'b1;
            rptr_gray <= bin2gray(rptr + 1'b1);
        end
    end

    // Synchronize write pointer gray into read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r  <= {AWIDTH{1'b0}};
            wptr_gray_r_d1 <= {AWIDTH{1'b0}};
            wptr_gray_r_d2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_gray_r  <= wptr_gray;
            wptr_gray_r_d1 <= wptr_gray_r;
            wptr_gray_r_d2 <= wptr_gray_r_d1;
        end
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Memory read
    reg  [DSIZE-1:0] rdata_reg;
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata_reg <= mem[rptr[ASIZE-1:0]];
        end
    end

    assign rdata = rdata_reg;

    // Full/empty generation
    // Write domain: compare wptr_gray with synchronized rptr_gray
    wire [AWIDTH-1:0] wptr_gray_w = wptr_gray;
    wire [AWIDTH-1:0] rptr_gray_w_sync = rptr_gray_w_d2;

    // Full: wptr_gray MSB and next-highest differ from rptr_gray, rest same
    wire wfull_internal = (wptr_gray_w == {~rptr_gray_w_sync[AWIDTH-1:AWIDTH-2], rptr_gray_w_sync[AWIDTH-3:0]});
    wire awfull_internal = (wptr_gray_w == {~rptr_gray_w_sync[AWIDTH-1:AWIDTH-2], rptr_gray_w_sync[AWIDTH-3:0]}) ||
                           (wptr_gray_w == {~rptr_gray_w_sync[AWIDTH-1:AWIDTH-2], rptr_gray_w_sync[AWIDTH-3:0]});
    // awfull: one less than full, i.e., DEPTH-1 entries
    // For simplicity, awfull = full or (wptr - rptr == DEPTH-1)
    // Let's compute properly:
    wire [AWIDTH-1:0] wptr_bin_w = wptr;
    wire [AWIDTH-1:0] rptr_bin_w = rptr_gray_w_d2 ^ (rptr_gray_w_d2 >> 1); // gray to bin
    // Actually, let's just use the standard approach:
    // full when wptr_gray == {~rptr_gray[MSB:MSB-1], rptr_gray[MSB-2:0]}
    // awfull when count == DEPTH-1

    // Read domain: compare rptr_gray with synchronized wptr_gray
    wire [AWIDTH-1:0] rptr_gray_r = rptr_gray;
    wire [AWIDTH-1:0] wptr_gray_r_sync = wptr_gray_r_d2;

    // Empty: rptr_gray == wptr_gray
    wire rempty_internal = (rptr_gray_r == wptr_gray_r_sync);
    wire arempty_internal = (rptr_gray_r == wptr_gray_r_sync) ||
                            (rptr_gray_r == {wptr_gray_r_sync[AWIDTH-1:AWIDTH-2], ~wptr_gray_r_sync[AWIDTH-3:0]});
    // arempty: empty or one entry

    // Let me redo the full/empty logic more carefully.
    // Standard CDC FIFO:
    // full: wptr_gray[MSB:MSB-1] != rptr_gray[MSB:MSB-1] && wptr_gray[MSB-2:0] == rptr_gray[MSB-2:0]
    // empty: wptr_gray == rptr_gray

    // Write domain full
    wire wfull_w = (wptr_gray_w[AWIDTH-1:AWIDTH-2] != rptr_gray_w_sync[AWIDTH-1:AWIDTH-2]) &&
                   (wptr_gray_w[AWIDTH-3:0] == rptr_gray_w_sync[AWIDTH-3:0]);

    // Write domain awfull (DEPTH-1 entries)
    // This is trickier. Let's compute the difference.
    // For now, let's use a simpler approach: awfull = wfull || (count == DEPTH-1)
    // We can compute count in write domain by converting gray to binary.
    wire [AWIDTH-1:0] rptr_bin_w = rptr_gray_w_d2 ^ (rptr_gray_w_d2 >> 1);
    wire [AWIDTH-1:0] wptr_bin_w = wptr;
    wire [AWIDTH-1:0] count_w = wptr_bin_w - rptr_bin_w;
    wire awfull_w = (count_w == DEPTH - 1);

    // Read domain empty
    wire rempty_r = (rptr_gray_r == wptr_gray_r_sync);

    // Read domain arempty (1 entry)
    wire [AWIDTH-1:0] wptr_bin_r = wptr_gray_r_d2 ^ (wptr_gray_r_d2 >> 1);
    wire [AWIDTH-1:0] rptr_bin_r = rptr;
    wire [AWIDTH-1:0] count_r = wptr_bin_r - rptr_bin_r;
    wire arempty_r = (count_r == 1);

    assign wfull   = wfull_w;
    assign awfull  = awfull_w;
    assign rempty  = rempty_r;
    assign arempty = arempty_r;

endmodule
