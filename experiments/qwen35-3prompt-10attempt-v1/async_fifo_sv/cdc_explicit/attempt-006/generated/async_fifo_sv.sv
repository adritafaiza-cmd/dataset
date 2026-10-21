```systemverilog
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

    localparam ADDR_MASK = (1 << ADDR_WIDTH) - 1;
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

    // Generate synchronization stages
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stage_gen
            wire sync_winc;
            wire sync_rinc;
            wire sync_wrst_n;
            wire sync_rrst_n;

            // Write domain sync chain
            if (i == 0)
                sync_winc = winc;
            else
                sync_winc = sync_winc_d;

            if (i == 0)
                sync_wrst_n = wrst_n;
            else
                sync_wrst_n = sync_wrst_n_d;

            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n)
                    sync_winc_d <= 1'b0;
                else
                    sync_winc_d <= sync_winc;
            end

            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n)
                    sync_wrst_n_d <= 1'b1;
                else
                    sync_wrst_n_d <= sync_wrst_n;
            end

            // Read domain sync chain
            if (i == 0)
                sync_rinc = rinc;
            else
                sync_rinc = sync_rinc_d;

            if (i == 0)
                sync_rrst_n = rrst_n;
            else
                sync_rrst_n = sync_rrst_n_d;

            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n)
                    sync_rinc_d <= 1'b0;
                else
                    sync_rinc_d <= sync_rinc;
            end

            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n)
                    sync_rrst_n_d <= 1'b1;
                else
                    sync_rrst_n_d <= sync_rrst_n;
            end
        end
    endgenerate

    // Internal signals
    wire [ADDR_WIDTH:0] wptr_sync;
    wire [ADDR_WIDTH:0] rptr_sync;
    wire [ADDR_WIDTH:0] wptr_sync_d;
    wire [ADDR_WIDTH:0] rptr_sync_d;
    wire [ADDR_WIDTH:0] wptr_sync_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dd;
    wire [ADDR_WIDTH:0] wptr_sync_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_ddd;
    wire [ADDR_WIDTH:0] wptr_sync_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_ddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd;

    wire [ADDR_WIDTH:0] wptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_d;
    wire [ADDR_WIDTH:0] rptr_sync_dddd_sync_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd_dddd