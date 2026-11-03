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
    reg [PTR_WIDTH-1:0] rptr_w;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [PTR_WIDTH-1:0] rptr;
    reg [PTR_WIDTH-1:0] wptr_r;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg rdata_valid;

    // Synchronization registers for write pointer to read domain
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];

    // Synchronization registers for read pointer to write domain
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Synchronization for reset signals
    reg wrst_n_sync [0:SYNC_STAGES-1];
    reg rrst_n_sync [0:SYNC_STAGES-1];

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
            rptr_w <= {PTR_WIDTH{1'b0}};
        end else begin
            if (winc && !wfull) begin
                mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
                wptr <= wptr + 1'b1;
            end
            // Synchronize read pointer
            rptr_w <= rptr_sync[SYNC_STAGES-1];
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
            wptr_r <= {PTR_WIDTH{1'b0}};
            rdata_reg <= {DATA_WIDTH{1'b0}};
            rdata_valid <= 1'b0;
        end else begin
            // Synchronize write pointer
            wptr_r <= wptr_sync[SYNC_STAGES-1];

            if (rinc && !rempty) begin
                rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
                rdata_valid <= 1'b1;
                rptr <= rptr + 1'b1;
            end
        end
    end

    // Synchronize write pointer to read domain
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

    // Synchronize read pointer to write domain
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

    // Synchronize write reset to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wrst_n_sync[i] <= 1'b0;
        end else begin
            wrst_n_sync[0] <= wrst_n;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wrst_n_sync[i] <= wrst_n_sync[i-1];
        end
    end

    // Synchronize read reset to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rrst_n_sync[i] <= 1'b0;
        end else begin
            rrst_n_sync[0] <= rrst_n;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rrst_n_sync[i] <= rrst_n_sync[i-1];
        end
    end

    // Full and empty flags
    assign wfull = (wptr - rptr_w) == DEPTH;
    assign rempty = (rptr == wptr_r);

    // Outputs
    assign waddr = wptr;
    assign raddr = rptr;
    assign rdata = rdata_reg;

endmodule
