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

    wire [AWIDTH-1:0] wptr;
    wire [AWIDTH-1:0] rptr;

    wire [AWIDTH-1:0] rptr_w;
    wire [AWIDTH-1:0] wptr_r;

    wire winc_eff;
    wire rinc_eff;

    wire wfull_int;
    wire rempty_int;

    wire [DSIZE-1:0] mem [0:DEPTH-1];

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {AWIDTH{1'b0}};
        else if (winc && !wfull_int)
            wptr <= wptr + 1'b1;
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {AWIDTH{1'b0}};
        else if (rinc && !rempty_int)
            rptr <= rptr + 1'b1;
    end

    // CDC: rptr to write domain
    wire [AWIDTH-1:0] rptr_sync1;
    wire [AWIDTH-1:0] rptr_sync2;
    wire [AWIDTH-1:0] rptr_sync3;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync1 <= {AWIDTH{1'b0}};
            rptr_sync2 <= {AWIDTH{1'b0}};
            rptr_sync3 <= {AWIDTH{1'b0}};
        end else begin
            rptr_sync1 <= rptr;
            rptr_sync2 <= rptr_sync1;
            rptr_sync3 <= rptr_sync2;
        end
    end

    assign rptr_w = rptr_sync3;

    // CDC: wptr to read domain
    wire [AWIDTH-1:0] wptr_sync1;
    wire [AWIDTH-1:0] wptr_sync2;
    wire [AWIDTH-1:0] wptr_sync3;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync1 <= {AWIDTH{1'b0}};
            wptr_sync2 <= {AWIDTH{1'b0}};
            wptr_sync3 <= {AWIDTH{1'b0}};
        end else begin
            wptr_sync1 <= wptr;
            wptr_sync2 <= wptr_sync1;
            wptr_sync3 <= wptr_sync2;
        end
    end

    assign wptr_r = wptr_sync3;

    // Full/Empty logic
    // Full: write pointer has lapped read pointer by DEPTH
    // In the extended pointer space, full when wptr[ASIZE:1] == rptr[ASIZE:1] && wptr[0] != rptr[0]
    // More precisely: full when (wptr - rptr) == DEPTH
    // Using the standard Gray code approach or binary comparison:
    // wfull when wptr[ASIZE:1] == rptr_w[ASIZE:1] && wptr[0] != rptr_w[0]
    // Actually, the standard check for full in binary pointers with extra bit:
    // full when wptr[ASIZE:1] == rptr_w[ASIZE:1] && wptr[0] != rptr_w[0]
    // This works because the pointers are in a space of 2*DEPTH, and full means they differ by exactly DEPTH.

    assign wfull_int = (wptr[ASIZE:1] == rptr_w[ASIZE:1]) && (wptr[0] != rptr_w[0]);
    assign rempty_int = (wptr_r == rptr);

    // Almost full: one entry away from full
    // awfull when (wptr - rptr_w) == DEPTH - 1
    // This is when wptr[ASIZE:1] == rptr_w[ASIZE:1] && wptr[0] == rptr_w[0] is NOT the case...
    // Let's think: full is diff == DEPTH. Almost full is diff == DEPTH - 1.
    // diff = wptr - rptr_w (mod 2*DEPTH)
    // awfull when diff == DEPTH - 1
    // This means wptr[ASIZE:1] == rptr_w[ASIZE:1] + 1 (mod 2^ASIZE) and wptr[0] == rptr_w[0] - 1 (mod 2)
    // Or more simply: awfull when (wptr + 1) would be full, i.e., (wptr + 1)[ASIZE:1] == rptr_w[ASIZE:1] && (wptr + 1)[0] != rptr_w[0]
    // Let's use: awfull = wfull_int || ((wptr[ASIZE:1] == rptr_w[ASIZE:1]) && (wptr[0] == rptr_w[0]) && (wptr[0] == 1'b1))
    // Hmm, let me reconsider.
    
    // diff = wptr - rptr_w
    // full: diff == DEPTH
    // awfull: diff == DEPTH - 1
    
    // DEPTH = 2^ASIZE
    // diff == DEPTH means wptr[ASIZE:1] == rptr_w[ASIZE:1] and wptr[0] != rptr_w[0] (specifically wptr[0]=1, rptr_w[0]=0)
    // diff == DEPTH - 1 means wptr[ASIZE:1] == rptr_w[ASIZE:1] and wptr[0] == rptr_w[0] and wptr[0] == 1
    // Wait, that's not right either. Let me use a different approach.
    
    // awfull when the number of entries is DEPTH - 1
    // entries = wptr - rptr_w (mod 2*DEPTH)
    // awfull when entries == DEPTH - 1
    
    // Let's compute entries and compare
    wire [AWIDTH-1:0] entries_w;
    assign entries_w = wptr - rptr_w;
    
    assign awfull = (entries_w == FULL_THRESHOLD);

    // Almost empty: one entry away from empty
    // arempty when entries == 1
    wire [AWIDTH-1:0] entries_r;
    assign entries_r = wptr_r - rptr;
    
    assign arempty = (entries_r == EMPTY_THRESHOLD);

    // Memory write
    assign winc_eff = winc && !wfull_int;
    
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Memory read
    assign rinc_eff = rinc && !rempty_int;
    
    // For fall-through mode, rdata is the data at the current read pointer
    // For non-fall-through, rdata is registered
    wire [ASIZE-1:0] raddr;
    assign raddr = rptr[ASIZE-1:0];

    wire [DSIZE-1:0] mem_rdata;
    assign mem_rdata = mem[raddr];

    reg [DSIZE-1:0] rdata_reg;
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata_reg <= {DSIZE{1'b0}};
        else if (rinc_eff)
            rdata_reg <= mem_rdata;
    end

    assign rdata = (FALLTHROUGH == "TRUE") ? mem_rdata : rdata_reg;

    // Outputs
    assign wfull = wfull_int;
    assign rempty = rempty_int;

endmodule
