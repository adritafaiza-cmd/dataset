//==============================================================================
// File: async_fifo.sv
// Description: Asynchronous FIFO with Gray code pointer synchronization
// Author: IC Lab Design
// Date: 2025
//==============================================================================

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,  // Depth = 2^ADDR_WIDTH = 16
    parameter SYNC_STAGES = 2  // Number of synchronizer stages
)(
    // Write clock domain
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,     // Write increment
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,    // For debugging
    
    // Read clock domain  
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,     // Read increment
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr     // For debugging
);

    // Internal wires
    wire [ADDR_WIDTH:0]   wptr, rptr;
    wire [ADDR_WIDTH:0]   wptr_gray, rptr_gray;
    wire [ADDR_WIDTH:0]   rptr_gray_sync, wptr_gray_sync;
    wire [ADDR_WIDTH-1:0] waddr_int, raddr_int;
    wire                  common_rst_n;
    wire                  wrst_n_sync;
    wire                  rrst_n_sync;

    // Coordinated async assertion; deassert is synchronized per domain.
    (* ASYNC_REG = "TRUE" *) reg [1:0] wrst_sync_ff;
    (* ASYNC_REG = "TRUE" *) reg [1:0] rrst_sync_ff;

    assign common_rst_n = wrst_n & rrst_n;

    always @(posedge wclk or negedge common_rst_n) begin
        if (!common_rst_n)
            wrst_sync_ff <= 2'b00;
        else
            wrst_sync_ff <= {wrst_sync_ff[0], 1'b1};
    end

    always @(posedge rclk or negedge common_rst_n) begin
        if (!common_rst_n)
            rrst_sync_ff <= 2'b00;
        else
            rrst_sync_ff <= {rrst_sync_ff[0], 1'b1};
    end

    assign wrst_n_sync = wrst_sync_ff[1];
    assign rrst_n_sync = rrst_sync_ff[1];

    // Assign debug addresses
    assign waddr = wptr;
    assign raddr = rptr;

    //==========================================================================
    // Write pointer and full generation logic
    //==========================================================================
    wptr_full #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_wptr_full (
        .wclk          (wclk),
        .wrst_n        (wrst_n_sync),
        .winc          (winc),
        .wfull         (wfull),
        .wptr          (wptr),
        .wptr_gray     (wptr_gray),
        .waddr         (waddr_int),
        .rptr_gray_sync(rptr_gray_sync)
    );

    //==========================================================================
    // Read pointer and empty generation logic
    //==========================================================================
    rptr_empty #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_rptr_empty (
        .rclk          (rclk),
        .rrst_n        (rrst_n_sync),
        .rinc          (rinc),
        .rempty        (rempty),
        .rptr          (rptr),
        .rptr_gray     (rptr_gray),
        .raddr         (raddr_int),
        .wptr_gray_sync(wptr_gray_sync)
    );

    //==========================================================================
    // Synchronize read pointer to write clock domain
    //==========================================================================
    sync_r2w #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .SYNC_STAGES (SYNC_STAGES)
    ) u_sync_r2w (
        .wclk          (wclk),
        .wrst_n        (wrst_n_sync),
        .rptr_gray     (rptr_gray),
        .rptr_gray_sync(rptr_gray_sync)
    );

    //==========================================================================
    // Synchronize write pointer to read clock domain
    //==========================================================================
    sync_w2r #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .SYNC_STAGES (SYNC_STAGES)
    ) u_sync_w2r (
        .rclk          (rclk),
        .rrst_n        (rrst_n_sync),
        .wptr_gray     (wptr_gray),
        .wptr_gray_sync(wptr_gray_sync)
    );

    //==========================================================================
    // Dual-port RAM
    //==========================================================================
    fifomem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifomem (
        .wclk  (wclk),
        .wfull (wfull),
        .winc  (winc),
        .waddr (waddr_int),
        .wdata (wdata),
        .raddr (raddr_int),
        .rdata (rdata)
    );

endmodule