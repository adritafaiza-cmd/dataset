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
    wire [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] rptr;
    reg wfull_reg, rempty_reg;
    wire waddr_wclk, wfull_wclk, rempty_wclk;
    wire waddr_rclk, wfull_rclk, rempty_rclk;

    // FIFO core
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            rempty_reg <= 1;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
            end
            if (wptr == rptr) begin
                wfull_reg <= 1;
            end else begin
                wfull_reg <= 0;
            end
            if (wptr == 0 && rempty_reg) begin
                rempty_reg <= 0;
            end
        end
    end

    assign waddr_wclk = wptr;
    assign rempty_wclk = rempty_reg;
    assign wfull_wclk = wfull_reg;

    // Clock domain crossing for write domain signals
    sync_module #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_wclk_to_rclk (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .waddr_wclk(waddr_wclk),
        .rempty_wclk(rempty_wclk),
        .wfull_wclk(wfull_wclk),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .waddr_rclk(waddr_rclk),
        .rempty_rclk(rempty_rclk),
        .wfull_rclk(wfull_rclk)
    );

    // FIFO core
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            wfull_reg <= 0;
            rempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rptr <= rptr + 1;
            end
            if (wptr == rptr) begin
                rempty_reg <= 1;
            end else begin
                rempty_reg <= 0;
            end
            if (rptr == 0 && wfull_reg) begin
                wfull_reg <= 0;
            end
        end
    end

    assign rdata = mem[rptr];
    assign waddr = waddr_rclk;
    assign rempty = rempty_rclk;
    assign raddr = rptr;

endmodule

module sync_module #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire [ADDR_WIDTH:0]     waddr_wclk,
    input  wire                    rempty_wclk,
    input  wire                    wfull_wclk,
    input  wire                    rclk,
    input  wire                    rrst_n,
    output wire [ADDR_WIDTH:0]     waddr_rclk,
    output wire                    rempty_rclk,
    output wire                    wfull_rclk
);

    // Internal signals
    reg [ADDR_WIDTH:0] waddr_reg;
    reg rempty_reg;
    reg wfull_reg;
    reg [SYNC_STAGES-1:0] waddr_sync;
    reg [SYNC_STAGES-1:0] rempty_sync;
    reg [SYNC_STAGES-1:0] wfull_sync;

    // Write domain signals synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr_reg <= 0;
            rempty_reg <= 1;
            wfull_reg <= 0;
        end else begin
            waddr_reg <= waddr_wclk;
            rempty_reg <= rempty_wclk;
            wfull_reg <= wfull_wclk;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            waddr_sync <= 0;
            rempty_sync <= 1;
            wfull_sync <= 0;
        end else begin
            waddr_sync <= {waddr_sync[SYNC_STAGES-2:0], waddr_reg};
            rempty_sync <= {rempty_sync[SYNC_STAGES-2:0], rempty_reg};
            wfull_sync <= {wfull_sync[SYNC_STAGES-2:0], wfull_reg};
        end
    end

    assign waddr_rclk = waddr_sync[SYNC_STAGES-1];
    assign rempty_rclk = rempty_sync[SYNC_STAGES-1];
    assign wfull_rclk = wfull_sync[SYNC_STAGES-1];

endmodule
