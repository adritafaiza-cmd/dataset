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

    // Write domain
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] wptr_sync_r; // read pointer synchronized to write domain

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] rptr_sync_w; // write pointer synchronized to read domain

    // Synchronizer for write pointer to read domain
    reg [ADDR_WIDTH:0] wptr_sync_r [0:SYNC_STAGES-1];
    // Synchronizer for read pointer to write domain
    reg [ADDR_WIDTH:0] rptr_sync_w [0:SYNC_STAGES-1];

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

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync_r[0] <= {(ADDR_WIDTH+1){1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync_r[i] <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wptr_sync_r[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync_r[i] <= wptr_sync_r[i-1];
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync_w[0] <= {(ADDR_WIDTH+1){1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync_w[i] <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rptr_sync_w[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync_w[i] <= rptr_sync_w[i-1];
        end
    end

    // Full and empty flags
    // Full: write pointer has lapped read pointer by DEPTH
    // Compare the MSB (gray code style) but here using binary with wrap-around
    // For binary pointers, full when wptr[ADDR_WIDTH] != rptr_sync[ADDR_WIDTH] && wptr[ADDR_WIDTH-1:0] == rptr_sync[ADDR_WIDTH-1:0]
    // Empty: wptr_sync == rptr

    assign wfull = (wptr[ADDR_WIDTH] != rptr_sync_w[SYNC_STAGES-1][ADDR_WIDTH]) &&
                   (wptr[ADDR_WIDTH-1:0] == rptr_sync_w[SYNC_STAGES-1][ADDR_WIDTH-1:0]);

    assign rempty = (wptr_sync_r[SYNC_STAGES-1] == rptr);

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

    // Debug pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
