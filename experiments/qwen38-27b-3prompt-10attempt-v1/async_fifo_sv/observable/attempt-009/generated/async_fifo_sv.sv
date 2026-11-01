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

    localparam DEPTH = 1 << ADDR_WIDTH;

    // Write domain
    reg [ADDR_WIDTH:0] wptr;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Synchronizers
    reg [ADDR_WIDTH:0] rptr_sync [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] wptr_sync [0:SYNC_STAGES-1];

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
        else if (winc && !wfull)
            wptr <= wptr + 1'b1;
    end

    // Write memory
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {1'b0, {ADDR_WIDTH{1'b0}}};
        else if (rinc && !rempty)
            rptr <= rptr + 1'b1;
    end

    // Read data
    always @(posedge rclk) begin
        if (rinc && !rempty)
            rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end
        else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {1'b0, {ADDR_WIDTH{1'b0}}};
        end
        else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    // Full flag: write pointer has lapped read pointer by DEPTH
    // Compare the upper bits (gray code style comparison)
    wire [ADDR_WIDTH:0] rptr_w = rptr_sync[SYNC_STAGES-1];
    wire [ADDR_WIDTH:0] wptr_r = wptr_sync[SYNC_STAGES-1];

    assign wfull = (wptr[ADDR_WIDTH] != rptr_w[ADDR_WIDTH]) &&
                   (wptr[ADDR_WIDTH-1:0] == rptr_w[ADDR_WIDTH-1:0]);

    assign rempty = (wptr_r == rptr);

    assign waddr = wptr;
    assign raddr = rptr;
    assign rdata = rdata_reg;

endmodule
