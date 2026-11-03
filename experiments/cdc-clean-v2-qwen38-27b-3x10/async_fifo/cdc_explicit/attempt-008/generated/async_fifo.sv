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

    // Read data pipeline
    reg [DSIZE-1:0] rdata_pipe1;
    reg [DSIZE-1:0] rdata_pipe2;
    reg             rdata_valid1;
    reg             rdata_valid2;

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
            wptr <= {(ASIZE+1){1'b0}};
        end else if (wptr_inc) begin
            wptr <= wptr + 1'b1;
        end
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

    // Write full and almost full
    assign wfull = (wptr[ASIZE] != rptr_w_sync2[ASIZE]) &&
                   (wptr[ASIZE-1:0] == rptr_w_sync2[ASIZE-1:0]);
    assign awfull = (wptr[ASIZE] == rptr_w_sync2[ASIZE]) &&
                    (wptr[ASIZE-1:0] - rptr_w_sync2[ASIZE-1:0] >= AWFULL_THRESH[ASIZE-1:0]);

    // Write to memory
    always @(posedge wclk) begin
        if (wvalid) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {(ASIZE+1){1'b0}};
        end else if (rptr_inc) begin
            rptr <= rptr + 1'b1;
        end
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

    // Read empty and almost empty
    assign rempty = (rptr == wptr_r_sync2);
    assign arempty = (wptr_r_sync2[ASIZE] == rptr[ASIZE]) &&
                     (wptr_r_sync2[ASIZE-1:0] - rptr[ASIZE-1:0] <= AEMPTY_THRESH[ASIZE-1:0]);

    // Read data pipeline: two destination-clock stages
    // Stage 1: capture data from memory when a read is accepted
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_pipe1 <= {DSIZE{1'b0}};
            rdata_valid1 <= 1'b0;
        end else begin
            if (rvalid) begin
                rdata_pipe1 <= mem[rptr[ASIZE-1:0]];
                rdata_valid1 <= 1'b1;
            end else begin
                rdata_valid1 <= 1'b0;
            end
        end
    end

    // Stage 2: second pipeline stage
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_pipe2 <= {DSIZE{1'b0}};
            rdata_valid2 <= 1'b0;
        end else begin
            rdata_pipe2 <= rdata_pipe1;
            rdata_valid2 <= rdata_valid1;
        end
    end

    // Output rdata
    // When FALLTHROUGH is TRUE, present data as soon as it becomes available
    // The data is valid after two pipeline stages
    assign rdata = rdata_pipe2;

    // Update the synchronized pointers for the other domain
    // These are the "acknowledged binary snapshots"
    always @(posedge wclk) begin
        rptr_w <= rptr;
    end

    always @(posedge rclk) begin
        wptr_r <= wptr;
    end

endmodule
