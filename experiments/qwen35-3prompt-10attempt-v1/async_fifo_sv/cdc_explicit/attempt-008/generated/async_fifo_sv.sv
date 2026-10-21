```systemverilog
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

    localparam INT_WIDTH = ADDR_WIDTH + 1;
    localparam FIFO_DEPTH = 2**ADDR_WIDTH;
    localparam GRANT_WIDTH = INT_WIDTH;

    // Generate synchronization stages
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stage
            wire wsynced;
            wire rsynced;
            
            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n)
                    wsynced <= 1'b0;
                else
                    wsynced <= winc;
            end

            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n)
                    rsynced <= 1'b0;
                else
                    rsynced <= rinc;
            end
        end
    endgenerate

    // Write pointer and data storage
    reg [INT_WIDTH-1:0] wptr;
    reg [INT_WIDTH-1:0] rptr;
    reg [DATA_WIDTH-1:0] mem[FIFO_DEPTH-1:0];
    reg [INT_WIDTH-1:0] wptr_sync;
    reg [INT_WIDTH-1:1] wptr_sync_msb;
    reg [INT_WIDTH-1:1] rptr_sync_msb;
    reg [INT_WIDTH-1:0] rptr_sync;
    reg wfull_sync;
    reg rempty_sync;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 1'b0;
            wfull <= 1'b0;
        end else begin
            if (winc && !wfull) begin
                wptr <= wptr + 1'b1;
                mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            end
            wfull <= (wptr == (FIFO_DEPTH - 1));
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 1'b0;
            rempty <= 1'b1;
        end else begin
            if (rinc && !rempty) begin
                rptr <= rptr + 1'b1;
            end
            rempty <= (rptr == wptr_sync);
        end
    end

    // Cross-domain synchronization
    // Write pointer MSB synchronization for full detection
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync_msb <= 1'b0;
            wptr_sync <= 1'b0;
            wfull_sync <= 1'b0;
        end else begin
            wptr_sync_msb <= wptr[ADDR_WIDTH];
            wptr_sync <= wptr[ADDR_WIDTH-1:0];
            wfull_sync <= (wptr_sync == (FIFO_DEPTH - 1));
        end
    end

    // Read pointer MSB synchronization for empty detection
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync_msb <= 1'b0;
            rptr_sync <= 1'b0;
            rempty_sync <= 1'b1;
        end else begin
            rptr_sync_msb <= rptr[ADDR_WIDTH];
            rptr_sync <= rptr[ADDR_WIDTH-1:0];
            rempty_sync <= (rptr_sync == wptr_sync);
        end
    end

    // Output assignments
    assign waddr = wptr[ADDR_WIDTH-1:0];
    assign raddr = rptr[ADDR_WIDTH-1:0];
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];
    assign wfull = wfull_sync;
    assign rempty = rempty_sync;

endmodule
```<|im_end|>
