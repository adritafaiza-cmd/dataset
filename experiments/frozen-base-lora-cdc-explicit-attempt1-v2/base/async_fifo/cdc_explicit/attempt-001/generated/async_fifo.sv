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
    localparam AWFULL_THRESH = DEPTH - 2;
    localparam AEMPTY_THRESH = 2;

    // Write domain
    reg [ASIZE:0] wptr;
    reg [ASIZE:0] rptr_w;
    reg [ASIZE:0] rptr_w_sync1;
    reg [ASIZE:0] rptr_w_sync2;

    // Read domain
    reg [ASIZE:0] rptr;
    reg [ASIZE:0] wptr_r;
    reg [ASIZE:0] wptr_r_sync1;
    reg [ASIZE:0] wptr_r_sync2;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wvalid = winc & ~wfull;
    wire waddr = wptr[ASIZE-1:0];

    // Read enable
    wire rvalid = rinc & ~rempty;
    wire raddr = rptr[ASIZE-1:0];

    // Write to memory
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {(ASIZE+1){1'b0}};
        else if (wvalid)
            wptr <= wptr + 1'b1;
    end

    always @(posedge wclk) begin
        if (wvalid)
            mem[waddr] <= wdata;
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_w_sync1 <= {(ASIZE+1){1'b0}};
            rptr_w_sync2 <= {(ASIZE+1){1'b0}};
        end else begin
            rptr_w_sync1 <= rptr_w;
            rptr_w_sync2 <= rptr_w_sync1;
        end
    end

    // Read domain pointer
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {(ASIZE+1){1'b0}};
        else if (rvalid)
            rptr <= rptr + 1'b1;
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_r_sync1 <= {(ASIZE+1){1'b0}};
            wptr_r_sync2 <= {(ASIZE+1){1'b0}};
        end else begin
            wptr_r_sync1 <= wptr_r;
            wptr_r_sync2 <= wptr_r_sync1;
        end
    end

    // Full and empty flags
    assign wfull = (wptr[ASIZE] != rptr_w_sync2[ASIZE]) &&
                   (wptr[ASIZE-1:0] == rptr_w_sync2[ASIZE-1:0]);

    assign rempty = (rptr == wptr_r_sync2);

    // Almost full/empty
    wire [ASIZE:0] wcount = wptr - rptr_w_sync2;
    wire [ASIZE:0] rcount = wptr_r_sync2 - rptr;

    assign awfull = (wcount >= AWFULL_THRESH);
    assign arempty = (rcount <= AEMPTY_THRESH);

    // Read data
    // For fall-through: present data at current read pointer when not empty
    // For non-fall-through: present data one cycle after read is accepted
    reg [DSIZE-1:0] rdata_reg;
    reg             rdata_valid;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
            rdata_valid <= 1'b0;
        end else begin
            if (rvalid) begin
                rdata_reg <= mem[raddr];
                rdata_valid <= 1'b1;
            end else if (!rempty) begin
                // Fall-through: keep presenting current oldest word
                rdata_reg <= mem[raddr];
                rdata_valid <= 1'b1;
            end else begin
                rdata_valid <= 1'b0;
            end
        end
    end

    assign rdata = (FALLTHROUGH == "TRUE") ? mem[raddr] : rdata_reg;

endmodule
