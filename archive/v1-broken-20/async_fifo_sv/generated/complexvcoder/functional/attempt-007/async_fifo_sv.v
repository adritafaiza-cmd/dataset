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

    // Internal signals
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg [ADDR_WIDTH:0] waddr_synced, raddr_synced;
    reg wfull_synced, rempty_synced;
    reg [DATA_WIDTH-1:0] rdata_synced;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
        end
    end

    // FIFO full and empty logic
    assign wfull = (wptr == (rptr + (1<<ADDR_WIDTH) - 1) % (1<<ADDR_WIDTH));
    assign rempty = (wptr == rptr);

    // Address outputs
    assign waddr = wptr;
    assign raddr = rptr;

    // Data write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem[wptr] <= 0;
        end else if (winc && !wfull) begin
            mem[wptr] <= wdata;
        end
    end

    // Data read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_synced <= 0;
        end else if (rinc && !rempty) begin
            rdata_synced <= mem[rptr];
        end
    end

    // Synchronous reset logic
    sync_reset wreset_sync (
        .clk(wclk),
        .reset_n(wrst_n),
        .synced_reset_n(wrst_n)
    );

    sync_reset rreset_sync (
        .clk(rclk),
        .reset_n(rrst_n),
        .synced_reset_n(rrst_n)
    );

    // Output assignments
    assign wfull_synced = wfull;
    assign rempty_synced = rempty;
    assign rdata = rdata_synced;

endmodule

module sync_reset (
    input  wire                    clk,
    input  wire                    reset_n,
    output wire                    synced_reset_n
);

    reg [SYNC_STAGES-1:0] reset_sync_reg;

    always @(posedge clk) begin
        reset_sync_reg <= {reset_n, reset_sync_reg[SYNC_STAGES-2:0]};
    end

    assign synced_reset_n = reset_sync_reg[0];

endmodule
