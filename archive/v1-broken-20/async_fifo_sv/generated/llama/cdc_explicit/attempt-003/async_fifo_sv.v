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

    // Write Domain
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_bin;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wcount;
    reg wfull_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcount <= 0;
            wfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcount <= wcount + 1;
            if (wcount == 2**ADDR_WIDTH - 1) begin
                wfull_reg <= 1;
            end
        end
    end

    always @(posedge wclk) begin
        wptr_gray <= wptr;
        wptr_bin <= wptr_gray;
    end

    assign wfull = wfull_reg;
    assign waddr = {wcount, wptr_bin};

    // Read Domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_bin;
    reg [ADDR_WIDTH:0] rcount;
    reg rempty_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcount <= 0;
            rempty_reg <= 1;
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            rcount <= rcount - 1;
            if (rcount == 0) begin
                rempty_reg <= 1;
            end
        end
    end

    always @(posedge rclk) begin
        rptr_gray <= rptr;
        rptr_bin <= rptr_gray;
    end

    assign rempty = rempty_reg;
    assign raddr = {rcount, rptr_bin};

    // CDC
    reg [SYNC_STAGES-1:0] wptr_sync;
    reg [SYNC_STAGES-1:0] rptr_sync;
    reg [SYNC_STAGES-1:0] wcount_sync;
    reg [SYNC_STAGES-1:0] rcount_sync;

    always @(posedge rclk) begin
        wptr_sync[0] <= wptr_bin;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    always @(posedge wclk) begin
        rptr_sync[0] <= rptr_bin;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        wcount_sync[0] <= wcount;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wcount_sync[i] <= wcount_sync[i-1];
        end
    end

    always @(posedge wclk) begin
        rcount_sync[0] <= rcount;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rcount_sync[i] <= rcount_sync[i-1];
        end
    end

    assign rdata = mem[wptr_sync[SYNC_STAGES-1]];
    assign rcount = wcount_sync[SYNC_STAGES-1] - rcount_sync[SYNC_STAGES-1];

endmodule
