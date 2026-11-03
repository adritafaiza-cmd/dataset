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

    // Synchronizer for write pointer into read domain
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    // Synchronizer for read pointer into write domain
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Write clock domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1'b1;
        end
    end

    // Synchronize read pointer into write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync[0] <= {PTR_WIDTH{1'b0}};
            rptr_sync[1] <= {PTR_WIDTH{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rptr_sync[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            rptr_sync[0] <= rptr;
            rptr_sync[1] <= rptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rptr_sync[i] <= rptr_sync[i-1];
            end
        end
    end

    assign rptr_wsync = rptr_sync[SYNC_STAGES-1];

    // Full flag: write pointer has lapped read pointer by DEPTH
    assign wfull = (wptr[ADDR_WIDTH-1:0] == rptr_wsync[ADDR_WIDTH-1:0]) &&
                   (wptr[ADDR_WIDTH] != rptr_wsync[ADDR_WIDTH]);

    assign waddr = wptr;

    // Read clock domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1'b1;
        end
    end

    // Synchronize write pointer into read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync[0] <= {PTR_WIDTH{1'b0}};
            wptr_sync[1] <= {PTR_WIDTH{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wptr_sync[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            wptr_sync[0] <= wptr;
            wptr_sync[1] <= wptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wptr_sync[i] <= wptr_sync[i-1];
            end
        end
    end

    assign wptr_rsync = wptr_sync[SYNC_STAGES-1];

    // Empty flag: write pointer equals read pointer
    assign rempty = (wptr_rsync == rptr);

    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];
    assign raddr = rptr;

endmodule
