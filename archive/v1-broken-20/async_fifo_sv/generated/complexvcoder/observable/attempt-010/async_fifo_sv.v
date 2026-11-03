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

    localparam DEPTH = 2**ADDR_WIDTH;
    localparam ADDR_WIDTH_SYNC = ADDR_WIDTH + SYNC_STAGES;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg [DATA_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    reg [DATA_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    assign waddr = wptr;
    assign raddr = rptr;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull <= 1'b0;
        end else begin
            if (winc && !wfull) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                if (wptr == DEPTH - 1)
                    wptr <= 0;
                wfull <= (wptr == rptr);
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty <= 1'b1;
        end else begin
            if (rinc && !rempty) begin
                rptr <= rptr + 1;
                if (rptr == DEPTH - 1)
                    rptr <= 0;
                rempty <= (wptr == rptr);
            end
        end
    end

    // Clock domain crossing for write pointer
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : wptr_sync_gen
            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n) begin
                    wptr_sync[i] <= 0;
                end else begin
                    wptr_sync[i] <= wptr;
                end
            end
        end
    endgenerate

    // Clock domain crossing for read pointer
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : rptr_sync_gen
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    rptr_sync[i] <= 0;
                end else begin
                    rptr_sync[i] <= rptr;
                end
            end
        end
    endgenerate

    assign wdata_sync = wdata;
    assign rdata_sync = rdata;

endmodule
