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
    reg [ADDR_WIDTH:0] rptr_gray_w_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] rptr_bin_w;

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_r;
    reg [ADDR_WIDTH:0] wptr_gray_r_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] wptr_bin_r;

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary to Gray conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to Binary conversion
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        begin
            gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else begin
            if (winc && !wfull) begin
                wptr <= wptr + 1;
                wptr_gray <= bin2gray(wptr + 1);
            end
        end
    end

    // Write memory
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Synchronize read pointer gray to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w_sync[0] <= 0;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_gray_w_sync[i] <= 0;
        end else begin
            rptr_gray_w_sync[0] <= rptr_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_gray_w_sync[i] <= rptr_gray_w_sync[i-1];
        end
    end

    assign rptr_gray_w = rptr_gray_w_sync[SYNC_STAGES-1];
    assign rptr_bin_w = gray2bin(rptr_gray_w);

    // Full condition: write pointer gray MSB and second MSB differ from read pointer gray,
    // and the remaining bits are equal
    assign wfull = (wptr_gray == {~rptr_gray_w[ADDR_WIDTH:ADDR_WIDTH-1], rptr_gray_w[ADDR_WIDTH-2:0]});

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else begin
            if (rinc && !rempty) begin
                rptr <= rptr + 1;
                rptr_gray <= bin2gray(rptr + 1);
            end
        end
    end

    // Synchronize write pointer gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r_sync[0] <= 0;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_gray_r_sync[i] <= 0;
        end else begin
            wptr_gray_r_sync[0] <= wptr_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_gray_r_sync[i] <= wptr_gray_r_sync[i-1];
        end
    end

    assign wptr_gray_r = wptr_gray_r_sync[SYNC_STAGES-1];
    assign wptr_bin_r = gray2bin(wptr_gray_r);

    // Empty condition: write pointer gray equals read pointer gray
    assign rempty = (wptr_gray_r == rptr_gray);

    // Read data
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Debug pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
