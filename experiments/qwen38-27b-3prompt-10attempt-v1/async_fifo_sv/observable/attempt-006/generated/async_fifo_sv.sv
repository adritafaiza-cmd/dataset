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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Write domain
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0]  wptr;
    reg [PTR_WIDTH-1:0]  rptr_wsync;

    // Read domain
    reg [PTR_WIDTH-1:0]  rptr;
    reg [PTR_WIDTH-1:0]  wptr_rsync;

    // Synchronizer chains
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Write clock domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else if (winc && !wfull) begin
            wptr <= wptr + 1'b1;
        end
    end

    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Synchronize rptr into write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    assign rptr_wsync = rptr_sync[SYNC_STAGES-1];

    // Full condition: write pointer has lapped read pointer by DEPTH
    // In binary, full when wptr[ADDR_WIDTH:1] == rptr_wsync[ADDR_WIDTH:1] and wptr[0] != rptr_wsync[0]
    // More simply: full when (wptr - rptr_wsync) == DEPTH
    // Using the standard Gray code or binary comparison:
    // wfull = (wptr[ADDR_WIDTH:1] == rptr_wsync[ADDR_WIDTH:1]) && (wptr[0] != rptr_wsync[0])
    // But since we're using binary pointers, let's use:
    // wfull = (wptr[ADDR_WIDTH:1] == rptr_wsync[ADDR_WIDTH:1]) && (wptr[0] ^ rptr_wsync[0])
    // Actually, the standard approach with binary pointers:
    // wfull when wptr has advanced exactly DEPTH beyond rptr_wsync
    // i.e., wptr[ADDR_WIDTH:1] == rptr_wsync[ADDR_WIDTH:1] and wptr[0] != rptr_wsync[0]
    // This works because DEPTH = 2^ADDR_WIDTH, so the upper bits wrap around.

    wire wfull_internal = (wptr[ADDR_WIDTH:1] == rptr_wsync[ADDR_WIDTH:1]) && (wptr[0] != rptr_wsync[0]);
    assign wfull = wfull_internal;
    assign waddr = wptr;

    // Read clock domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1'b1;
        end
    end

    // Synchronize wptr into read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    assign wptr_rsync = wptr_sync[SYNC_STAGES-1];

    // Empty condition: read pointer equals write pointer
    wire rempty_internal = (rptr == wptr_rsync);
    assign rempty = rempty_internal;
    assign raddr = rptr;

    // Read data: sample from memory at current read pointer
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

endmodule
