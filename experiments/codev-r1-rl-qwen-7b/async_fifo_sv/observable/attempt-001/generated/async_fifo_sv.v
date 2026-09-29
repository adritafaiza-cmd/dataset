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

    // Memory declaration
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    // Write domain signals
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr_sync [SYNC_STAGES-1:0];

    // Read domain signals
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_sync [SYNC_STAGES-1:0];

    // Full and empty conditions
    wire full_condition;
    wire empty_condition;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
        end
    end

    // Read pointer synchronization to write domain
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_rd
            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n) begin
                    rptr_sync[i] <= 0;
                end else begin
                    if (i == 0)
                        rptr_sync[i] <= rptr;
                    else
                        rptr_sync[i] <= rptr_sync[i-1];
                end
            end
        end
    endgenerate

    // Full condition
    assign full_condition = ( (wptr[ADDR_WIDTH] != rptr_sync[SYNC_STAGES-1][ADDR_WIDTH]) &&
                              (wptr[ADDR_WIDTH-1:0] == rptr_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0]) );

    assign wfull = full_condition;

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
        end
    end

    // Write pointer synchronization to read domain
    generate
        genvar j;
        for (j = 0; j < SYNC_STAGES; j = j + 1) begin : sync_wr
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    wptr_sync[j] <= 0;
                end else begin
                    if (j == 0)
                        wptr_sync[j] <= wptr;
                    else
                        wptr_sync[j] <= wptr_sync[j-1];
                end
            end
        end
    endgenerate

    // Empty condition
    assign empty_condition = (rptr == wptr_sync[SYNC_STAGES-1]);

    assign rempty = empty_condition;

    // Memory write
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Memory read
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Assign outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
