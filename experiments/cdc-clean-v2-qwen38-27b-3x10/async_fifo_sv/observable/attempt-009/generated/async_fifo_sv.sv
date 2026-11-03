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

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Synchronizers: write pointer into read domain
    reg [ADDR_WIDTH:0] wptr_sync [0:SYNC_STAGES-1];
    // Synchronizers: read pointer into write domain
    reg [ADDR_WIDTH:0] rptr_sync [0:SYNC_STAGES-1];

    // Synchronized pointers
    wire [ADDR_WIDTH:0] wptr_synced = wptr_sync[SYNC_STAGES-1];
    wire [ADDR_WIDTH:0] rptr_synced = rptr_sync[SYNC_STAGES-1];

    // Flags
    assign wfull  = (wptr[ADDR_WIDTH] != rptr_synced[ADDR_WIDTH]) &&
                    (wptr[ADDR_WIDTH-1:0] == rptr_synced[ADDR_WIDTH-1:0]);
    assign rempty = (rptr == wptr_synced);

    // Pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

    // Read data output
    assign rdata = rdata_reg;

    // Write clock domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end else begin
            if (winc && !wfull) begin
                mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
                wptr <= wptr + 1'b1;
            end
        end
    end

    // Read clock domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
            rdata_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            if (rinc && !rempty) begin
                rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
                rptr <= rptr + 1'b1;
            end
        end
    end

    // Synchronize write pointer into read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    // Synchronize read pointer into write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

endmodule
