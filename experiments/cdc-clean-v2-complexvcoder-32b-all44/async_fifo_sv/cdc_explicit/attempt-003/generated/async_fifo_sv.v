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
    reg [ADDR_WIDTH:0] wptr_bin, wptr_gray, wptr_gray_synced, wptr_next;
    reg [ADDR_WIDTH:0] rptr_bin, rptr_gray, rptr_gray_synced, rptr_next;
    reg write_en, read_en;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
        end else begin
            if (write_en) begin
                wptr_bin <= wptr_next;
            end
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
        end else begin
            if (read_en) begin
                rptr_bin <= rptr_next;
            end
        end
    end

    // Binary to Gray conversion
    assign wptr_gray = wptr_bin ^ (wptr_bin >> 1);
    assign rptr_gray = rptr_bin ^ (rptr_bin >> 1);

    // Synchronize pointers across clock domains
    sync_flop #(.din_width(ADDR_WIDTH+1), .sync_stages(SYNC_STAGES)) wptr_gray_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray),
        .dout(wptr_gray_synced)
    );

    sync_flop #(.din_width(ADDR_WIDTH+1), .sync_stages(SYNC_STAGES)) rptr_gray_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray),
        .dout(rptr_gray_synced)
    );

    // Gray to Binary conversion
    assign wptr_bin_synced = wptr_gray_synced ^ (wptr_gray_synced >> 1);
    assign rptr_bin_synced = rptr_gray_synced ^ (rptr_gray_synced >> 1);

    // Next pointers
    assign wptr_next = write_en ? (wptr_bin + 1) : wptr_bin;
    assign rptr_next = read_en ? (rptr_bin + 1) : rptr_bin;

    // Full and empty flags
    assign wfull = (wptr_next[ADDR_WIDTH] != rptr_gray_synced[ADDR_WIDTH]) && (wptr_next[ADDR_WIDTH-1:0] == rptr_gray_synced[ADDR_WIDTH-1:0]);
    assign rempty = (wptr_gray_synced[ADDR_WIDTH] == rptr_bin[ADDR_WIDTH]) && (wptr_gray_synced[ADDR_WIDTH-1:0] == rptr_bin[ADDR_WIDTH-1:0]);

    // Enable signals
    assign write_en = winc & ~wfull;
    assign read_en = rinc & ~rempty;

    // FIFO memory
    fifo_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(write_en),
        .waddr(wptr_bin[ADDR_WIDTH-1:0]),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(rptr_bin[ADDR_WIDTH-1:0]),
        .rdata(rdata)
    );

    // Debug outputs
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;

endmodule

module sync_flop #(
    parameter din_width = 8,
    parameter sync_stages = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [din_width-1:0] din,
    output reg [din_width-1:0] dout
);

    reg [din_width-1:0] sync_flops [sync_stages-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < sync_stages; i = i + 1) begin
                sync_flops[i] <= 0;
            end
        end else begin
            sync_flops[0] <= din;
            for (int i = 1; i < sync_stages; i = i + 1) begin
                sync_flops[i] <= sync_flops[i-1];
            end
        end
    end

    assign dout = sync_flops[sync_stages-1];

endmodule

module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire winc,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] memory [0:(2**ADDR_WIDTH)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
                memory[i] <= 0;
            end
        end else if (winc) begin
            memory[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            rdata <= memory[raddr];
        end
    end

endmodule
