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

    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH:0] wptr, rptr, wptr_gray, rptr_gray, rptr_gray_sync [SYNC_STAGES-1:0];

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
        end
    end

    // Gray code conversion for pointers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray <= 0;
        end else begin
            wptr_gray <= (wptr >> 1) ^ wptr;
        end
    end

    // Synchronize wptr_gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray_sync[0] <= 0;
        end else begin
            rptr_gray_sync[0] <= wptr_gray;
        end
    end

    // Additional synchronization stages
    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    rptr_gray_sync[i] <= 0;
                end else begin
                    rptr_gray_sync[i] <= rptr_gray_sync[i-1];
                end
            end
        end
    endgenerate

    // Convert synchronized gray code back to binary
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray <= 0;
        end else begin
            rptr_gray <= rptr_gray_sync[SYNC_STAGES-1];
        end
    end

    // Binary conversion
    always @(*) begin
        reg [ADDR_WIDTH:0] temp = rptr_gray;
        reg [ADDR_WIDTH:0] mask = 1;
        integer j;
        for (j = 0; j < ADDR_WIDTH; j = j + 1) begin
            temp = temp ^ (temp >> mask);
            mask = mask << 1;
        end
        rptr = temp;
    end

    // Write data to memory
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read data from memory
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // FIFO full and empty flags
    assign wfull = (wptr[ADDR_WIDTH:ADDR_WIDTH-1] != rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH:ADDR_WIDTH-1]) && (wptr[ADDR_WIDTH-1:0] == rptr_gray_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0]);
    assign rempty = (wptr_gray_sync[SYNC_STAGES-1] == rptr_gray);

    // Debug outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
