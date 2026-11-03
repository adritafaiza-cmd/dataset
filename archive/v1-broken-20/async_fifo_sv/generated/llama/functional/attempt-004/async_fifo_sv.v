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

    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] wptr_sync;
    reg [ADDR_WIDTH-1:0] rptr_sync;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wcount;
    reg [ADDR_WIDTH:0] rcount;
    reg wfull_int;
    reg rempty_int;

    assign wfull = wfull_int;
    assign rempty = rempty_int;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcount <= 0;
            wfull_int <= 0;
        end else if (winc && ~wfull_int) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcount <= wcount + 1;
            if (wcount == 2**ADDR_WIDTH - 1) begin
                wfull_int <= 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcount <= 0;
            rempty_int <= 1;
        end else if (rinc && ~rempty_int) begin
            rdata <= mem[rptr];
            rptr <= rptr + 1;
            rcount <= rcount + 1;
            if (rcount == 1) begin
                rempty_int <= 0;
            end
            if (rcount == 2**ADDR_WIDTH) begin
                rcount <= 0;
            end
        end
    end

    // Synchronize wptr to read clock domain
    reg [ADDR_WIDTH-1:0] wptr_sync_reg [SYNC_STAGES-1:0];
    always @(posedge rclk) begin
        wptr_sync_reg[0] <= wptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_reg[i] <= wptr_sync_reg[i-1];
        end
        wptr_sync <= wptr_sync_reg[SYNC_STAGES-1];
    end

    // Synchronize rptr to write clock domain
    reg [ADDR_WIDTH-1:0] rptr_sync_reg [SYNC_STAGES-1:0];
    always @(posedge wclk) begin
        rptr_sync_reg[0] <= rptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_reg[i] <= rptr_sync_reg[i-1];
        end
        rptr_sync <= rptr_sync_reg[SYNC_STAGES-1];
    end

    always @(posedge wclk) begin
        if (wcount == 2**ADDR_WIDTH - 1) begin
            wfull_int <= 1;
        end else if (wcount == rcount) begin
            wfull_int <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rcount == 0) begin
            rempty_int <= 1;
        end else if (rcount == wcount) begin
            rempty_int <= 0;
        end
    end

    assign waddr = {1'b0, wptr};
    assign raddr = {1'b0, rptr};

endmodule
