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
    reg [PTR_WIDTH-1:0]  rptr_w; // read pointer synchronized to write domain

    // Read domain
    reg [PTR_WIDTH-1:0]  rptr;
    reg [PTR_WIDTH-1:0]  wptr_r; // write pointer synchronized to read domain

    // Synchronizer for write pointer to read domain
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    // Synchronizer for read pointer to write domain
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Write pointer synchronization to read domain
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

    // Read pointer synchronization to write domain
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

    assign wptr_r = wptr_sync[SYNC_STAGES-1];
    assign rptr_w = rptr_sync[SYNC_STAGES-1];

    // Full and empty flags
    wire wfull_internal;
    wire rempty_internal;

    // FIFO is full when write pointer has lapped read pointer by DEPTH
    assign wfull_internal = (wptr == {rptr_w[ADDR_WIDTH], ~rptr_w[ADDR_WIDTH-1:0]});
    // FIFO is empty when write pointer equals read pointer
    assign rempty_internal = (wptr_r == rptr);

    assign wfull = wfull_internal;
    assign rempty = rempty_internal;

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {PTR_WIDTH{1'b0}};
        else if (winc && !wfull_internal)
            wptr <= wptr + 1'b1;
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {PTR_WIDTH{1'b0}};
        else if (rinc && !rempty_internal)
            rptr <= rptr + 1'b1;
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc && !wfull_internal)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Memory read
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
