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

    // Write Domain
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_gray_sync;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wcount;
    reg wfull_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wcount <= 0;
            wfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            wptr <= wptr + 1;
            wcount <= wcount + 1;
            mem[wptr] <= wdata;
        end else if (~winc && wcount > 0) begin
            wcount <= wcount;
        end else begin
            wcount <= wcount;
        end
    end

    always @(posedge wclk) begin
        wptr_gray <= gray_encode(wptr);
    end

    // Synchronize wptr_gray to read domain
    reg [ADDR_WIDTH-1:0] wptr_gray_sync_reg [SYNC_STAGES-1:0];
    always @(posedge rclk) begin
        wptr_gray_sync_reg[0] <= wptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_gray_sync_reg[i] <= wptr_gray_sync_reg[i-1];
        end
        wptr_gray_sync <= wptr_gray_sync_reg[SYNC_STAGES-1];
    end

    // Read Domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_gray_sync;
    reg [ADDR_WIDTH:0] rcount;
    reg rempty_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rcount <= 0;
            rempty_reg <= 1;
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            rcount <= rcount - 1;
        end else if (~rinc && rcount < 2**ADDR_WIDTH) begin
            rcount <= rcount;
        end else begin
            rcount <= rcount;
        end
    end

    always @(posedge rclk) begin
        rptr_gray <= gray_encode(rptr);
    end

    // Synchronize rptr_gray to write domain
    reg [ADDR_WIDTH-1:0] rptr_gray_sync_reg [SYNC_STAGES-1:0];
    always @(posedge wclk) begin
        rptr_gray_sync_reg[0] <= rptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_gray_sync_reg[i] <= rptr_gray_sync_reg[i-1];
        end
        rptr_gray_sync <= rptr_gray_sync_reg[SYNC_STAGES-1];
    end

    // Output Logic
    assign wfull = wfull_reg;
    assign waddr = {wcount, wptr};
    assign rdata = mem[rptr];
    assign rempty = rempty_reg;
    assign raddr = {rcount, rptr};

    // Full and Empty Logic
    always @(posedge wclk) begin
        if (wcount == 2**ADDR_WIDTH) begin
            wfull_reg <= 1;
        end else begin
            wfull_reg <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rcount == 0) begin
            rempty_reg <= 1;
        end else begin
            rempty_reg <= 0;
        end
    end

    // Gray Encoding Function
    function reg [ADDR_WIDTH-1:0] gray_encode;
        input [ADDR_WIDTH-1:0] bin;
        reg [ADDR_WIDTH-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

endmodule
