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
    reg [ADDR_WIDTH:0] rptr_w;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_r;

    // Synchronizers
    reg [ADDR_WIDTH:0] wptr_sync [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] rptr_sync [0:SYNC_STAGES-1];

    // Write pointer increment
    wire winc_eff = winc && !wfull;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (winc_eff)
            wptr <= wptr + 1'b1;
    end

    // Read pointer increment
    wire rinc_eff = rinc && !rempty;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (rinc_eff)
            rptr <= rptr + 1'b1;
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Memory read
    always @(posedge rclk) begin
        if (rinc_eff)
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Synchronize wptr to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {(ADDR_WIDTH+1){1'b0}};
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
                rptr_sync[i] <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    // Flags
    assign wfull  = (wptr[ADDR_WIDTH] != rptr_sync[SYNC_STAGES-1][ADDR_WIDTH]) &&
                    (wptr[ADDR_WIDTH-1:0] == rptr_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0]);

    assign rempty = (rptr == wptr_sync[SYNC_STAGES-1]);

    // Pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
