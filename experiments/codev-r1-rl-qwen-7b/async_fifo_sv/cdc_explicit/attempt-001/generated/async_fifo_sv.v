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

    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Pointers
    reg [PTR_WIDTH-1:0] wptr, rptr;

    // Gray code pointers
    reg [PTR_WIDTH-1:0] wgray, rgray;

    // Synchronized pointers
    reg [PTR_WIDTH-1:0] rgray_sync1, rgray_sync2;
    reg [PTR_WIDTH-1:0] wgray_sync1, wgray_sync2;

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    // Write domain logic
    wire [PTR_WIDTH-1:0] wgraynext = bin2gray(wptr + 1);

    // Read domain logic
    wire [PTR_WIDTH-1:0] rgraynext = bin2gray(rptr + 1);

    // Convert binary to gray code
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else begin
            if (winc && !wfull) begin
                wptr <= wptr + 1;
            end
        end
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else begin
            if (rinc && !rempty) begin
                rptr <= rptr + 1;
            end
        end
    end

    // Convert pointers to gray
    always @* begin
        wgray = bin2gray(wptr);
        rgray = bin2gray(rptr);
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_sync1 <= 0;
            rgray_sync2 <= 0;
        end else begin
            rgray_sync1 <= rgray;
            rgray_sync2 <= rgray_sync1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_sync1 <= 0;
            wgray_sync2 <= 0;
        end else begin
            wgray_sync1 <= wgray;
            wgray_sync2 <= wgray_sync1;
        end
    end

    // Full condition
    assign wfull = (wgraynext == { ~rgray_sync2[PTR_WIDTH-1], ~rgray_sync2[PTR_WIDTH-2], rgray_sync2[PTR_WIDTH-3:0] });

    // Empty condition
    assign rempty = (rgray == wgray_sync2);

    // Write to memory
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read from memory
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // Assign outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
