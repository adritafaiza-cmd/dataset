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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Write domain
    reg [PTR_WIDTH-1:0] wptr;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [PTR_WIDTH-1:0] rptr;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Synchronizers
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Write domain logic
    wire wfull_internal;
    wire winc_valid;

    assign wfull = wfull_internal;
    assign waddr = wptr;

    // Full condition: write pointer has lapped read pointer by DEPTH
    // wptr - rptr_synced == DEPTH
    wire [PTR_WIDTH-1:0] wptr_minus_rptr;
    assign wptr_minus_rptr = wptr - rptr_sync[SYNC_STAGES-1];
    assign wfull_internal = (wptr_minus_rptr == DEPTH);

    assign winc_valid = winc & ~wfull;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else if (winc_valid) begin
            wptr <= wptr + 1'b1;
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read domain logic
    wire rempty_internal;
    wire rinc_valid;

    assign rempty = rempty_internal;
    assign raddr = rptr;

    // Empty condition: read pointer equals write pointer
    assign rempty_internal = (rptr == wptr_sync[SYNC_STAGES-1]);

    assign rinc_valid = rinc & ~rempty;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
            rdata_reg <= {DATA_WIDTH{1'b0}};
        end else if (rinc_valid) begin
            rptr <= rptr + 1'b1;
            rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    assign rdata = rdata_reg;

    // Synchronize wptr to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    // Synchronize rptr to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

endmodule
