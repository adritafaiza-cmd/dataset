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

    // Write domain
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_gray_sync [SYNC_STAGES-1:0];
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

    // Read domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_gray_sync [SYNC_STAGES-1:0];

    // Synchronization
    reg [ADDR_WIDTH-1:0] wptr_gray_sync_r [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_gray_sync_w [SYNC_STAGES-1:0];

    // Flags
    reg wfull_reg;
    reg rempty_reg;

    // Assign outputs
    assign wfull = wfull_reg;
    assign waddr = {1'b0, wptr};
    assign rdata = mem[rptr];
    assign rempty = rempty_reg;
    assign raddr = {1'b0, rptr};

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wfull_reg <= 0;
            for (int i = 0; i < SYNC_STAGES; i++) begin
                wptr_gray_sync[i] <= 0;
            end
        end else if (winc && ~wfull_reg) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= gray_encode(wptr);
            wfull_reg <= (wptr == 2**ADDR_WIDTH - 1);
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rempty_reg <= 1;
            for (int i = 0; i < SYNC_STAGES; i++) begin
                rptr_gray_sync[i] <= 0;
            end
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            rptr_gray <= gray_encode(rptr);
            rempty_reg <= (rptr == 2**ADDR_WIDTH - 1);
        end
    end

    // Synchronization
    always @(posedge wclk) begin
        wptr_gray_sync[0] <= wptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_gray_sync[i] <= wptr_gray_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        rptr_gray_sync[0] <= rptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_gray_sync[i] <= rptr_gray_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        wptr_gray_sync_r[0] <= wptr_gray_sync[SYNC_STAGES-1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_gray_sync_r[i] <= wptr_gray_sync_r[i-1];
        end
    end

    always @(posedge wclk) begin
        rptr_gray_sync_w[0] <= rptr_gray_sync[SYNC_STAGES-1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_gray_sync_w[i] <= rptr_gray_sync_w[i-1];
        end
    end

    // Gray encoding
    function [ADDR_WIDTH-1:0] gray_encode;
        input [ADDR_WIDTH-1:0] bin;
        gray_encode = (bin >> 1) ^ bin;
    endfunction

endmodule
