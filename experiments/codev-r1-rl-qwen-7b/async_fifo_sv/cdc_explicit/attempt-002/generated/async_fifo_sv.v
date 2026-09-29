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

    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // Write domain signals
    reg [PTR_WIDTH-1:0] wptr;
    wire [PTR_WIDTH-1:0] wgray;
    wire [PTR_WIDTH-1:0] wgray_next;
    wire winc_valid = winc && !wfull;

    // Read domain signals
    reg [PTR_WIDTH-1:0] rptr;
    wire [PTR_WIDTH-1:0] rgray;
    wire [PTR_WIDTH-1:0] rgray_next;
    wire rinc_valid = rinc && !rempty;

    // Synchronization registers
    reg [PTR_WIDTH-1:0] rgray_sync [SYNC_STAGES-1:0];
    reg [PTR_WIDTH-1:0] wgray_sync [SYNC_STAGES-1:0];

    // Full and empty flags
    wire wfull_val, rempty_val;

    // Write pointer logic
    wire [PTR_WIDTH-1:0] wbin_next = wptr + (winc_valid ? 1 : 0);
    assign wgray_next = bin2gray(wbin_next);

    // Full condition
    wire [PTR_WIDTH-1:0] rgray_synced = rgray_sync[SYNC_STAGES-1];
    assign wfull_val = (wgray_next == { ~rgray_synced[PTR_WIDTH-1 : PTR_WIDTH-2], rgray_synced[PTR_WIDTH-3 : 0] });

    // Update write pointer
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc_valid) begin
            wptr <= wbin_next;
        end
    end

    // Convert to gray
    assign wgray = bin2gray(wptr);

    // Synchronization of read pointer's gray in write domain
    integer i;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (i=0; i < SYNC_STAGES; i=i+1)
                rgray_sync[i] <= 0;
        end else begin
            rgray_sync[0] <= rgray;
            for (i=1; i < SYNC_STAGES; i=i+1)
                rgray_sync[i] <= rgray_sync[i-1];
        end
    end

    // Read pointer logic
    wire [PTR_WIDTH-1:0] rbin_next = rptr + (rinc_valid ? 1 : 0);
    assign rgray_next = bin2gray(rbin_next);

    // Empty condition
    wire [PTR_WIDTH-1:0] wgray_synced = wgray_sync[SYNC_STAGES-1];
    assign rempty_val = (rgray == wgray_synced);

    // Update read pointer
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc_valid) begin
            rptr <= rbin_next;
        end
    end

    // Convert to gray
    assign rgray = bin2gray(rptr);

    // Synchronization of write pointer's gray in read domain
    integer j;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (j=0; j < SYNC_STAGES; j=j+1)
                wgray_sync[j] <= 0;
        end else begin
            wgray_sync[0] <= wgray;
            for (j=1; j < SYNC_STAGES; j=j+1)
                wgray_sync[j] <= wgray_sync[j-1];
        end
    end

    // Memory
    reg [DATA_WIDTH-1:0] mem [0 : (1 << ADDR_WIDTH) -1];

    // Write to memory
    always @(posedge wclk) begin
        if (winc_valid)
            mem[wptr[ADDR_WIDTH-1 : 0]] <= wdata;
    end

    // Read from memory
    assign rdata = mem[rptr[ADDR_WIDTH-1 : 0]];

    // Assign outputs
    assign wfull = wfull_val;
    assign rempty = rempty_val;
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
