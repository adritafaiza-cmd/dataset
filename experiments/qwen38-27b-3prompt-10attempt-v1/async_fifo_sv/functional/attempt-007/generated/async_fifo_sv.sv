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

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write domain
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr_w; // Read pointer synchronized to write domain

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_r; // Write pointer synchronized to read domain

    // Synchronization registers
    reg [ADDR_WIDTH:0] wptr_sync [0:SYNC_STAGES];
    reg [ADDR_WIDTH:0] rptr_sync [0:SYNC_STAGES];

    // Write domain logic
    wire winc_eff = winc & ~wfull;
    wire wfull = (wptr[ADDR_WIDTH] != rptr_w[ADDR_WIDTH]) &&
                 (wptr[ADDR_WIDTH-1:0] == rptr_w[ADDR_WIDTH-1:0]);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            rptr_w <= 0;
        end else begin
            if (winc_eff)
                wptr <= wptr + 1;
            // rptr_w is updated by synchronization
        end
    end

    // Synchronize rptr to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync[0] <= 0;
            for (int i = 1; i < SYNC_STAGES; i++)
                rptr_sync[i] <= 0;
        end else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i++)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    assign rptr_w = rptr_sync[SYNC_STAGES-1];

    // Write to memory
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read domain logic
    wire rinc_eff = rinc & ~rempty;
    wire rempty = (rptr == wptr_r);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            wptr_r <= 0;
        end else begin
            if (rinc_eff)
                rptr <= rptr + 1;
            // wptr_r is updated by synchronization
        end
    end

    // Synchronize wptr to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync[0] <= 0;
            for (int i = 1; i < SYNC_STAGES; i++)
                wptr_sync[i] <= 0;
        end else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i++)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    assign wptr_r = wptr_sync[SYNC_STAGES-1];

    // Read data
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Debug outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
