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
    localparam AW = ADDR_WIDTH + 1;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [AW-1:0] wptr, rptr;
    reg [AW-1:0] wptr_gray, rptr_gray;
    reg [AW-1:0] rptr_gray_sync [0:SYNC_STAGES-1];

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
        end
    end

    // Gray code synchronization
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    rptr_gray_sync[i] <= 0;
                end else begin
                    if (i == 0) begin
                        rptr_gray_sync[i] <= wptr_gray;
                    end else begin
                        rptr_gray_sync[i] <= rptr_gray_sync[i-1];
                    end
                end
            end
        end
    endgenerate

    // Write full flag
    assign wfull = (wptr_gray == {~rptr_gray_sync[SYNC_STAGES-1][AW-2:0], rptr_gray_sync[SYNC_STAGES-1][AW-1]});

    // Read empty flag
    assign rempty = (rptr_gray == wptr_gray_sync[SYNC_STAGES-1]);

    // Write address
    assign waddr = wptr;

    // Read address
    assign raddr = rptr;

    // Read data
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    // Write data
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

endmodule
