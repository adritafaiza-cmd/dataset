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

    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wptr_sync, rptr_sync;
    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0] wptr_bin, rptr_bin;
    reg [SYNC_STAGES-1:0] wptr_sync_reg;
    reg [SYNC_STAGES-1:0] rptr_sync_reg;
    reg wfull_reg, rempty_reg;

    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1;
            if (wptr == {1'b1, {(ADDR_WIDTH){1'b0}}} - 1) begin
                wfull_reg <= 1;
            end else begin
                wfull_reg <= 0;
            end
        end
    end

    always @(posedge wclk) begin
        wptr_gray <= wptr;
        wptr_bin <= wptr;
        for (int i = 0; i < SYNC_STAGES; i++) begin
            if (i == 0) begin
                wptr_sync_reg[i] <= wptr_gray[ADDR_WIDTH];
            end else begin
                wptr_sync_reg[i] <= wptr_sync_reg[i-1];
            end
        end
    end

    always @(posedge rclk) begin
        rptr_gray <= rptr;
        rptr_bin <= rptr;
        for (int i = 0; i < SYNC_STAGES; i++) begin
            if (i == 0) begin
                rptr_sync_reg[i] <= rptr_gray[ADDR_WIDTH];
            end else begin
                rptr_sync_reg[i] <= rptr_sync_reg[i-1];
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rempty_reg <= 1;
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            if (rptr == {1'b1, {(ADDR_WIDTH){1'b0}}} - 1) begin
                rempty_reg <= 1;
            end else begin
                rempty_reg <= 0;
            end
        end
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr_sync_reg[SYNC_STAGES-1];
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr_sync_reg[SYNC_STAGES-1];
    end

    always @(posedge rclk) begin
        if (~rempty_reg) begin
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    assign waddr = wptr;
    assign raddr = rptr;

endmodule
