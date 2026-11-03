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
    logic [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];
    logic [ADDR_WIDTH:0] wp_addr_sync [0:SYNC_STAGES-1];
    logic [ADDR_WIDTH:0] rp_addr_sync [0:SYNC_STAGES-1];
    logic [ADDR_WIDTH:0] wp_addr;
    logic [ADDR_WIDTH:0] rp_addr;
    logic wp_full;
    logic rp_empty;

    // Write pointer logic
    assign wp_addr = wp_addr_sync[SYNC_STAGES-1];
    assign waddr = wp_addr;

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wp_addr_sync <= {SYNC_STAGES{0}};
        end else begin
            if (winc && !wp_full) begin
                wp_addr_sync[0] <= wp_addr_sync[SYNC_STAGES-1] + 1;
            end
            if (SYNC_STAGES > 1) begin
                wp_addr_sync[1:SYNC_STAGES-1] <= wp_addr_sync[0:SYNC_STAGES-2];
            end
        end
    end

    // Read pointer logic
    assign rp_addr = rp_addr_sync[SYNC_STAGES-1];
    assign raddr = rp_addr;

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rp_addr_sync <= {SYNC_STAGES{0}};
        end else begin
            if (rinc && !rp_empty) begin
                rp_addr_sync[0] <= rp_addr_sync[SYNC_STAGES-1] + 1;
            end
            if (SYNC_STAGES > 1) begin
                rp_addr_sync[1:SYNC_STAGES-1] <= rp_addr_sync[0:SYNC_STAGES-2];
            end
        end
    end

    // FIFO memory
    assign wfull = (wp_addr + 1 == rp_addr) || (wp_addr == 2**ADDR_WIDTH - 1 && rp_addr == 0);
    assign rp_empty = wp_addr == rp_addr;

    // Data read and write
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '{default: 0};
        end else if (winc && !wp_full) begin
            mem[wp_addr] <= wdata;
        end
    end

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rp_empty) begin
            rdata <= mem[rp_addr];
        end
    end

endmodule
