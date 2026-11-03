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

    localparam DEPTH = 2**ADDR_WIDTH;

    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] wptr_sync;
    reg [ADDR_WIDTH-1:0] rptr_sync;

    reg [DATA_WIDTH-1:0] fifo [DEPTH-1:0];

    reg wfull_reg;
    reg rempty_reg;

    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

    assign waddr = {1'b0, wptr};
    assign raddr = {1'b0, rptr};

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wfull_reg <= 1'b0;
        end else if (winc && ~wfull_reg) begin
            fifo[wptr] <= wdata;
            wptr <= wptr + 1;
            if (wptr == DEPTH - 1) begin
                wfull_reg <= 1'b1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rempty_reg <= 1'b1;
        end else if (rinc && ~rempty_reg) begin
            rdata <= fifo[rptr];
            rptr <= rptr + 1;
            if (rptr == DEPTH - 1) begin
                rempty_reg <= 1'b1;
            end
        end
    end

    // Synchronize wptr to read clock domain
    always @(posedge rclk) begin
        wptr_sync <= wptr_sync + 1;
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr;
    end

    // Synchronize rptr to write clock domain
    always @(posedge wclk) begin
        rptr_sync <= rptr_sync + 1;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr;
    end

    // Reset synchronization
    reg [SYNC_STAGES-1:0] wrst_sync;
    reg [SYNC_STAGES-1:0] rrst_sync;

    always @(posedge wclk) begin
        wrst_sync[0] <= ~wrst_n;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wrst_sync[i] <= wrst_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        rrst_sync[0] <= ~rrst_n;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rrst_sync[i] <= rrst_sync[i-1];
        end
    end

    // Update rempty and wfull based on synchronized pointers
    always @(posedge rclk) begin
        if (rrst_sync[SYNC_STAGES-1]) begin
            rempty_reg <= 1'b1;
        end else if (rptr == wptr_sync) begin
            rempty_reg <= 1'b1;
        end else begin
            rempty_reg <= 1'b0;
        end
    end

    always @(posedge wclk) begin
        if (wrst_sync[SYNC_STAGES-1]) begin
            wfull_reg <= 1'b0;
        end else if (wptr == rptr_sync + DEPTH) begin
            wfull_reg <= 1'b1;
        end else begin
            wfull_reg <= 1'b0;
        end
    end

endmodule
