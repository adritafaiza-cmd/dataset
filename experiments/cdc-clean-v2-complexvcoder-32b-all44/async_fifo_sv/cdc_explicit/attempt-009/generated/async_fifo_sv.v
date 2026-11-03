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

    // Internal signals
    wire [ADDR_WIDTH:0] wptr_bin, rptr_bin, wptr_bin_next, rptr_bin_next;
    wire [ADDR_WIDTH:0] wptr_gray, rptr_gray, wptr_gray_next, rptr_gray_sync, wptr_gray_sync;
    reg  [DATA_WIDTH-1:0] mem [0:(2**(ADDR_WIDTH+1))-1];
    wire wfull_raw, rempty_raw, winc_gray, rinc_gray;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray_to_bin = bin;
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
        end else if (winc_gray && !wfull_raw) begin
            wptr_bin <= wptr_bin_next;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem[0] <= 0;
        end else if (winc_gray && !wfull_raw) begin
            mem[wptr_bin] <= wdata;
        end
    end

    // Write pointer logic
    assign wptr_bin_next = wptr_bin + 1;
    assign wptr_gray = bin_to_gray(wptr_bin);
    assign wptr_gray_next = bin_to_gray(wptr_bin_next);
    assign winc_gray = winc && !wfull;

    // Write full condition
    assign wfull_raw = (wptr_gray_next == gray_to_bin(rptr_gray_sync) + 1);
    assign wfull = wfull_raw;

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
        end else if (rinc_gray && !rempty_raw) begin
            rptr_bin <= rptr_bin_next;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc_gray && !rempty_raw) begin
            rdata <= mem[rptr_bin];
        end
    end

    // Read pointer logic
    assign rptr_bin_next = rptr_bin + 1;
    assign rptr_gray = bin_to_gray(rptr_bin);
    assign rinc_gray = rinc && !rempty;

    // Read empty condition
    assign rempty_raw = (wptr_gray_sync == rptr_gray);
    assign rempty = rempty_raw;

    // Address outputs
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;

    // Cross-clock domain synchronization for pointers
    sync_register #(.WIDTH(ADDR_WIDTH+1), .SYNC_STAGES(SYNC_STAGES))
    sync_wptr_gray (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_gray),
        .sync_out(rptr_gray_sync)
    );

    sync_register #(.WIDTH(ADDR_WIDTH+1), .SYNC_STAGES(SYNC_STAGES))
    sync_rptr_gray (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_gray),
        .sync_out(wptr_gray_sync)
    );

endmodule

// Synchronizer module
module sync_register #(
    parameter WIDTH = 5,
    parameter SYNC_STAGES = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] sync_out
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= 0;
            end
        end else begin
            sync_reg[0] <= din;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule
