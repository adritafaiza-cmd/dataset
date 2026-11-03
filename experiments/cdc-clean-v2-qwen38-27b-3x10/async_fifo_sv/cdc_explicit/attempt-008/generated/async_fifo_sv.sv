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

    // Synchronizers for write pointer to read domain
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];

    // Synchronizers for read pointer to write domain
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Write domain logic
    wire wfull_int;
    wire [PTR_WIDTH-1:0] rptr_synced;

    assign rptr_synced = rptr_sync[SYNC_STAGES-1];
    assign wfull_int = (wptr[PTR_WIDTH-1] != rptr_synced[PTR_WIDTH-1]) &&
                       (wptr[PTR_WIDTH-2:0] == rptr_synced[PTR_WIDTH-2:0]);

    assign wfull = wfull_int;
    assign waddr = wptr;

    // Read domain logic
    wire rempty_int;
    wire [PTR_WIDTH-1:0] wptr_synced;

    assign wptr_synced = wptr_sync[SYNC_STAGES-1];
    assign rempty_int = (rptr == wptr_synced);

    assign rempty = rempty_int;
    assign raddr = rptr;
    assign rdata = rdata_reg;

    // Write pointer update
    wire winc_eff = winc & ~wfull_int;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else if (winc_eff) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1'b1;
        end
    end

    // Read pointer update
    wire rinc_eff = rinc & ~rempty_int;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
            rdata_reg <= {DATA_WIDTH{1'b0}};
        end else if (rinc_eff) begin
            rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
            rptr <= rptr + 1'b1;
        end
    end

    // Synchronize write pointer to read domain
    integer i;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_sync[0] <= wptr;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_sync[0] <= rptr;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

endmodule
