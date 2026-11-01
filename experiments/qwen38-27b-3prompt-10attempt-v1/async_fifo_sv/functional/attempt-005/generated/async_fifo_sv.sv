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

    // Write domain
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] wptr_gray;
    reg [ADDR_WIDTH:0] rptr_gray_w;
    reg [ADDR_WIDTH:0] rptr_gray_w_sync [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] rptr_bin_w;
    reg [ADDR_WIDTH:0] rptr_bin_w_sync [0:SYNC_STAGES-1];

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_r;
    reg [ADDR_WIDTH:0] wptr_gray_r_sync [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] wptr_bin_r;
    reg [ADDR_WIDTH:0] wptr_bin_r_sync [0:SYNC_STAGES-1];

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write enable
    wire w_en = winc & ~wfull;

    // Read enable
    wire r_en = rinc & ~rempty;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        reg [ADDR_WIDTH:0] bin;
        integer i;
        begin
            bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            rptr_gray_w_sync[0] <= 0;
            rptr_gray_w_sync[1] <= 0;
            rptr_bin_w_sync[0] <= 0;
            rptr_bin_w_sync[1] <= 0;
        end else begin
            if (w_en) begin
                wptr <= wptr + 1;
                wptr_gray <= bin2gray(wptr + 1);
            end
            // Synchronize read pointer gray code
            rptr_gray_w_sync[0] <= rptr_gray;
            rptr_gray_w_sync[1] <= rptr_gray_w_sync[0];
            // Synchronize read pointer binary code
            rptr_bin_w_sync[0] <= rptr;
            rptr_bin_w_sync[1] <= rptr_bin_w_sync[0];
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            wptr_gray_r_sync[0] <= 0;
            wptr_gray_r_sync[1] <= 0;
            wptr_bin_r_sync[0] <= 0;
            wptr_bin_r_sync[1] <= 0;
        end else begin
            if (r_en) begin
                rptr <= rptr + 1;
                rptr_gray <= bin2gray(rptr + 1);
            end
            // Synchronize write pointer gray code
            wptr_gray_r_sync[0] <= wptr_gray;
            wptr_gray_r_sync[1] <= wptr_gray_r_sync[0];
            // Synchronize write pointer binary code
            wptr_bin_r_sync[0] <= wptr;
            wptr_bin_r_sync[1] <= wptr_bin_r_sync[0];
        end
    end

    // Full flag: write pointer gray code equals read pointer gray code with MSB different
    wire wfull = (wptr_gray == {~rptr_gray_w_sync[1][ADDR_WIDTH], rptr_gray_w_sync[1][ADDR_WIDTH-1:0]});

    // Empty flag: read pointer gray code equals write pointer gray code
    wire rempty = (rptr_gray == wptr_gray_r_sync[1]);

    // Memory write
    always @(posedge wclk) begin
        if (w_en)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Memory read
    always @(posedge rclk) begin
        if (r_en)
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Debug pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
