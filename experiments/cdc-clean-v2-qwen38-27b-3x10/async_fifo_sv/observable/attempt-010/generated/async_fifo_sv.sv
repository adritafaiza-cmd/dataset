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
    reg [PTR_WIDTH-1:0]  rptr_wsync; // read pointer synchronized to write domain

    // Read domain
    reg [PTR_WIDTH-1:0]  rptr;
    reg [PTR_WIDTH-1:0]  wptr_rsync; // write pointer synchronized to read domain

    // Synchronizer for write pointer to read domain
    reg [PTR_WIDTH-1:0] wptr_rsync_r1;
    reg [PTR_WIDTH-1:0] wptr_rsync_r2;
    reg [PTR_WIDTH-1:0] wptr_rsync_r3;

    // Synchronizer for read pointer to write domain
    reg [PTR_WIDTH-1:0] rptr_wsync_r1;
    reg [PTR_WIDTH-1:0] rptr_wsync_r2;
    reg [PTR_WIDTH-1:0] rptr_wsync_r3;

    // Write pointer increment
    wire winc_eff = winc & ~wfull;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else if (winc_eff) begin
            wptr <= wptr + 1'b1;
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read pointer increment
    wire rinc_eff = rinc & ~rempty;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
        end else if (rinc_eff) begin
            rptr <= rptr + 1'b1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_rsync_r1 <= {PTR_WIDTH{1'b0}};
            wptr_rsync_r2 <= {PTR_WIDTH{1'b0}};
            wptr_rsync_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_rsync_r1 <= wptr;
            wptr_rsync_r2 <= wptr_rsync_r1;
            wptr_rsync_r3 <= wptr_rsync_r2;
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_wsync_r1 <= {PTR_WIDTH{1'b0}};
            rptr_wsync_r2 <= {PTR_WIDTH{1'b0}};
            rptr_wsync_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_wsync_r1 <= rptr;
            rptr_wsync_r2 <= rptr_wsync_r1;
            rptr_wsync_r3 <= rptr_wsync_r2;
        end
    end

    assign wptr_rsync = wptr_rsync_r3;
    assign rptr_wsync = rptr_wsync_r3;

    // Full flag: write pointer has lapped read pointer by DEPTH
    // wfull when (wptr - rptr_wsync) == DEPTH
    wire [PTR_WIDTH:0] wdiff = {1'b0, wptr} - {1'b0, rptr_wsync};
    assign wfull = (wdiff == DEPTH);

    // Empty flag: read pointer equals write pointer
    wire [PTR_WIDTH:0] rdiff = {1'b0, wptr_rsync} - {1'b0, rptr};
    assign rempty = (rdiff == 0);

    // Read data
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
