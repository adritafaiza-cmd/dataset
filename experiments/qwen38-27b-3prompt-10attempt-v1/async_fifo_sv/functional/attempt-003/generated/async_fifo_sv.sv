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
    reg [ADDR_WIDTH:0] rptr_w; // read pointer synchronized to write domain

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_r; // write pointer synchronized to read domain

    // Synchronization registers
    reg [ADDR_WIDTH:0] wptr_sync [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] rptr_sync [0:SYNC_STAGES-1];

    // Write domain logic
    wire wfull_internal = (wptr[ADDR_WIDTH] != rptr_w[ADDR_WIDTH]) &&
                          (wptr[ADDR_WIDTH-1:0] == rptr_w[ADDR_WIDTH-1:0]);

    assign wfull = wfull_internal;
    assign waddr = wptr;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end else if (winc && !wfull_internal) begin
            wptr <= wptr + 1'b1;
        end
    end

    // Write to memory
    always @(posedge wclk) begin
        if (winc && !wfull_internal) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync[0] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    assign rptr_w = rptr_sync[SYNC_STAGES-1];

    // Read domain logic
    wire rempty_internal = (rptr == wptr_r);

    assign rempty = rempty_internal;
    assign raddr = rptr;
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end else if (rinc && !rempty_internal) begin
            rptr <= rptr + 1'b1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync[0] <= {1'b0, {ADDR_WIDTH{1'b0}}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    assign wptr_r = wptr_sync[SYNC_STAGES-1];

endmodule
