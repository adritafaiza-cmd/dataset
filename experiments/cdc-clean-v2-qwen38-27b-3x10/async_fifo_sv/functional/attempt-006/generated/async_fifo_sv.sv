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

    // Gray code pointers
    wire [ADDR_WIDTH:0] wptr_gray;
    wire [ADDR_WIDTH:0] rptr_gray;

    // Synchronized pointers
    reg [ADDR_WIDTH:0] rptr_gray_sync [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] wptr_gray_sync [0:SYNC_STAGES-1];

    // Full/Empty flags
    wire wfull_int;
    wire rempty_int;

    // Write enable
    wire wvalid = winc & ~wfull_int;

    // Read enable
    wire rvalid = rinc & ~rempty_int;

    // Gray code conversion
    assign wptr_gray = wptr ^ (wptr >> 1);
    assign rptr_gray = rptr ^ (rptr >> 1);

    // Write pointer increment
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {PTR_WIDTH{1'b0}};
        else if (wvalid)
            wptr <= wptr + 1'b1;
    end

    // Write data
    always @(posedge wclk) begin
        if (wvalid)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read pointer increment
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {PTR_WIDTH{1'b0}};
        else if (rvalid)
            rptr <= rptr + 1'b1;
    end

    // Read data
    always @(posedge rclk) begin
        if (rvalid)
            rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Synchronize rptr_gray to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync[0] <= {ADDR_WIDTH+1{1'b0}};
            rptr_gray_sync[1] <= {ADDR_WIDTH+1{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rptr_gray_sync[i] <= {ADDR_WIDTH+1{1'b0}};
            end
        end
        else begin
            rptr_gray_sync[0] <= rptr_gray;
            rptr_gray_sync[1] <= rptr_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rptr_gray_sync[i] <= rptr_gray_sync[i-1];
            end
        end
    end

    // Synchronize wptr_gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync[0] <= {ADDR_WIDTH+1{1'b0}};
            wptr_gray_sync[1] <= {ADDR_WIDTH+1{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wptr_gray_sync[i] <= {ADDR_WIDTH+1{1'b0}};
            end
        end
        else begin
            wptr_gray_sync[0] <= wptr_gray;
            wptr_gray_sync[1] <= wptr_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wptr_gray_sync[i] <= wptr_gray_sync[i-1];
            end
        end
    end

    // Full condition: write pointer has lapped read pointer
    // In gray code, full when wptr_gray == rptr_gray_sync[SYNC_STAGES-1] with MSB different
    // Actually, for a FIFO of depth 2^ADDR_WIDTH, we use ADDR_WIDTH+1 bits for pointers.
    // Full: wptr_gray[ADDR_WIDTH] != rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH] && 
    //       wptr_gray[ADDR_WIDTH-1:0] == rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0]
    assign wfull_int = (wptr_gray[ADDR_WIDTH] != rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH]) &&
                       (wptr_gray[ADDR_WIDTH-1:0] == rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0]);

    // Empty condition: read pointer has lapped write pointer
    // Empty: rptr_gray == wptr_gray_sync[SYNC_STAGES-1]
    assign rempty_int = (rptr_gray == wptr_gray_sync[SYNC_STAGES-1]);

    // Outputs
    assign wfull = wfull_int;
    assign waddr = wptr;
    assign rdata = rdata_reg;
    assign rempty = rempty_int;
    assign raddr = rptr;

endmodule
