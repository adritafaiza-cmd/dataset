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

    // Read data register
    reg [DSIZE-1:0] rdata_reg;

    // Write enable
    wire wvalid = winc & ~wfull;

    // Read enable
    wire rvalid = rinc & ~rempty;

    // Write pointer increment
    wire wptr_inc = wvalid;

    // Read pointer increment
    wire rptr_inc = rvalid;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            rptr_w <= {AWIDTH{1'b0}};
            rptr_w_sync1 <= {AWIDTH{1'b0}};
            rptr_w_sync2 <= {AWIDTH{1'b0}};
        end else begin
            if (wptr_inc)
                wptr <= wptr + 1'b1;

            // Synchronize read pointer to write domain
            rptr_w_sync1 <= rptr_w;
            rptr_w_sync2 <= rptr_w_sync1;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            wptr_r <= {AWIDTH{1'b0}};
            wptr_r_sync1 <= {AWIDTH{1'b0}};
            wptr_r_sync2 <= {AWIDTH{1'b0}};
            rdata_reg <= {DSIZE{1'b0}};
        end else begin
            if (rptr_inc)
                rptr <= rptr + 1'b1;

            // Synchronize write pointer to read domain
            wptr_r_sync1 <= wptr_r;
            wptr_r_sync2 <= wptr_r_sync1;

            // Read data
            if (rvalid)
                rdata_reg <= mem[rptr[ASIZE-1:0]];
        end
    end

    // Write to memory
    always @(posedge wclk) begin
        if (wvalid)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Cross-domain pointer synchronization
    // Write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wptr_r <= {AWIDTH{1'b0}};
        else
            wptr_r <= wptr;
    end

    // Read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            rptr_w <= {AWIDTH{1'b0}};
        else
            rptr_w <= rptr;
    end

    // Status signals
    // Write domain: wfull, awfull
    wire [AWIDTH-1:0] wptr_minus_rptr_w = wptr - rptr_w_sync2;
    assign wfull = (wptr_minus_rptr_w == FULL_THRESH);
    assign awfull = (wptr_minus_rptr_w >= (FULL_THRESH - 1));

    // Read domain: rempty, arempty
    wire [AWIDTH-1:0] wptr_r_minus_rptr = wptr_r_sync2 - rptr;
    assign rempty = (wptr_r_minus_rptr == 0);
    assign arempty = (wptr_r_minus_rptr <= EMPTY_THRESH);

    // Output data
    assign rdata = rdata_reg;

endmodule
