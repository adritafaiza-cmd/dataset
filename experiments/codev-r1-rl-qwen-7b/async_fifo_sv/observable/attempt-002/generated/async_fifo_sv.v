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

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    // Write domain signals
    reg [ADDR_WIDTH:0] wptr;
    wire [ADDR_WIDTH:0] wgray;
    reg [ADDR_WIDTH:0] rgray_sync1, rgray_sync2;

    // Read domain signals
    reg [ADDR_WIDTH:0] rptr;
    wire [ADDR_WIDTH:0] rgray;
    reg [ADDR_WIDTH:0] wgray_sync1, wgray_sync2;

    // Gray code conversion functions
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
        integer i;
        begin
            gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >=0; i = i -1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
        end
    end

    assign wgray = bin2gray(wptr);

    // Synchronize read pointer's gray to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_sync1 <= 0;
            rgray_sync2 <= 0;
        end else begin
            rgray_sync1 <= rgray;
            rgray_sync2 <= rgray_sync1;
        end
    end

    // Full condition
    wire [ADDR_WIDTH:0] rbin = gray2bin(rgray_sync2);
    wire [ADDR_WIDTH:0] wgraynext = bin2gray(wptr + 1);
    assign wfull = (wgraynext == { ~rbin[ADDR_WIDTH], ~rbin[ADDR_WIDTH-1], rbin[ADDR_WIDTH-2:0] });

    // Write address
    assign waddr = wptr;

    // Memory write
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
        end
    end

    assign rgray = bin2gray(rptr);

    // Synchronize write pointer's gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_sync1 <= 0;
            wgray_sync2 <= 0;
        end else begin
            wgray_sync1 <= wgray;
            wgray_sync2 <= wgray_sync1;
        end
    end

    // Empty condition
    wire [ADDR_WIDTH:0] wbin = gray2bin(wgray_sync2);
    assign rempty = (rptr == wbin);

    // Read address
    assign raddr = rptr;

    // Memory read
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

endmodule
