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

    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0] rptr_gray_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] wptr_gray_sync [SYNC_STAGES-1:0];

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                wptr_gray_sync[i] <= 0;
            end
        end else begin
            wptr_gray_sync[0] <= rptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                wptr_gray_sync[i] <= wptr_gray_sync[i-1];
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                rptr_gray_sync[i] <= 0;
            end
        end else begin
            rptr_gray_sync[0] <= wptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                rptr_gray_sync[i] <= rptr_gray_sync[i-1];
            end
        end
    end

    // Binary conversion
    wire [ADDR_WIDTH:0] wptr_bin_sync;
    wire [ADDR_WIDTH:0] rptr_bin_sync;

    assign wptr_bin_sync = {wptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH], wptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0] ^ (wptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH:1] >> 1)};
    assign rptr_bin_sync = {rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH], rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0] ^ (rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH:1] >> 1)};

    // Full and empty flags
    assign wfull = (wptr_bin_sync[ADDR_WIDTH:ADDR_WIDTH-1] == {~rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH], rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH-1]});
    assign rempty = (wptr_gray_sync[SYNC_STAGES-1] == rptr_bin_sync[ADDR_WIDTH:0]);

    // Read data output
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Debug outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
