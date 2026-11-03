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

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= '0;
            wptr_gray <= '0;
            for (int i = 0; i < SYNC_STAGES-1; i++) begin
                wptr_gray_sync[i] <= '0;
            end
        end else if (winc && ~wfull) begin
            wptr <= wptr + 1;
            wptr_gray <= gray_encode(wptr);
            for (int i = 0; i < SYNC_STAGES-2; i++) begin
                wptr_gray_sync[i] <= wptr_gray_sync[i+1];
            end
            wptr_gray_sync[SYNC_STAGES-2] <= wptr_gray;
        end
    end

    // Read domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_gray_sync [SYNC_STAGES-1:0];

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= '0;
            rptr_gray <= '0;
            for (int i = 0; i < SYNC_STAGES-1; i++) begin
                rptr_gray_sync[i] <= '0;
            end
        end else if (rinc && ~rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= gray_encode(rptr);
            for (int i = 0; i < SYNC_STAGES-2; i++) begin
                rptr_gray_sync[i] <= rptr_gray_sync[i+1];
            end
            rptr_gray_sync[SYNC_STAGES-2] <= rptr_gray;
        end
    end

    // Data storage
    reg [DATA_WIDTH-1:0] data [2**ADDR_WIDTH-1:0];

    always @(posedge wclk) begin
        if (winc && ~wfull) begin
            data[wptr] <= wdata;
        end
    end

    // Empty and full flags
    assign wfull = (wptr_gray_sync[SYNC_STAGES-2] == rptr_gray_sync[SYNC_STAGES-2]) && (wptr == (1 << ADDR_WIDTH) - 1);
    assign rempty = (wptr_gray_sync[SYNC_STAGES-2] == rptr_gray_sync[SYNC_STAGES-2]) && (wptr == rptr);

    // Read data
    assign rdata = data[rptr];

    // Debug outputs
    assign waddr = {1'b0, wptr};
    assign raddr = {1'b0, rptr};

    // Gray encoding function
    function [ADDR_WIDTH-1:0] gray_encode(input [ADDR_WIDTH-1:0] bin);
        gray_encode = bin ^ (bin >> 1);
    endfunction

endmodule
