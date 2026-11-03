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
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_gray;
    reg [ADDR_WIDTH:0] rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_sync;
    reg [ADDR_WIDTH:0] rptr_gray_sync;
    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];
    wire wfull_raw;
    wire rempty_raw;

    // Gray code conversion
    assign wptr_gray = (wptr >> 1) ^ wptr;
    assign rptr_gray = (rptr >> 1) ^ rptr;

    // Sync FIFO instances for crossing clock domains
    sync_ff #(.ADDR_WIDTH(ADDR_WIDTH)) sync_wptr (
        .clk(wclk),
        .rst_n(wrst_n),
        .d(rptr_gray),
        .q(rptr_gray_sync)
    );

    sync_ff #(.ADDR_WIDTH(ADDR_WIDTH)) sync_rptr (
        .clk(rclk),
        .rst_n(rrst_n),
        .d(wptr_gray),
        .q(wptr_gray_sync)
    );

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull_raw) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1;
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty_raw) begin
            rptr <= rptr + 1;
        end
    end

    // Full and empty flag logic
    assign wfull_raw = (wptr_gray_sync[ADDR_WIDTH-1:0] == wptr[ADDR_WIDTH-1:0] && wptr_gray_sync[ADDR_WIDTH] != wptr[ADDR_WIDTH]);
    assign rempty_raw = (rptr_gray_sync[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0] && rptr_gray_sync[ADDR_WIDTH] == rptr[ADDR_WIDTH]);

    // Output assignments
    assign wfull = wfull_raw;
    assign waddr = wptr;
    assign rempty = rempty_raw;
    assign raddr = rptr;
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

endmodule

module sync_ff #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     d,
    output reg  [ADDR_WIDTH:0]     q
);

    // Internal sync register array
    reg [ADDR_WIDTH:0] sync_reg [0:SYNC_STAGES-1];

    // Sync logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 0;
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= 0;
            end
        end else begin
            sync_reg[0] <= d;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            q <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule
