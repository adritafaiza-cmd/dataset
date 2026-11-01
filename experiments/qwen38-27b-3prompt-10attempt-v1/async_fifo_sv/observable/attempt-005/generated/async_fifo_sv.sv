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
    reg [PTR_WIDTH-1:0] wptr;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [PTR_WIDTH-1:0] rptr;

    // Synchronizers
    reg [PTR_WIDTH-1:0] rptr_wsync [0:SYNC_STAGES-1];
    reg [PTR_WIDTH-1:0] wptr_rsync [0:SYNC_STAGES-1];

    // Synchronized pointers in respective domains
    wire [PTR_WIDTH-1:0] rptr_wsync_out = rptr_wsync[SYNC_STAGES-1];
    wire [PTR_WIDTH-1:0] wptr_rsync_out = wptr_rsync[SYNC_STAGES-1];

    // Full and empty flags
    assign wfull = (wptr == {~rptr_wsync_out[PTR_WIDTH-1:ADDR_WIDTH], rptr_wsync_out[ADDR_WIDTH-1:0]});
    assign rempty = (rptr == wptr_rsync_out);

    // Pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

    // Read data output
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {PTR_WIDTH{1'b0}};
        else if (winc && !wfull)
            wptr <= wptr + 1'b1;
    end

    // Write memory
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {PTR_WIDTH{1'b0}};
        else if (rinc && !rempty)
            rptr <= rptr + 1'b1;
    end

    // Synchronize rptr to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_wsync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_wsync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_wsync[i] <= rptr_wsync[i-1];
        end
    end

    // Synchronize wptr to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_rsync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_rsync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_rsync[i] <= wptr_rsync[i-1];
        end
    end

endmodule
