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
    reg [ADDR_WIDTH:0] wptr, wptr_gray, wptr_gray_sync_rclk, wptr_bin;
    reg [ADDR_WIDTH:0] rptr, rptr_gray, rptr_gray_sync_wclk, rptr_bin;
    reg [DATA_WIDTH-1:0] mem [0:(2**(ADDR_WIDTH+1))-1];
    reg wfull_raw, rempty_raw;

    // Binary to Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary code conversion
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
            wptr <= 0;
            wptr_gray <= 0;
            wfull_raw <= 0;
        end else begin
            if (!wfull_raw && winc) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                wptr_gray <= bin_to_gray(wptr + 1);
            end
            wfull_raw <= (wptr_gray == rptr_gray_sync_wclk);
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rempty_raw <= 1;
        end else begin
            if (!rempty_raw && rinc) begin
                rptr <= rptr + 1;
                rptr_gray <= bin_to_gray(rptr + 1);
            end
            rempty_raw <= (wptr_gray_sync_rclk == rptr_gray_sync_wclk);
        end
    end

    // Synchronization registers for crossing clock domains
    sync_reg #(.DATA_WIDTH(ADDR_WIDTH+1))
    sync_rptr_gray_wclk (
        .clk(wclk),
        .rst_n(wrst_n),
        .data_in(rptr_gray),
        .data_out(rptr_gray_sync_wclk)
    );

    sync_reg #(.DATA_WIDTH(ADDR_WIDTH+1))
    sync_wptr_gray_rclk (
        .clk(rclk),
        .rst_n(rrst_n),
        .data_in(wptr_gray),
        .data_out(wptr_gray_sync_rclk)
    );

    // Outputs
    assign wfull = wfull_raw;
    assign rempty = rempty_raw;
    assign waddr = wptr;
    assign raddr = rptr;
    assign rdata = mem[rptr];

endmodule

module sync_reg #(
    parameter DATA_WIDTH = 1
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output wire [DATA_WIDTH-1:0]   data_out
);

    reg [DATA_WIDTH-1:0] sync_stage [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= 0;
            end
        end else begin
            sync_stage[0] <= data_in;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign data_out = sync_stage[SYNC_STAGES-1];

endmodule
