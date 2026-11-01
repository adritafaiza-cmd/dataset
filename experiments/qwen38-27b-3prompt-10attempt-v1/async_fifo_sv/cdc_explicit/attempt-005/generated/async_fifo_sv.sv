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
    reg [ADDR_WIDTH:0] wptr_sync_r; // synchronized read pointer in write domain
    reg [ADDR_WIDTH:0] wptr_sync_r_next;
    reg [ADDR_WIDTH:0] wptr_sync_r_1;
    reg [ADDR_WIDTH:0] wptr_sync_r_2;

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] rptr_sync_w; // synchronized write pointer in read domain
    reg [ADDR_WIDTH:0] rptr_sync_w_next;
    reg [ADDR_WIDTH:0] rptr_sync_w_1;
    reg [ADDR_WIDTH:0] rptr_sync_w_2;

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wvalid = winc & ~wfull;
    wire rvalid = rinc & ~rempty;

    // Full condition: write pointer has lapped read pointer by DEPTH
    wire wfull = (wptr[ADDR_WIDTH] != wptr_sync_r[ADDR_WIDTH]) &&
                 (wptr[ADDR_WIDTH-1:0] == wptr_sync_r[ADDR_WIDTH-1:0]);

    // Empty condition: read pointer equals write pointer
    wire rempty = (rptr == rptr_sync_w);

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

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_sync_r_1 <= {(ADDR_WIDTH+1){1'b0}};
            wptr_sync_r_2 <= {(ADDR_WIDTH+1){1'b0}};
            wptr_sync_r   <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wptr_sync_r_1 <= rptr;
            wptr_sync_r_2 <= wptr_sync_r_1;
            wptr_sync_r   <= wptr_sync_r_2;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_sync_w_1 <= {(ADDR_WIDTH+1){1'b0}};
            rptr_sync_w_2 <= {(ADDR_WIDTH+1){1'b0}};
            rptr_sync_w   <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rptr_sync_w_1 <= wptr;
            rptr_sync_w_2 <= rptr_sync_w_1;
            rptr_sync_w   <= rptr_sync_w_2;
        end
    end

    // Memory write
    always @(posedge wclk) begin
        if (wvalid)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Memory read
    always @(posedge rclk) begin
        if (rvalid)
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Debug outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
