module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    // Write domain
    reg [ADDR_WIDTH:0] wptr;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] rptr_wsync [0:SYNC_STAGES-1];

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_rsync [0:SYNC_STAGES-1];

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_wsync[0] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            rptr_wsync[1] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rptr_wsync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            end
        end else begin
            rptr_wsync[0] <= rptr;
            rptr_wsync[1] <= rptr_wsync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rptr_wsync[i] <= rptr_wsync[i-1];
            end
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_rsync[0] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            wptr_rsync[1] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wptr_rsync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            end
        end else begin
            wptr_rsync[0] <= wptr;
            wptr_rsync[1] <= wptr_rsync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wptr_rsync[i] <= wptr_rsync[i-1];
            end
        end
    end

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
        else if (winc && !wfull)
            wptr <= wptr + 1'b1;
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
        else if (rinc && !rempty)
            rptr <= rptr + 1'b1;
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Memory read
    always @(posedge rclk) begin
        if (rinc && !rempty)
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Full flag: write pointer has lapped read pointer by DEPTH
    wire [ADDR_WIDTH:0] rptr_wsync_final = rptr_wsync[SYNC_STAGES-1];
    assign wfull = (wptr[ADDR_WIDTH] != rptr_wsync_final[ADDR_WIDTH]) &&
                   (wptr[ADDR_WIDTH-1:0] == rptr_wsync_final[ADDR_WIDTH-1:0]);

    // Empty flag: read pointer equals write pointer
    wire [ADDR_WIDTH:0] wptr_rsync_final = wptr_rsync[SYNC_STAGES-1];
    assign rempty = (rptr == wptr_rsync_final);

    // Address outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
