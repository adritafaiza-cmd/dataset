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
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0] rptr_gray_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] wptr_gray_sync [SYNC_STAGES-1:0];

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
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

    // Gray code synchronization for read pointer
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_rptr_gray
            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n) begin
                    wptr_gray_sync[i] <= 0;
                end else begin
                    if (i == 0) begin
                        wptr_gray_sync[i] <= rptr_gray;
                    end else begin
                        wptr_gray_sync[i] <= wptr_gray_sync[i-1];
                    end
                end
            end
        end
    endgenerate

    // Gray code synchronization for write pointer
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_wptr_gray
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

    // Binary conversion of synchronized read pointer
    reg [ADDR_WIDTH:0] rptr_sync;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync <= 0;
        end else begin
            rptr_sync <= gray_to_bin(rptr_gray_sync[SYNC_STAGES-1]);
        end
    end

    // Binary conversion of synchronized write pointer
    reg [ADDR_WIDTH:0] wptr_sync;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync <= 0;
        end else begin
            wptr_sync <= gray_to_bin(wptr_gray_sync[SYNC_STAGES-1]);
        end
    end

    // Gray to binary conversion function
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        begin
            gray_to_bin[0] = gray[0];
            for (i = 1; i <= ADDR_WIDTH; i = i + 1) begin
                gray_to_bin[i] = gray_to_bin[i-1] ^ gray[i];
            end
        end
    endfunction

    // Full flag logic
    assign wfull = (wptr_gray == (rptr_sync ^ (rptr_sync >> 1)));

    // Empty flag logic
    assign rempty = (rptr_gray == (wptr_sync ^ (wptr_sync >> 1)));

    // Read data output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    // Address outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
