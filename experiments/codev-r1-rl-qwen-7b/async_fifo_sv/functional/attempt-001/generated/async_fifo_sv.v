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

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    // Write domain signals
    reg [ADDR_WIDTH:0] wbin;
    reg [ADDR_WIDTH:0] wgray;
    wire [ADDR_WIDTH:0] wbin_next;
    wire [ADDR_WIDTH:0] wgray_next;

    // Read domain signals
    reg [ADDR_WIDTH:0] rbin;
    reg [ADDR_WIDTH:0] rgray;
    wire [ADDR_WIDTH:0] rbin_next;
    wire [ADDR_WIDTH:0] rgray_next;

    // Synchronization registers
    reg [ADDR_WIDTH:0] rgray_sync [0:SYNC_STAGES-1];
    reg [ADDR_WIDTH:0] wgray_sync [0:SYNC_STAGES-1];

    // Gray to binary conversion function
    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
        reg [ADDR_WIDTH:0] bin;
        integer i;
        begin
            bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // Write domain logic
    // Synchronize read gray to write domain
    integer i;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                rgray_sync[i] <= 0;
        end else begin
            rgray_sync[0] <= rgray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                rgray_sync[i] <= rgray_sync[i-1];
        end
    end

    // Convert synchronized read gray to binary
    wire [ADDR_WIDTH:0] rbin_sync = gray2bin(rgray_sync[SYNC_STAGES-1]);

    // Full condition
    wire full_condition = ( (wbin - rbin_sync) >= (1 << ADDR_WIDTH) );

    // Write pointer update
    assign wbin_next = wbin + (winc && !wfull);
    assign wgray_next = wbin_next ^ (wbin_next >> 1);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= 0;
            wgray <= 0;
        end else begin
            wbin <= wbin_next;
            wgray <= wgray_next;
        end
    end

    // Read domain logic
    // Synchronize write gray to read domain
    integer j;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (j = 0; j < SYNC_STAGES; j = j + 1)
                wgray_sync[j] <= 0;
        end else begin
            wgray_sync[0] <= wgray;
            for (j = 1; j < SYNC_STAGES; j = j + 1)
                wgray_sync[j] <= wgray_sync[j-1];
        end
    end

    // Convert synchronized write gray to binary
    wire [ADDR_WIDTH:0] wbin_sync = gray2bin(wgray_sync[SYNC_STAGES-1]);

    // Empty condition
    wire empty_condition = (rbin == wbin_sync);

    // Read pointer update
    assign rbin_next = rinc && !rempty ? rbin + 1 : rbin;
    assign rgray_next = rbin_next ^ (rbin_next >> 1);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= 0;
            rgray <= 0;
        end else begin
            rbin <= rbin_next;
            rgray <= rgray_next;
        end
    end

    // Assign outputs
    assign wfull = full_condition;
    assign rempty = empty_condition;

    // Memory write
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wbin[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Memory read
    assign rdata = mem[rbin[ADDR_WIDTH-1:0]];

    // Address outputs
    assign waddr = wbin;
    assign raddr = rbin;

endmodule
