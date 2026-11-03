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
    logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    logic [ADDR_WIDTH:0] wp_raw, rp_raw;
    logic [ADDR_WIDTH:0] wp_sync, rp_sync;
    logic [DATA_WIDTH-1:0] rdata_sync;

    // Write pointer logic
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wp_raw <= 0;
        end else if (winc && !wfull) begin
            wp_raw <= wp_raw + 1;
        end
    end

    // Read pointer logic
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rp_raw <= 0;
        end else if (rinc && !rempty) begin
            rp_raw <= rp_raw + 1;
        end
    end

    // Synchronize write pointer to read clock domain
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i++) begin : wp_sync_gen
            always_ff @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    wp_sync[i] <= 0;
                end else begin
                    wp_sync[i] <= wp_sync[i-1];
                end
            end
        end
    endgenerate

    assign waddr = wp_sync[SYNC_STAGES-1];

    // Synchronize read pointer to write clock domain
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i++) begin : rp_sync_gen
            always_ff @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n) begin
                    rp_sync[i] <= 0;
                end else begin
                    rp_sync[i] <= rp_sync[i-1];
                end
            end
        end
    endgenerate

    assign raddr = rp_sync[SYNC_STAGES-1];

    // FIFO memory logic
    assign mem[wp_raw] <= wdata;

    // FIFO flags logic
    assign wfull = (wp_sync[SYNC_STAGES-1] == rp_sync[SYNC_STAGES-1] + 2**ADDR_WIDTH);
    assign rempty = (wp_sync[SYNC_STAGES-1] == rp_sync[SYNC_STAGES-1]);

    // Synchronize read data to write clock domain
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rdata_sync <= 0;
        end else begin
            rdata_sync <= mem[rp_sync[SYNC_STAGES-1]];
        end
    end

    assign rdata = rdata_sync;

endmodule
