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
    localparam ADDR_MSB = ADDR_WIDTH;

    // Write domain signals
    reg [ADDR_WIDTH:0] wptr_gray, wptr_gray_next, wptr_bin, wptr_bin_next;
    reg [ADDR_WIDTH:0] rptr_gray_synced [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] rptr_bin_synced;

    // Read domain signals
    reg [ADDR_WIDTH:0] rptr_gray, rptr_gray_next, rptr_bin, rptr_bin_next;
    reg [ADDR_WIDTH:0] wptr_gray_synced [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] wptr_bin_synced;

    // Memory
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray <= 0;
            wptr_bin <= 0;
        end else begin
            wptr_gray <= wptr_gray_next;
            wptr_bin <= wptr_bin_next;
        end
    end

    always @(*) begin
        wptr_gray_next = wptr_gray;
        wptr_bin_next = wptr_bin;
        if (winc && !wfull) begin
            wptr_bin_next = wptr_bin + 1;
            wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray <= 0;
            rptr_bin <= 0;
        end else begin
            rptr_gray <= rptr_gray_next;
            rptr_bin <= rptr_bin_next;
        end
    end

    always @(*) begin
        rptr_gray_next = rptr_gray;
        rptr_bin_next = rptr_bin;
        if (rinc && !rempty) begin
            rptr_bin_next = rptr_bin + 1;
            rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;
        end
    end

    // Gray to binary conversion for read pointer in write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_synced[0] <= 0;
            rptr_bin_synced <= 0;
        end else begin
            rptr_gray_synced[0] <= rptr_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                rptr_gray_synced[i] <= rptr_gray_synced[i-1];
            end
            rptr_bin_synced <= (rptr_gray_synced[SYNC_STAGES-1] >> 1) ^ rptr_gray_synced[SYNC_STAGES-1];
        end
    end

    // Gray to binary conversion for write pointer in read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_synced[0] <= 0;
            wptr_bin_synced <= 0;
        end else begin
            wptr_gray_synced[0] <= wptr_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                wptr_gray_synced[i] <= wptr_gray_synced[i-1];
            end
            wptr_bin_synced <= (wptr_gray_synced[SYNC_STAGES-1] >> 1) ^ wptr_gray_synced[SYNC_STAGES-1];
        end
    end

    // FIFO full and empty flags
    assign wfull = (wptr_bin_next == {~rptr_bin_synced[ADDR_MSB], rptr_bin_synced[ADDR_MSB-1:0]});
    assign rempty = (rptr_bin_next == {~wptr_bin_synced[ADDR_MSB], wptr_bin_synced[ADDR_MSB-1:0]});

    // Memory write
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr_bin[ADDR_MSB-1:0]] <= wdata;
        end
    end

    // Memory read
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata <= mem[rptr_bin[ADDR_MSB-1:0]];
        end
    end

    // Debug outputs
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;

endmodule
