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

    // Write domain
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_sync [SYNC_STAGES-1:0];

    // Read domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_sync [SYNC_STAGES-1:0];

    // Data memory
    reg [DATA_WIDTH-1:0] data [2**ADDR_WIDTH-1:0];

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wfull <= 1'b0;
        end else if (winc && ~wfull) begin
            wptr <= wptr + 1;
            data[wptr] <= wdata;
        end
    end

    // Gray encoding for write pointer
    always @(*) begin
        wptr_gray <= {wptr[ADDR_WIDTH-1], wptr[ADDR_WIDTH-2:0] + wptr[ADDR_WIDTH-1]};
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk) begin
        wptr_sync[0] <= wptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rempty <= 1'b1;
        end else if (rinc && ~rempty) begin
            rptr <= rptr + 1;
        end
    end

    // Gray encoding for read pointer
    always @(*) begin
        rptr_gray <= {rptr[ADDR_WIDTH-1], rptr[ADDR_WIDTH-2:0] + rptr[ADDR_WIDTH-1]};
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk) begin
        rptr_sync[0] <= rptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    // Full and empty flags
    always @(*) begin
        wfull <= (wptr_sync[SYNC_STAGES-1] == rptr + (2**ADDR_WIDTH - 1));
        rempty <= (rptr_sync[SYNC_STAGES-1] == wptr);
    end

    // Data output
    always @(*) begin
        rdata <= data[rptr];
    end

    // Debug outputs
    always @(*) begin
        waddr <= {1'b0, wptr};
        raddr <= {1'b0, rptr};
    end

endmodule
