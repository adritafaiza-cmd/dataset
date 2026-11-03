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
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0]  wptr;
    reg [PTR_WIDTH-1:0]  rptr_w; // read pointer synchronized to write domain

    // Read domain
    reg [PTR_WIDTH-1:0]  rptr;
    reg [PTR_WIDTH-1:0]  wptr_r; // write pointer synchronized to read domain

    // Synchronizer for write pointer to read domain
    reg [PTR_WIDTH-1:0] wptr_r_sync [0:SYNC_STAGES-1];
    // Synchronizer for read pointer to write domain
    reg [PTR_WIDTH-1:0] rptr_w_sync [0:SYNC_STAGES-1];

    // Write domain logic
    wire wfull = (wptr == rptr_w) ? 1'b0 : (wptr[PTR_WIDTH-1] != rptr_w[PTR_WIDTH-1]) && (wptr[ADDR_WIDTH-1:0] == rptr_w[ADDR_WIDTH-1:0]);
    
    // Actually, for a FIFO of size 2**ADDR_WIDTH, we use an extra bit for full/empty detection.
    // Full: wptr and rptr have same lower ADDR_WIDTH bits, but different MSB, and wptr MSB is ahead.
    // Let's use the standard Gray code approach or binary with extra bit.
    // Using binary with extra bit:
    // wfull: wptr[ADDR_WIDTH] != rptr_w[ADDR_WIDTH] && wptr[ADDR_WIDTH-1:0] == rptr_w[ADDR_WIDTH-1:0]
    // rempty: wptr_r == rptr

    wire wfull_internal = (wptr[ADDR_WIDTH] != rptr_w[ADDR_WIDTH]) && (wptr[ADDR_WIDTH-1:0] == rptr_w[ADDR_WIDTH-1:0]);
    wire rempty_internal = (wptr_r == rptr);

    assign wfull = wfull_internal;
    assign rempty = rempty_internal;
    assign waddr = wptr[ADDR_WIDTH-1:0];
    assign raddr = rptr[ADDR_WIDTH-1:0];

    // Write operation
    wire wvalid = winc & ~wfull;
    
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else if (wvalid) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1'b1;
        end
    end

    // Read operation
    wire rvalid = rinc & ~rempty;
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
        end else if (rvalid) begin
            rptr <= rptr + 1'b1;
        end
    end

    // Read data output
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_r_sync[0] <= {PTR_WIDTH{1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                wptr_r_sync[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            wptr_r_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                wptr_r_sync[i] <= wptr_r_sync[i-1];
            end
        end
    end
    assign wptr_r = wptr_r_sync[SYNC_STAGES-1];

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_w_sync[0] <= {PTR_WIDTH{1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                rptr_w_sync[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            rptr_w_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                rptr_w_sync[i] <= rptr_w_sync[i-1];
            end
        end
    end
    assign rptr_w = rptr_w_sync[SYNC_STAGES-1];

endmodule
