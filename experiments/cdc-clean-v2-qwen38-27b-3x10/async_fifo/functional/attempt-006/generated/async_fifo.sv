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

    localparam DEPTH = 1 << ASIZE;
    localparam AWIDTH = ASIZE + 1;
    localparam FULL_THRESHOLD = DEPTH - 1;
    localparam EMPTY_THRESHOLD = 1;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [AWIDTH-1:0] rptr_w;
    reg [AWIDTH-1:0] rptr_w_sync1;
    reg [AWIDTH-1:0] rptr_w_sync2;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [AWIDTH-1:0] wptr_r;
    reg [AWIDTH-1:0] wptr_r_sync1;
    reg [AWIDTH-1:0] wptr_r_sync2;

    // Read data register for fall-through
    reg [DSIZE-1:0] rdata_reg;
    reg             rdata_valid;

    // Write enable
    wire winc_eff = winc & ~wfull;

    // Read enable
    wire rinc_eff = rinc & ~rempty;

    // Full condition: write pointer has lapped read pointer by DEPTH
    // wptr and rptr_w are AWIDTH bits. Full when upper bits differ and lower bits equal.
    wire wfull = (wptr[ASIZE] != rptr_w[ASIZE]) && (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]);

    // Almost full: one more write would make it full
    wire awfull = (wptr[ASIZE-1:0] == (rptr_w[ASIZE-1:0] + ASIZE'(FULL_THRESHOLD - 1))) ||
                  (wptr[ASIZE-1:0] == (rptr_w[ASIZE-1:0] + ASIZE'(FULL_THRESHOLD - 1)) - 1) ||
                  (wptr[ASIZE-1:0] == (rptr_w[ASIZE-1:0] + ASIZE'(FULL_THRESHOLD - 1)) - 2);
    // Simpler: awfull when distance to full is 1
    // Distance = (rptr_w - wptr) mod DEPTH. Full when distance == 0 (with wrap bit).
    // Let's use a cleaner approach.

    // Actually, let me redefine awfull properly.
    // The number of entries = (rptr_w - wptr) mod DEPTH, but with the extra bit for full/empty distinction.
    // Full: wptr[ASIZE] != rptr_w[ASIZE] && wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]
    // Almost full: one write away from full.
    // That means (wptr + 1) would be full.
    // wptr + 1 full: ((wptr+1)[ASIZE] != rptr_w[ASIZE]) && ((wptr+1)[ASIZE-1:0] == rptr_w[ASIZE-1:0])
    // This is equivalent to: wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0] - 1 (mod DEPTH) with appropriate wrap bit.
    // Let's just compute: awfull = wfull_next where wfull_next is full if we wrote one more.
    wire [AWIDTH-1:0] wptr_next = wptr + AWIDTH'(1);
    wire awfull = (wptr_next[ASIZE] != rptr_w[ASIZE]) && (wptr_next[ASIZE-1:0] == rptr_w[ASIZE-1:0]);

    // Empty condition: read pointer equals write pointer (both bits)
    wire rempty = (rptr == wptr_r);

    // Almost empty: one read away from empty
    wire [AWIDTH-1:0] rptr_next = rptr + AWIDTH'(1);
    wire arempty = (rptr_next == wptr_r);

    // Write memory
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
        end else if (winc_eff) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
            wptr <= wptr + AWIDTH'(1);
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_w_sync1 <= {AWIDTH{1'b0}};
            rptr_w_sync2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_w_sync1 <= rptr;
            rptr_w_sync2 <= rptr_w_sync1;
        end
    end
    assign rptr_w = rptr_w_sync2;

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_r_sync1 <= {AWIDTH{1'b0}};
            wptr_r_sync2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_r_sync1 <= wptr;
            wptr_r_sync2 <= wptr_r_sync1;
        end
    end
    assign wptr_r = wptr_r_sync2;

    // Read data and pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rdata_reg <= {DSIZE{1'b0}};
            rdata_valid <= 1'b0;
        end else begin
            if (rinc_eff) begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
                rdata_valid <= 1'b1;
                rptr <= rptr + AWIDTH'(1);
            end
        end
    end

    // Fall-through: rdata presents current oldest unread word once rempty falls
    // When FALLTHROUGH is TRUE, rdata is combinational from memory when not empty,
    // but the spec says "FALLTHROUGH does not select a combinational memory read."
    // So we use a registered approach. Let me re-read.
    // "rdata presents the current oldest unread word once rempty falls, without requiring an additional accepted read."
    // "rdata is one read-clock sample."
    // This suggests rdata is registered, updated on read clock, showing the head of FIFO.
    // When a write makes the FIFO non-empty, on the next rclk edge, rdata should show that word.
    // But we can't read memory combinationally. So we need to track the head.
    // Actually, the simplest interpretation: rdata is the data at rptr, registered.
    // We update rdata_reg whenever rptr changes or when a new word becomes available.
    // But since rptr only changes on accepted reads, and new words appear via wptr_r sync,
    // we can update rdata_reg when rempty transitions from 1 to 0, or on read.
    // Let's use: if rempty was high and now low, load mem[rptr]. If rinc_eff, load mem[rptr] and advance.
    // But we need to know when rempty transitions. Let's track previous rempty.

    reg rempty_prev;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rempty_prev <= 1'b1;
        else
            rempty_prev <= rempty;
    end

    wire rempty_fall = rempty_prev & ~rempty;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
        end else begin
            if (rinc_eff) begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
            end else if (rempty_fall) begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
            end
        end
    end

    assign rdata = rdata_reg;

endmodule
