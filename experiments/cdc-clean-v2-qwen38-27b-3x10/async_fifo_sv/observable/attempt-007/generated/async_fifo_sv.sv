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

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write pointer (write domain)
    reg [ADDR_WIDTH:0] wptr;
    // Read pointer (read domain)
    reg [ADDR_WIDTH:0] rptr;

    // Synchronized read pointer in write domain
    reg [ADDR_WIDTH:0] rptr_wsync [0:SYNC_STAGES-1];
    // Synchronized write pointer in read domain
    reg [ADDR_WIDTH:0] wptr_rsync [0:SYNC_STAGES-1];

    // Flags
    wire wfull;
    wire rempty;

    // Write pointer increment
    wire winc_eff = winc & ~wfull;

    // Read pointer increment
    wire rinc_eff = rinc & ~rempty;

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (winc_eff)
            wptr <= wptr + 1'b1;
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (rinc_eff)
            rptr <= rptr + 1'b1;
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Memory read
    always @(posedge rclk) begin
        if (rinc_eff)
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_wsync[i] <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rptr_wsync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_wsync[i] <= rptr_wsync[i-1];
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_rsync[i] <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wptr_rsync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_rsync[i] <= wptr_rsync[i-1];
        end
    end

    // Full flag: write pointer has lapped read pointer by DEPTH
    // Compare the upper bits (wrap-around bits)
    assign wfull = (wptr[ADDR_WIDTH] != rptr_wsync[SYNC_STAGES-1][ADDR_WIDTH]) &&
                   (wptr[ADDR_WIDTH-1:0] == rptr_wsync[SYNC_STAGES-1][ADDR_WIDTH-1:0]);

    // Empty flag: write pointer equals read pointer
    assign rempty = (wptr_rsync[SYNC_STAGES-1] == rptr);

    // Outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
