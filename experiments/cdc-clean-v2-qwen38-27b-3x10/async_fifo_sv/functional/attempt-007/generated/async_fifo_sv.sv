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
    reg [ADDR_WIDTH:0] rptr_w_sync;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_r_sync;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Synchronizer signals
    reg [ADDR_WIDTH:0] wptr_r_sync_reg [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] rptr_w_sync_reg [0:SYNC_STAGES-1];

    // Write pointer increment
    wire winc_eff = winc & ~wfull;

    // Read pointer increment
    wire rinc_eff = rinc & ~rempty;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {(ADDR_WIDTH+1){1'b0}};
        end else if (winc_eff) begin
            wptr <= wptr + 1'b1;
        end
    end

    // Write to memory
    always @(posedge wclk) begin
        if (winc_eff) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_w_sync_reg[0] <= {(ADDR_WIDTH+1){1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                rptr_w_sync_reg[i] <= {(ADDR_WIDTH+1){1'b0}};
            end
        end else begin
            rptr_w_sync_reg[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                rptr_w_sync_reg[i] <= rptr_w_sync_reg[i-1];
            end
        end
    end

    assign rptr_w_sync = rptr_w_sync_reg[SYNC_STAGES-1];

    // Full condition: write pointer has lapped read pointer by DEPTH
    // wfull when wptr[ADDR_WIDTH] != rptr_w_sync[ADDR_WIDTH] and wptr[ADDR_WIDTH-1:0] == rptr_w_sync[ADDR_WIDTH-1:0]
    assign wfull = (wptr[ADDR_WIDTH] != rptr_w_sync[ADDR_WIDTH]) && 
                   (wptr[ADDR_WIDTH-1:0] == rptr_w_sync[ADDR_WIDTH-1:0]);

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {(ADDR_WIDTH+1){1'b0}};
            rdata_reg <= {DATA_WIDTH{1'b0}};
        end else if (rinc_eff) begin
            rptr <= rptr + 1'b1;
            rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_r_sync_reg[0] <= {(ADDR_WIDTH+1){1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                wptr_r_sync_reg[i] <= {(ADDR_WIDTH+1){1'b0}};
            end
        end else begin
            wptr_r_sync_reg[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                wptr_r_sync_reg[i] <= wptr_r_sync_reg[i-1];
            end
        end
    end

    assign wptr_r_sync = wptr_r_sync_reg[SYNC_STAGES-1];

    // Empty condition: write pointer equals read pointer
    assign rempty = (wptr_r_sync == rptr);

    // Outputs
    assign waddr = wptr;
    assign raddr = rptr;
    assign rdata = rdata_reg;

endmodule
