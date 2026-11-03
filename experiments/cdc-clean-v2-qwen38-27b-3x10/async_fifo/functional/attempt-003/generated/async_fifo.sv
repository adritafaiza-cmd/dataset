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
    reg [AWIDTH-1:0] wptr_sync;
    reg [AWIDTH-1:0] rptr_w_sync1;
    reg [AWIDTH-1:0] rptr_w_sync2;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [AWIDTH-1:0] rptr_sync;
    reg [AWIDTH-1:0] wptr_r_sync1;
    reg [AWIDTH-1:0] wptr_r_sync2;

    // Read data register for fall-through
    reg [DSIZE-1:0] rdata_reg;
    reg             rdata_valid;

    // Write enable
    wire winc_eff = winc & ~wfull;

    // Read enable
    wire rinc_eff = rinc & ~rempty;

    // Write pointer increment
    wire wptr_inc = winc_eff;

    // Read pointer increment
    wire rptr_inc = rinc_eff;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_sync <= {AWIDTH{1'b0}};
            rptr_w_sync1 <= {AWIDTH{1'b0}};
            rptr_w_sync2 <= {AWIDTH{1'b0}};
        end else begin
            if (wptr_inc)
                wptr <= wptr + 1'b1;
            wptr_sync <= wptr;
            rptr_w_sync1 <= rptr_w_sync2;
            rptr_w_sync2 <= rptr_sync;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_sync <= {AWIDTH{1'b0}};
            wptr_r_sync1 <= {AWIDTH{1'b0}};
            wptr_r_sync2 <= {AWIDTH{1'b0}};
            rdata_reg <= {DSIZE{1'b0}};
            rdata_valid <= 1'b0;
        end else begin
            if (rptr_inc)
                rptr <= rptr + 1'b1;
            rptr_sync <= rptr;
            wptr_r_sync1 <= wptr_r_sync2;
            wptr_r_sync2 <= wptr_sync;

            // Fall-through: capture data when a read is accepted
            if (rptr_inc) begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
                rdata_valid <= 1'b1;
            end
        end
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Full/Empty generation
    // In write domain: full when wptr - rptr_w_sync2 == DEPTH
    wire [AWIDTH:0] wdiff = {1'b0, wptr} - {1'b0, rptr_w_sync2};
    assign wfull = (wdiff == DEPTH);

    // Almost full: wdiff >= FULL_THRESH
    assign awfull = (wdiff >= FULL_THRESH);

    // In read domain: empty when wptr_r_sync2 - rptr == 0
    wire [AWIDTH:0] rdiff = {1'b0, wptr_r_sync2} - {1'b0, rptr};
    assign rempty = (rdiff == 0);

    // Almost empty: rdiff <= EMPTY_THRESH
    assign arempty = (rdiff <= EMPTY_THRESH);

    // Output data
    // For fall-through: present rdata_reg when valid
    // For non-fall-through: present mem[rptr] combinationally
    assign rdata = (FALLTHROUGH == "TRUE") ? rdata_reg : mem[rptr[ASIZE-1:0]];

endmodule
