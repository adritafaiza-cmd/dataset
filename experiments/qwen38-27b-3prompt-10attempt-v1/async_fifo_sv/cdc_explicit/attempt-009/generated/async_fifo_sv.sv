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
    reg [ADDR_WIDTH:0] wptr_sync_r;
    reg [ADDR_WIDTH:0] wptr_sync_w;
    reg [ADDR_WIDTH:0] wptr_sync_r2;
    reg [ADDR_WIDTH:0] wptr_sync_w2;

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] rptr_sync_w;
    reg [ADDR_WIDTH:0] rptr_sync_r;
    reg [ADDR_WIDTH:0] rptr_sync_w2;
    reg [ADDR_WIDTH:0] rptr_sync_r2;

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wvalid = winc & ~wfull;
    wire rvalid = rinc & ~rempty;

    // Write pointer increment
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (wvalid)
            wptr <= wptr + 1'b1;
    end

    // Read pointer increment
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (rvalid)
            rptr <= rptr + 1'b1;
    end

    // Write to memory
    always @(posedge wclk) begin
        if (wvalid)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read from memory
    always @(posedge rclk) begin
        if (rvalid)
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync_r  <= {(ADDR_WIDTH+1){1'b0}};
            wptr_sync_r2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wptr_sync_r  <= wptr;
            wptr_sync_r2 <= wptr_sync_r;
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync_w  <= {(ADDR_WIDTH+1){1'b0}};
            rptr_sync_w2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rptr_sync_w  <= rptr;
            rptr_sync_w2 <= rptr_sync_w;
        end
    end

    // Full condition: write pointer has lapped read pointer by DEPTH
    // wfull is high when (wptr - rptr_sync_w2) == DEPTH
    // Using two's complement: wptr[ADDR_WIDTH] != rptr_sync_w2[ADDR_WIDTH] && wptr[ADDR_WIDTH-1:0] == rptr_sync_w2[ADDR_WIDTH-1:0]
    assign wfull = (wptr[ADDR_WIDTH] != rptr_sync_w2[ADDR_WIDTH]) && 
                   (wptr[ADDR_WIDTH-1:0] == rptr_sync_w2[ADDR_WIDTH-1:0]);

    // Empty condition: read pointer equals write pointer
    assign rempty = (rptr == wptr_sync_r2);

    // Debug outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
