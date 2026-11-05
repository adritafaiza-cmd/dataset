// =============================================================================
// Async FIFO with Gray-coded pointer CDC and dual-clock-domain storage
// =============================================================================
//
// Architecture:
//   - Two independent clock domains (wclk, rclk) with no phase/frequency
//     relationship.
//   - Write pointer (wptr) lives in the write domain; read pointer (rptr)
//     lives in the read domain.
//   - Each pointer is a binary counter with an extra MSB for full/empty
//     detection.  The binary value is converted to Gray code before crossing
//     the clock-domain boundary.
//   - Gray-coded pointers are synchronised into the opposite domain through
//     a SYNC_STAGES-deep shift register (default 2).
//   - Full/empty flags are derived locally in each domain by comparing the
//     local pointer with the synchronised copy of the remote pointer.
//   - Storage is a simple dual-port RAM: one write port (wclk) and one read
//     port (rclk).  The RAM is inferred from a plain always @(posedge) block
//     so that synthesis tools can map it to block RAM / URAM.
//
// CDC safety:
//   - Only Gray-coded pointers cross domains (single-bit change per increment).
//   - Synchroniser depth is configurable via SYNC_STAGES (>= 2 recommended).
//   - No multi-bit signals cross domains.
//   - Reset is asynchronous-assert / synchronous-release in each domain.
//
// =============================================================================

module async_fifo #(
    parameter DATA_WIDTH  = 8,
    parameter ADDR_WIDTH  = 4,
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

    // ------------------------------------------------------------------
    // Write-domain state
    // ------------------------------------------------------------------
    reg [PTR_WIDTH-1:0] wptr_bin;
    wire [PTR_WIDTH-1:0] wptr_gray;

    // ------------------------------------------------------------------
    // Read-domain state
    // ------------------------------------------------------------------
    reg [PTR_WIDTH-1:0] rptr_bin;
    wire [PTR_WIDTH-1:0] rptr_gray;

    // ------------------------------------------------------------------
    // Synchronised pointers (remote copies)
    // ------------------------------------------------------------------
    reg [PTR_WIDTH-1:0] wptr_gray_sync [0:SYNC_STAGES-1];
    reg [PTR_WIDTH-1:0] rptr_gray_sync [0:SYNC_STAGES-1];

    wire [PTR_WIDTH-1:0] wptr_gray_r = wptr_gray_sync[SYNC_STAGES-1];
    wire [PTR_WIDTH-1:0] rptr_gray_w = rptr_gray_sync[SYNC_STAGES-1];

    // ------------------------------------------------------------------
    // Full / Empty flags
    // ------------------------------------------------------------------
    wire wfull  = (wptr_bin == {~rptr_gray_w[PTR_WIDTH-1:PTR_WIDTH-2],
                                 rptr_gray_w[PTR_WIDTH-3:0]});

    wire rempty = (rptr_bin == {~wptr_gray_r[PTR_WIDTH-1:PTR_WIDTH-2],
                                 wptr_gray_r[PTR_WIDTH-3:0]});

    // ------------------------------------------------------------------
    // Binary-to-Gray conversion
    // ------------------------------------------------------------------
    assign wptr_gray = wptr_bin ^ (wptr_bin >> 1);
    assign rptr_gray = rptr_bin ^ (rptr_bin >> 1);

    // ------------------------------------------------------------------
    // Write pointer update (write domain)
    // ------------------------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr_bin <= {PTR_WIDTH{1'b0}};
        else if (winc && !wfull)
            wptr_bin <= wptr_bin + 1'b1;
    end

    // ------------------------------------------------------------------
    // Read pointer update (read domain)
    // ------------------------------------------------------------------
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr_bin <= {PTR_WIDTH{1'b0}};
        else if (rinc && !rempty)
            rptr_bin <= rptr_bin + 1'b1;
    end

    // ------------------------------------------------------------------
    // Synchroniser: write pointer Gray -> read domain
    // ------------------------------------------------------------------
    integer i;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_gray_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_gray_sync[0] <= wptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_gray_sync[i] <= wptr_gray_sync[i-1];
        end
    end

    // ------------------------------------------------------------------
    // Synchroniser: read pointer Gray -> write domain
    // ------------------------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_gray_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_gray_sync[0] <= rptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_gray_sync[i] <= rptr_gray_sync[i-1];
        end
    end

    // ------------------------------------------------------------------
    // Dual-port RAM
    // ------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Write port
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr_bin[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read port
    always @(posedge rclk) begin
        if (rinc && !rempty)
            rdata <= mem[rptr_bin[ADDR_WIDTH-1:0]];
    end

    // ------------------------------------------------------------------
    // Debug pointer outputs
    // ------------------------------------------------------------------
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;

endmodule