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
    localparam FULL_THRESH = DEPTH - 1;
    localparam EMPTY_THRESH = 1;

    wire [AWIDTH-1:0] wptr;
    wire [AWIDTH-1:0] rptr;

    wire winc_eff;
    wire rinc_eff;

    assign winc_eff = winc & ~wfull;
    assign rinc_eff = rinc & ~rempty;

    // Write pointer
    reg [AWIDTH-1:0] wptr_reg;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr_reg <= {AWIDTH{1'b0}};
        else if (winc_eff)
            wptr_reg <= wptr_reg + 1'b1;
    end
    assign wptr = wptr_reg;

    // Read pointer
    reg [AWIDTH-1:0] rptr_reg;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr_reg <= {AWIDTH{1'b0}};
        else if (rinc_eff)
            rptr_reg <= rptr_reg + 1'b1;
    end
    assign rptr = rptr_reg;

    // Synchronize read pointer to write domain
    reg [AWIDTH-1:0] rptr_sync1;
    reg [AWIDTH-1:0] rptr_sync2;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync1 <= {AWIDTH{1'b0}};
            rptr_sync2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_sync1 <= rptr;
            rptr_sync2 <= rptr_sync1;
        end
    end

    // Synchronize write pointer to read domain
    reg [AWIDTH-1:0] wptr_sync1;
    reg [AWIDTH-1:0] wptr_sync2;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync1 <= {AWIDTH{1'b0}};
            wptr_sync2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_sync1 <= wptr;
            wptr_sync2 <= wptr_sync1;
        end
    end

    // Full and empty detection
    wire wfull_int;
    wire rempty_int;

    assign wfull_int = (wptr[ASIZE-1:0] == rptr_sync2[ASIZE-1:0]) &&
                       (wptr[ASIZE] != rptr_sync2[ASIZE]);

    assign rempty_int = (wptr_sync2 == rptr);

    assign wfull = wfull_int;
    assign rempty = rempty_int;

    // Almost full: DEPTH - 1 entries
    wire [AWIDTH-1:0] wfull_thresh;
    assign wfull_thresh = wptr - rptr_sync2 + FULL_THRESH;
    assign awfull = (wptr[ASIZE-1:0] == wfull_thresh[ASIZE-1:0]) &&
                    (wptr[ASIZE] == wfull_thresh[ASIZE]);

    // Almost empty: 1 entry
    wire [AWIDTH-1:0] rempty_thresh;
    assign rempty_thresh = wptr_sync2 - rptr + EMPTY_THRESH;
    assign arempty = (rptr[ASIZE-1:0] == rempty_thresh[ASIZE-1:0]) &&
                     (rptr[ASIZE] == rempty_thresh[ASIZE]);

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Read
    wire [ASIZE-1:0] raddr;
    assign raddr = rptr[ASIZE-1:0];

    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk) begin
        if (rinc_eff)
            rdata_reg <= mem[raddr];
    end

    assign rdata = (FALLTHROUGH == "TRUE") ? mem[raddr] : rdata_reg;

endmodule
